import Foundation
import Yosemite

enum CardReaderSettingsUnknownViewModelState {
    case idle
    case searching
    case stoppingSearch
    case searchFailure(Error)
    case foundReader
    case connectingToReader
    case connectionFailure(Error)
    case connected
}

final class CardReaderSettingsUnknownViewModel: CardReaderSettingsPresentedViewModel {

    private(set) var shouldShow: CardReaderSettingsTriState = .isUnknown
    var didChangeShouldShow: ((CardReaderSettingsTriState) -> Void)?
    var didUpdate: (() -> Void)?

    private var noConnectedReaders: CardReaderSettingsTriState = .isUnknown
    private var noKnownReaders: CardReaderSettingsTriState = .isUnknown
    private var knownReadersProvider: CardReaderSettingsKnownReadersProvider?
    private var siteID: Int64 = Int64.min

    private var foundReader: CardReader?

    var viewModelState: CardReaderSettingsUnknownViewModelState = .idle {
        didSet {
            didUpdate?()
        }
    }
    var foundReaderSerialNumber: String? {
        foundReader?.serial
    }

    init(didChangeShouldShow: ((CardReaderSettingsTriState) -> Void)?, knownReadersProvider: CardReaderSettingsKnownReadersProvider? = nil) {
        self.didChangeShouldShow = didChangeShouldShow
        self.siteID = ServiceLocator.stores.sessionManager.defaultStoreID ?? Int64.min
        self.knownReadersProvider = knownReadersProvider
        beginObservation()
    }

    /// Dispatches actions to the CardPresentPaymentStore so that we can monitor changes to the list of known
    /// and connected readers.
    ///
    private func beginObservation() {
        // This completion should be called repeatedly as the list of known readers changes
        let knownAction = CardPresentPaymentAction.observeKnownReaders() { [weak self] readers in
            guard let self = self else {
                return
            }
            self.noKnownReaders = readers.isEmpty ? .isTrue : .isFalse
            self.reevaluateShouldShow()
        }
        ServiceLocator.stores.dispatch(knownAction)

        // This completion should be called repeatedly as the list of connected readers changes
        let connectedAction = CardPresentPaymentAction.observeConnectedReaders() { [weak self] readers in
            guard let self = self else {
                return
            }
            self.noConnectedReaders = readers.isEmpty ? .isTrue : .isFalse
            self.reevaluateShouldShow()
        }
        ServiceLocator.stores.dispatch(connectedAction)
    }

    /// Dispatch a request to start reader discovery
    ///
    func startReaderDiscovery() {
        viewModelState = .searching

        ServiceLocator.analytics.track(.cardReaderDiscoveryTapped)
        let action = CardPresentPaymentAction.startCardReaderDiscovery(
            siteID: siteID,
            onReaderDiscovered: { [weak self] cardReaders in
                self?.didDiscoverReaders(cardReaders: cardReaders)
            },
            onError: { [weak self] error in
                self?.viewModelState = .searchFailure(error)
                ServiceLocator.analytics.track(.cardReaderDiscoveryFailed, withError: error)
            })

        ServiceLocator.stores.dispatch(action)
    }

    /// Alert the user we have a found reader
    ///
    func didDiscoverReaders(cardReaders: [CardReader]) {
        /// If we are already presenting a foundReader alert to the user, ignore the found reader
        guard case .searching = viewModelState else {
            return
        }

        /// The publisher for discovered readers can return an initial empty value. We'll want to ignore that.
        guard cardReaders.count > 0 else {
            return
        }

        ServiceLocator.analytics.track(.cardReaderDiscoveredReader)

        /// This viewmodel and view supports one reader at a time discovery only.
        /// TODO: Add another viewmodel and view for listing discovered readers.
        guard let cardReader = cardReaders.first else {
            return
        }

        foundReader = cardReader
        viewModelState = .foundReader
    }

    /// Dispatch a request to cancel reader discovery
    ///
    func cancelReaderDiscovery() {
        self.viewModelState = .stoppingSearch
        cancelReaderDiscovery(completion: { [weak self] in
            self?.viewModelState = .idle
        })
    }

    /// Dispatch a request to connect to the found reader
    ///
    func connectToReader() {
        guard let foundReader = foundReader else {
            DDLogError("foundReader unexpectedly nil in connectToReader")
            return
        }

        viewModelState = .connectingToReader

        ServiceLocator.analytics.track(.cardReaderConnectionTapped)
        let action = CardPresentPaymentAction.connect(reader: foundReader) { [weak self] result in
            switch result {
            case .success(let reader):
                self?.viewModelState = .connected
                self?.knownReadersProvider?.rememberCardReader(cardReaderID: reader.serial)
                // If the reader does not have a battery, or the battery level is unknown, it will be nil
                let properties = reader.batteryLevel
                    .map { ["battery_level": $0] }
                ServiceLocator.analytics.track(.cardReaderConnectionSuccess, withProperties: properties)
            case .failure(let error):
                self?.viewModelState = .connectionFailure(error)
                ServiceLocator.analytics.track(.cardReaderConnectionFailed, withError: error)
            }
        }
        ServiceLocator.stores.dispatch(action)
    }

    /// Discard the found reader and keep searching
    /// As discussed in p91TBi-5fB-p2#comment-4849, for the first release,
    /// we will restart the discovery process again
    func continueSearch() {
        foundReader = nil
        cancelReaderDiscovery { [weak self] in
            self?.startReaderDiscovery()
        }
    }

    /// Updates whether the view this viewModel is associated with should be shown or not
    /// Notifes the viewModel owner if a change occurs via didChangeShouldShow
    ///
    private func reevaluateShouldShow() {
        var newShouldShow: CardReaderSettingsTriState = .isUnknown

        if ( noKnownReaders == .isUnknown ) || ( noConnectedReaders == .isUnknown ) {
            newShouldShow = .isUnknown
        } else if ( noKnownReaders == .isTrue ) && ( noConnectedReaders == .isTrue ) {
            newShouldShow = .isTrue
        } else {
            newShouldShow = .isFalse
        }

        let didChange = newShouldShow != shouldShow

        shouldShow = newShouldShow

        if didChange {
            didChangeShouldShow?(shouldShow)
        }
    }
}


private extension CardReaderSettingsUnknownViewModel {
    func cancelReaderDiscovery(completion: (()-> Void)?) {
        let action = CardPresentPaymentAction.cancelCardReaderDiscovery() { _ in
            completion?()
        }

        ServiceLocator.stores.dispatch(action)
    }
}
