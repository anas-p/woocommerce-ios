/// Represents the possible states for onboarding to In-Person payments
public enum CardPresentPaymentOnboardingState: Equatable {
    /// The app is loading the required data to check for the current state
    ///
    case loading

    /// All the requirements are met and the feature is ready to use
    ///
    case completed

    /// Store is not located in one of the supported countries.
    ///
    case countryNotSupported(countryCode: String)

    /// WCPay plugin is not installed on the store.
    ///
    case wcpayNotInstalled

    /// WCPay plugin is installed on the store, but the version is out-dated and doesn't contain required APIs for card present payments.
    ///
    case wcpayUnsupportedVersion

    /// WCPay is installed on the store but is not activated.
    ///
    case wcpayNotActivated

    /// WCPay is installed and activated but requires to be setup first.
    ///
    case wcpaySetupNotCompleted

    /// This is a bit special case: WCPay is set to "dev mode" but the connected Stripe account is in live mode.
    /// Connecting to a reader or accepting payments is not supported in this state.
    ///
    case wcpayInTestModeWithLiveStripeAccount

    /// The connected Stripe account has not been reviewed by Stripe yet. This is a temporary state and the user needs to wait.
    ///
    case stripeAccountUnderReview

    /// There are some pending requirements on the connected Stripe account. The merchant still has some time before the deadline to fix them expires.
    /// In-person payments should work without issues.
    ///
    case stripeAccountPendingRequirement(deadline: Date?)

    /// There are some overdue requirements on the connected Stripe account. Connecting to a reader or accepting payments is not supported in this state.
    ///
    case stripeAccountOverdueRequirement

    /// The Stripe account was rejected by Stripe.
    /// This can happen for example when the account is flagged as fraudulent or the merchant violates the terms of service.
    ///
    case stripeAccountRejected

    /// Generic error - for example, one of the requests failed.
    ///
    case genericError

    /// Internet connection is not available.
    ///
    case noConnectionError
}

extension CardPresentPaymentOnboardingState {
    public var reasonForAnalytics: String? {
        switch self {
        case .loading:
            return nil
        case .completed:
            return nil
        case .countryNotSupported(countryCode: _):
            return "country_not_supported"
        case .wcpayNotInstalled:
            return "wcpay_not_installed"
        case .wcpayUnsupportedVersion:
            return "wcpay_unsupported_version"
        case .wcpayNotActivated:
            return "wcpay_not_activated"
        case .wcpaySetupNotCompleted:
            return "wcpay_setup_not_completed"
        case .wcpayInTestModeWithLiveStripeAccount:
            return "wcpay_in_test_mode_with_live_account"
        case .stripeAccountUnderReview:
            return "account_under_review"
        case .stripeAccountPendingRequirement(deadline: _):
            return "account_pending_requirements"
        case .stripeAccountOverdueRequirement:
            return "account_overdue_requirements"
        case .stripeAccountRejected:
            return "account_rejected"
        case .genericError:
            return "generic_error"
        case .noConnectionError:
            return "no_connection_error"
        }
    }
}
