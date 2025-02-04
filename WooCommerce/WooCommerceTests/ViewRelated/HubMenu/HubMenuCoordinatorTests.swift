import XCTest
import TestKit

import Yosemite

@testable import WooCommerce

/// Test cases for `HubMenuCoordinator`.
///
final class HubMenuCoordinatorTests: XCTestCase {
    private var pushNotificationsManager: MockPushNotificationsManager!
    private var storesManager: MockStoresManager!
    private var sessionManager: SessionManager!
    private var noticePresenter: MockNoticePresenter!
    private var switchStoreUseCase: MockSwitchStoreUseCase!

    private let siteID: Int64 = 1

    override func setUp() {
        super.setUp()

        pushNotificationsManager = MockPushNotificationsManager()
        sessionManager = SessionManager.testingInstance

        storesManager = MockStoresManager(sessionManager: sessionManager)
        // Reset `receivedActions`
        storesManager.reset()

        noticePresenter = MockNoticePresenter()
        switchStoreUseCase = MockSwitchStoreUseCase()
    }

    override func tearDown() {
        switchStoreUseCase = nil
        noticePresenter = nil
        storesManager = nil
        sessionManager = nil
        pushNotificationsManager = nil

        super.tearDown()
    }

    func test_when_receiving_a_non_review_notification_then_it_will_not_do_anything() throws {
        // Given
        let coordinator = makeHubMenuCoordinator()
        let pushNotification = PushNotification(noteID: 1_234, kind: .storeOrder, title: "", subtitle: "", message: "")

        coordinator.start()
        coordinator.activate(siteID: siteID)

        XCTAssertEqual(coordinator.navigationController.viewControllers.count, 1)

        // When
        pushNotificationsManager.sendInactiveNotification(pushNotification)

        // Then
        assertEmpty(storesManager.receivedActions)

        // Only the HubMenu is shown
        XCTAssertEqual(coordinator.navigationController.viewControllers.count, 1)
        assertThat(coordinator.navigationController.topViewController, isAnInstanceOf: HubMenuViewController.self)
    }

    func test_when_receiving_a_notification_while_in_foreground_then_it_will_not_do_anything() throws {
        // Given
        let coordinator = makeHubMenuCoordinator()
        let pushNotification = PushNotification(noteID: 1_234, kind: .comment, title: "", subtitle: "", message: "")

        coordinator.start()
        coordinator.activate(siteID: siteID)

        // When
        pushNotificationsManager.sendForegroundNotification(pushNotification)

        // Then
        assertEmpty(storesManager.receivedActions)

        // Only the HubMenu is shown
        XCTAssertEqual(coordinator.navigationController.viewControllers.count, 1)
        assertThat(coordinator.navigationController.topViewController, isAnInstanceOf: HubMenuViewController.self)
    }

    func test_when_receiving_a_review_notification_while_inactive_then_it_will_present_the_review_details() throws {
        // Given
        let pushNotification = PushNotification(noteID: 1_234, kind: .comment, title: "", subtitle: "", message: "")

        var willPresentReviewDetailsFromPushNotificationCallCount: Int = 0
        let coordinator = makeHubMenuCoordinator(willPresentReviewDetailsFromPushNotification: {
            willPresentReviewDetailsFromPushNotificationCallCount += 1
        })
        coordinator.start()
        coordinator.activate(siteID: siteID)

        // When
        pushNotificationsManager.sendInactiveNotification(pushNotification)

        // Simulate that the network call returns a parcel
        let receivedAction = try XCTUnwrap(storesManager.receivedActions.first as? ProductReviewAction)
        guard case .retrieveProductReviewFromNote(_, let completion) = receivedAction else {
            return XCTFail("Expected retrieveProductReviewFromNote action.")
        }
        completion(.success(ProductReviewFromNoteParcelFactory().parcel()))

        // Then
        waitUntil {
            coordinator.navigationController.viewControllers.count == 2
        }
        XCTAssertEqual(willPresentReviewDetailsFromPushNotificationCallCount, 1)

        // A ReviewDetailsViewController should be pushed
        XCTAssertEqual(coordinator.navigationController.viewControllers.count, 2)
        assertThat(coordinator.navigationController.topViewController, isAnInstanceOf: ReviewDetailsViewController.self)
    }

    func test_when_failing_to_retrieve_ProductReview_details_then_it_will_present_a_notice() throws {
        // Given
        let coordinator = makeHubMenuCoordinator()
        let pushNotification = PushNotification(noteID: 1_234, kind: .comment, title: "", subtitle: "", message: "")

        coordinator.start()
        coordinator.activate(siteID: siteID)

        assertEmpty(noticePresenter.queuedNotices)

        // When
        pushNotificationsManager.sendInactiveNotification(pushNotification)

        // Simulate that the network call returns a parcel
        let receivedAction = try XCTUnwrap(storesManager.receivedActions.first as? ProductReviewAction)
        guard case .retrieveProductReviewFromNote(_, let completion) = receivedAction else {
            return XCTFail("Expected retrieveProductReviewFromNote action.")
        }
        completion(.failure(NSError(domain: "domain", code: 0)))

        // Then
        waitUntil {
            self.noticePresenter.queuedNotices.count == 1
        }

        // A Notice should have been presented
        XCTAssertEqual(noticePresenter.queuedNotices.count, 1)

        let notice = try XCTUnwrap(noticePresenter.queuedNotices.first)
        XCTAssertEqual(notice.title, HubMenuCoordinator.Localization.failedToRetrieveReviewNotificationDetails)

        // Only the HubMenu should still be visible
        XCTAssertEqual(coordinator.navigationController.viewControllers.count, 1)
        assertThat(coordinator.navigationController.topViewController, isAnInstanceOf: HubMenuViewController.self)
    }

    func test_when_receiving_a_review_notification_from_a_different_site_then_it_will_switch_the_current_site() throws {
        // Given
        sessionManager.setStoreId(1_000)

        let coordinator = makeHubMenuCoordinator()
        let pushNotification = PushNotification(noteID: 1_234, kind: .comment, title: "", subtitle: "", message: "")
        let differentSiteID: Int64 = 2_000_111

        coordinator.start()
        coordinator.activate(siteID: siteID)

        // When
        pushNotificationsManager.sendInactiveNotification(pushNotification)

        // Simulate that the network call returns a parcel from a different site
        let receivedProductReviewAction = try XCTUnwrap(storesManager.receivedActions.first as? ProductReviewAction)
        guard case .retrieveProductReviewFromNote(_, let completion) = receivedProductReviewAction else {
            return XCTFail("Expected retrieveProductReviewFromNote action.")
        }
        completion(.success(ProductReviewFromNoteParcelFactory().parcel(metaSiteID: differentSiteID)))

        // Then
        waitUntil {
            coordinator.navigationController.viewControllers.count == 2
        }

        // A ReviewDetailsViewController should be pushed
        assertThat(coordinator.navigationController.topViewController, isAnInstanceOf: ReviewDetailsViewController.self)
        // We should have switched to the other site
        XCTAssertEqual(switchStoreUseCase.destinationStoreIDs, [differentSiteID])
    }
}

// MARK: - Utils
private extension HubMenuCoordinatorTests {
    func makeHubMenuCoordinator(willPresentReviewDetailsFromPushNotification: (@escaping () -> Void) = { }) -> HubMenuCoordinator {
        HubMenuCoordinator(navigationController: UINavigationController(),
                           pushNotificationsManager: pushNotificationsManager,
                           storesManager: storesManager,
                           noticePresenter: noticePresenter,
                           switchStoreUseCase: switchStoreUseCase,
                           willPresentReviewDetailsFromPushNotification: willPresentReviewDetailsFromPushNotification)
    }
}
