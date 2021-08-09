import UIKit
import Yosemite

/// Generates top banner view that is shown at the top of Shipping Label address form screen when there is an error in the address validation.
///
final class ShippingLabelAddressTopBannerFactory {
    static func addressErrorTopBannerView(shipType: ShipType,
                                          phoneNumber: String?,
                                          openMapPressed: @escaping () -> Void,
                                          contactCustomerPressed: @escaping () -> Void) -> TopBannerView {
        // Set banner text and action buttons based on shipping address type (origin or destination),
        // and whether phone number is missing.
        let missingPhoneNumber = phoneNumber == nil || phoneNumber?.isEmpty == true
        let infoText: String = {
            if shipType == .origin {
                return Localization.infoShipFrom
            }
            return missingPhoneNumber ? Localization.infoShipToNoContact : Localization.infoShipTo
        }()

        let openMapAction = TopBannerViewModel.ActionButton(title: Localization.openMapAction) {
            openMapPressed()
        }

        let contactCustomerAction: TopBannerViewModel.ActionButton? = {
            guard !missingPhoneNumber else {
                return nil
            }
            return .init(title: Localization.contactCustomerAction) {
                contactCustomerPressed()
            }
        }()

        let actions: [TopBannerViewModel.ActionButton] = {
            guard shipType == .destination else {
                return []
            }
            return [openMapAction, contactCustomerAction].compactMap { $0 }
        }()

        let viewModel = TopBannerViewModel(title: nil,
                                           infoText: infoText,
                                           icon: Constants.icon,
                                           isExpanded: true,
                                           topButton: .none,
                                           actionButtons: actions,
                                           type: .warning)
        return TopBannerView(viewModel: viewModel)
    }
}

private extension ShippingLabelAddressTopBannerFactory {
    enum Constants {
        static let icon = UIImage.infoOutlineImage
    }

    enum Localization {
        static let infoShipFrom = NSLocalizedString("We were unable to automatically verify the origin address.",
                                                    comment: "Banner caption in Shipping Label Address Validation when the origin address can't be verified.")
        static let infoShipTo = NSLocalizedString("We were unable to automatically verify the shipping address. " +
                                                "View on Apple Maps or try contacting the customer to make sure the address is correct.",
                                            comment: "Banner caption in Shipping Label Address Validation when the destination address can't be verified.")
        static let infoShipToNoContact = NSLocalizedString(
            "We were unable to automatically verify the shipping address. " +
                "View on Apple Maps to make sure the address is correct.",
            comment: "Banner caption in Shipping Label Address Validation " +
                "when the destination address can't be verified and no customer phone number is found."
        )
        static let openMapAction = NSLocalizedString("Open Map", comment: "Open Map action in Shipping Label Address Validation.")
        static let contactCustomerAction = NSLocalizedString("Contact Customer", comment: "Contact Customer action in Shipping Label Address Validation.")
    }
}
