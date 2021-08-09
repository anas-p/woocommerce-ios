import Foundation
import Codegen

/// An encodable/decodable data structure that can be used to save files. This contains
/// miscellaneous app settings.
///
/// Sometimes I wonder if `AppSettingsStore` should just use one plist file. Maybe things will
/// be simpler?
///
public struct GeneralAppSettings: Codable, Equatable, GeneratedCopiable {
    /// The known `Date` that the app was installed.
    ///
    /// Note that this is not accurate because this property/setting was created when we have
    /// thousands of users already.
    ///
    public let installationDate: Date?

    /// Key/Value type to store feedback settings
    /// Key: A `FeedbackType` to identify the feedback
    /// Value: A `FeedbackSetting` to store the feedback state
    public let feedbacks: [FeedbackType: FeedbackSettings]

    /// The state(`true` or `false`) for the view add-on beta feature switch.
    ///
    public let isViewAddOnsSwitchEnabled: Bool

    /// A list (possibly empty) of known card reader IDs - i.e. IDs of card readers that should be reconnected to automatically
    /// e.g. ["CHB204909005931"]
    ///
    public let knownCardReaders: [String]

    /// The last known eligibility error information persisted locally.
    ///
    public let lastEligibilityErrorInfo: EligibilityErrorInfo?

    public init(installationDate: Date?,
                feedbacks: [FeedbackType: FeedbackSettings],
                isViewAddOnsSwitchEnabled: Bool,
                knownCardReaders: [String],
                lastEligibilityErrorInfo: EligibilityErrorInfo? = nil) {
        self.installationDate = installationDate
        self.feedbacks = feedbacks
        self.isViewAddOnsSwitchEnabled = isViewAddOnsSwitchEnabled
        self.knownCardReaders = knownCardReaders
        self.lastEligibilityErrorInfo = lastEligibilityErrorInfo
    }

    /// Returns the status of a given feedback type. If the feedback is not stored in the feedback array. it is assumed that it has a pending status.
    ///
    public func feedbackStatus(of type: FeedbackType) -> FeedbackSettings.Status {
        guard let feedbackSetting = feedbacks[type] else {
            return .pending
        }

        return feedbackSetting.status
    }

    /// Returns a new instance of `GeneralAppSettings` with the provided feedback seetings updated.
    ///
    public func replacing(feedback: FeedbackSettings) -> GeneralAppSettings {
        let updatedFeedbacks = feedbacks.merging([feedback.name: feedback]) {
            _, new in new
        }

        return GeneralAppSettings(
            installationDate: installationDate,
            feedbacks: updatedFeedbacks,
            isViewAddOnsSwitchEnabled: isViewAddOnsSwitchEnabled,
            knownCardReaders: knownCardReaders,
            lastEligibilityErrorInfo: lastEligibilityErrorInfo
        )
    }
}
