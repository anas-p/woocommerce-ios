import Foundation
import UIKit

/// This view controller is used when no readers are known or connected. It assists
/// the merchant in connecting to a reader, often for the first time.
///
final class CardReaderSettingsUnknownViewController: UIViewController, CardReaderSettingsViewModelPresenter {

    /// Main TableView
    ///
    @IBOutlet weak var tableView: UITableView!

    /// ViewModel
    ///
    private var viewModel: CardReaderSettingsUnknownViewModel?

    /// Table Sections to be rendered
    ///
    private var sections = [Section]()

    /// Accept our viewmodel and listen for changes on it
    ///
    func configure(viewModel: CardReaderSettingsPresentedViewModel) {
        self.viewModel = viewModel as? CardReaderSettingsUnknownViewModel

        guard self.viewModel != nil else {
            DDLogError("Unexpectedly unable to downcast to CardReaderSettingsUnknownViewModel")
            return
        }

        self.viewModel?.didUpdate = onViewModelDidUpdate
    }

    // MARK: - Overridden Methods
    override func viewDidLoad() {
        super.viewDidLoad()

        registerTableViewCells()
        configureNavigation()
        configureSections()
        configureTable()
    }

    override func viewWillDisappear(_ animated: Bool) {
        viewModel?.didUpdate = nil
        super.viewWillDisappear(animated)
    }
}

// MARK: - View Updates
//
private extension CardReaderSettingsUnknownViewController {
    func onViewModelDidUpdate() {
        updateTable()
    }

    func updateTable() {
        tableView.reloadData()
    }
}

// MARK: - View Configuration
//
private extension CardReaderSettingsUnknownViewController {
    /// Set the title.
    ///
    func configureNavigation() {
        title = Localization.title
    }

    /// Setup the sections in this table view
    ///
    func configureSections() {
        sections = [Section(title: nil,
                            rows: [
                                .connectHeader,
                                .connectImage,
                                .connectHelpHintChargeReader,
                                .connectHelpHintTurnOnReader,
                                .connectHelpHintEnableBluetooth,
                                .connectButton,
                                .connectLearnMore
                            ])]
    }

    func configureTable() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.dataSource = self
        tableView.delegate = self
        tableView.reloadData()
    }

    /// Register table cells.
    ///
    func registerTableViewCells() {
        for row in Row.allCases {
            tableView.registerNib(for: row.type)
        }
    }

    /// Cells currently configured in the order they appear on screen
    ///
    func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as HeadlineTableViewCell where row == .connectHeader:
            configureHeader(cell: cell)
        case let cell as ImageTableViewCell where row == .connectImage:
            configureImage(cell: cell)
        case let cell as NumberedListItemTableViewCell where row == .connectHelpHintChargeReader:
            configureHelpHintChargeReader(cell: cell)
        case let cell as NumberedListItemTableViewCell where row == .connectHelpHintTurnOnReader:
            configureHelpHintTurnOnReader(cell: cell)
        case let cell as NumberedListItemTableViewCell where row == .connectHelpHintEnableBluetooth:
            configureHelpHintEnableBluetooth(cell: cell)
        case let cell as ButtonTableViewCell where row == .connectButton:
            configureButton(cell: cell)
        case let cell as LearnMoreTableViewCell where row == .connectLearnMore:
            configureLearnMore(cell: cell)
        default:
            fatalError()
        }
    }

    private func configureHeader(cell: HeadlineTableViewCell) {
        cell.configure(headline: Localization.connectYourCardReaderTitle)
        cell.backgroundColor = .systemBackground
        cell.selectionStyle = .none
    }

    private func configureImage(cell: ImageTableViewCell) {
        cell.configure(image: .cardReaderConnect)
        cell.backgroundColor = .systemBackground
        cell.selectionStyle = .none
    }

    private func configureHelpHintChargeReader(cell: NumberedListItemTableViewCell) {
        let cellViewModel = NumberedListItemTableViewCell.ViewModel(
            itemNumber: Localization.hintOneTitle,
            itemText: Localization.hintOne
        )
        cell.configure(viewModel: cellViewModel)
        cell.backgroundColor = .systemBackground
        cell.selectionStyle = .none
    }

    private func configureHelpHintTurnOnReader(cell: NumberedListItemTableViewCell) {
        let cellViewModel = NumberedListItemTableViewCell.ViewModel(
            itemNumber: Localization.hintTwoTitle,
            itemText: Localization.hintTwo
        )
        cell.configure(viewModel: cellViewModel)
        cell.backgroundColor = .systemBackground
        cell.selectionStyle = .none
    }

    private func configureHelpHintEnableBluetooth(cell: NumberedListItemTableViewCell) {
        let cellViewModel = NumberedListItemTableViewCell.ViewModel(
            itemNumber: Localization.hintThreeTitle,
            itemText: Localization.hintThree
        )
        cell.configure(viewModel: cellViewModel)
        cell.backgroundColor = .systemBackground
        cell.selectionStyle = .none
   }

    private func configureButton(cell: ButtonTableViewCell) {
        let buttonTitle = Localization.connectButton
        cell.configure(title: buttonTitle) { [weak self] in
            self?.searchAndConnect()
        }
        cell.backgroundColor = .systemBackground
        cell.selectionStyle = .none
    }

    private func configureLearnMore(cell: LearnMoreTableViewCell) {
        cell.configure(text: Localization.learnMore) { [weak self] url in
            self?.urlWasPressed(url: url)
        }
        cell.backgroundColor = .systemBackground
        cell.selectionStyle = .none
    }

    private func urlWasPressed(url: URL) {
        WebviewHelper.launch(url, with: self)
    }
}

// MARK: - Convenience Methods
//
private extension CardReaderSettingsUnknownViewController {
    func searchAndConnect() {
        guard let siteID = viewModel?.siteID else {
            return
        }

        guard let knownReadersProvider = viewModel?.knownReadersProvider else {
            return
        }

        let connectionController = CardReaderConnectionController(
            forSiteID: siteID,
            knownReadersProvider: knownReadersProvider
        )
        connectionController.searchAndConnect(from: self) { _ in
            /// No need for logic here. Once connected, the connected reader will publish
            /// through the `cardReaderAvailableSubscription`
        }
    }
}

// MARK: - Convenience Methods
//
private extension CardReaderSettingsUnknownViewController {
    func rowAtIndexPath(_ indexPath: IndexPath) -> Row {
        return sections[indexPath.section].rows[indexPath.row]
    }
}

// MARK: - UITableViewDataSource Conformance
//
extension CardReaderSettingsUnknownViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = rowAtIndexPath(indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: row.reuseIdentifier, for: indexPath)
        configure(cell, for: row, at: indexPath)

        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].title
    }
}


// MARK: - UITableViewDelegate Conformance
//
extension CardReaderSettingsUnknownViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - Private Types
//
private struct Section {
    let title: String?
    let rows: [Row]
}

private enum Row: CaseIterable {
    case connectHeader
    case connectImage
    case connectHelpHintChargeReader
    case connectHelpHintTurnOnReader
    case connectHelpHintEnableBluetooth
    case connectButton
    case connectLearnMore

    var type: UITableViewCell.Type {
        switch self {
        case .connectHeader:
            return HeadlineTableViewCell.self
        case .connectImage:
            return ImageTableViewCell.self
        case .connectHelpHintChargeReader:
            return NumberedListItemTableViewCell.self
        case .connectHelpHintTurnOnReader:
            return NumberedListItemTableViewCell.self
        case .connectHelpHintEnableBluetooth:
            return NumberedListItemTableViewCell.self
        case .connectButton:
            return ButtonTableViewCell.self
        case .connectLearnMore:
            return LearnMoreTableViewCell.self
        }
    }

    var reuseIdentifier: String {
        return type.reuseIdentifier
    }
}

// MARK: - Localization
//
private extension CardReaderSettingsUnknownViewController {
    enum Localization {
        static let title = NSLocalizedString(
            "Manage Card Reader",
            comment: "Settings > Manage Card Reader > Title for the no-reader-connected screen in settings."
        )

        static let connectYourCardReaderTitle = NSLocalizedString(
            "Connect your card reader",
            comment: "Settings > Manage Card Reader > Prompt user to connect their first reader"
        )

        static let hintOneTitle = NSLocalizedString(
            "1",
            comment: "Settings > Manage Card Reader > Connect > Help hint number 1"
        )

        static let hintOne = NSLocalizedString(
            "Make sure card reader is charged",
            comment: "Settings > Manage Card Reader > Connect > Hint to charge card reader"
        )

        static let hintTwoTitle = NSLocalizedString(
            "2",
            comment: "Settings > Manage Card Reader > Connect > Help hint number 2"
        )

        static let hintTwo = NSLocalizedString(
            "Turn card reader on and place it next to mobile device",
            comment: "Settings > Manage Card Reader > Connect > Hint to power on reader"
        )

        static let hintThreeTitle = NSLocalizedString(
            "3",
            comment: "Settings > Manage Card Reader > Connect > Help hint number 3"
        )

        static let hintThree = NSLocalizedString(
            "Turn mobile device Bluetooth on",
            comment: "Settings > Manage Card Reader > Connect > Hint to enable Bluetooth"
        )

        static let connectButton = NSLocalizedString(
            "Connect Card Reader",
            comment: "Settings > Manage Card Reader > Connect > A button to begin a search for a reader"
        )

        static let learnMore: NSAttributedString = {
            let learnMoreText = NSLocalizedString(
                "<a href=\"https://woocommerce.com/payments\">Learn more</a> about accepting payments with your mobile device and ordering card readers",
                comment: "A label prompting users to learn more about card readers with an embedded hyperlink"
            )

            let learnMoreAttributes: [NSAttributedString.Key: Any] = [
                .font: StyleManager.footerLabelFont,
                .foregroundColor: UIColor.textSubtle
            ]

            let learnMoreAttrText = NSMutableAttributedString()
            learnMoreAttrText.append(learnMoreText.htmlToAttributedString)
            let range = NSRange(location: 0, length: learnMoreAttrText.length)
            learnMoreAttrText.addAttributes(learnMoreAttributes, range: range)

            return learnMoreAttrText
        }()
    }
}
