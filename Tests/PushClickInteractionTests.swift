import XCTest
import UserNotifications
@testable import Segmentify

final class PushClickInteractionTests: XCTestCase {
    private var manager: SegmentifyManager!

    override func setUp() {
        super.setUp()
        URLProtocol.registerClass(MockURLProtocol.self)
        SegmentifyTestSupport.configureSegmentify()
        SegmentifyManager.setPushConfig(dataCenterUrlPush: SegmentifyTestSupport.dataCenterURL)
        manager = SegmentifyManager.sharedManager()
    }

    override func tearDown() {
        URLProtocol.unregisterClass(MockURLProtocol.self)
        MockURLProtocol.requestHandler = nil
        SegmentifyTestSupport.resetTestNetworking()
        UserDefaults.standard.removeObject(forKey: "SEGMENTIFY_PUSH_CAMPAIGN_ID")
        SegmentifyManager.pushTargetOpener = SegmentifyManager.openInApplication
        super.tearDown()
    }

    func testClickSendsPushInteractionWithSuppliedInteractionId() {
        let interactionSent = expectation(description: "push interaction dispatched")
        var sentRequest: [AnyHashable: Any] = [:]

        MockURLProtocol.requestHandler = stubAllRequests(onInteraction: {
            sentRequest = self.manager.testingCurrentRequestDictionary()
            interactionSent.fulfill()
        })

        manager.sendNotificationInteraction(segmentifyObject: makeClick(instanceId: "psh_abc", interactionId: "static"))

        wait(for: [interactionSent], timeout: 3)
        XCTAssertEqual(sentRequest["name"] as? String, "INTERACTION")
        XCTAssertEqual(sentRequest["type"] as? String, "push")
        XCTAssertEqual(sentRequest["instanceId"] as? String, "psh_abc")
        XCTAssertEqual(sentRequest["interactionId"] as? String, "static")
    }

    func testClickFallsBackToInstanceIdWhenInteractionIdMissing() {
        let interactionSent = expectation(description: "push interaction dispatched")
        var sentRequest: [AnyHashable: Any] = [:]

        MockURLProtocol.requestHandler = stubAllRequests(onInteraction: {
            sentRequest = self.manager.testingCurrentRequestDictionary()
            interactionSent.fulfill()
        })

        manager.sendNotificationInteraction(segmentifyObject: makeClick(instanceId: "psh_abc", interactionId: nil))

        wait(for: [interactionSent], timeout: 3)
        XCTAssertEqual(sentRequest["type"] as? String, "push")
        XCTAssertEqual(sentRequest["interactionId"] as? String, "psh_abc")
    }

    func testClickKeepsPostingLegacyNotificationInteraction() {
        let legacyPosted = expectation(description: "legacy notification interaction posted")

        MockURLProtocol.requestHandler = stubAllRequests(onLegacyNotification: {
            legacyPosted.fulfill()
        })

        manager.sendNotificationInteraction(segmentifyObject: makeClick(instanceId: "psh_abc", interactionId: "static"))

        wait(for: [legacyPosted], timeout: 3)
        XCTAssertEqual(UserDefaults.standard.string(forKey: "SEGMENTIFY_PUSH_CAMPAIGN_ID"), "psh_abc")
    }

    func testClickViewStillSendsClickType() {
        let interactionSent = expectation(description: "click interaction dispatched")
        var sentRequest: [AnyHashable: Any] = [:]

        MockURLProtocol.requestHandler = stubAllRequests(onInteraction: {
            sentRequest = self.manager.testingCurrentRequestDictionary()
            interactionSent.fulfill()
        })

        manager.sendClickView(instanceId: "widget_1", interactionId: "product_1")

        wait(for: [interactionSent], timeout: 3)
        XCTAssertEqual(sentRequest["type"] as? String, "click")
        XCTAssertEqual(sentRequest["instanceId"] as? String, "widget_1")
        XCTAssertEqual(sentRequest["interactionId"] as? String, "product_1")
    }

    func testHandlePushClickedPostsInteractionWithPayloadInstanceId() {
        let legacyPosted = expectation(description: "push click posted to the interaction endpoint")

        MockURLProtocol.requestHandler = stubAllRequests(onLegacyNotification: {
            legacyPosted.fulfill()
        })

        manager.handlePushClicked(SegmentifyPushPayload(userInfo: ["instanceId": "psh_abc"]))

        wait(for: [legacyPosted], timeout: 3)
        XCTAssertEqual(UserDefaults.standard.string(forKey: "SEGMENTIFY_PUSH_CAMPAIGN_ID"), "psh_abc")
    }

    func testHandlePushReceivedPostsViewToTheInteractionEndpoint() {
        let viewPosted = expectation(description: "push view posted to the interaction endpoint")

        MockURLProtocol.requestHandler = stubAllRequests(onLegacyNotification: {
            viewPosted.fulfill()
        })

        manager.handlePushReceived(SegmentifyPushPayload(userInfo: ["instanceId": "psh_abc"]))

        wait(for: [viewPosted], timeout: 3)
    }

    func testHandlePushWithoutInstanceIdSendsNothing() {
        let nothingSent = expectation(description: "no push interaction request")
        nothingSent.isInverted = true

        MockURLProtocol.requestHandler = stubAllRequests(onLegacyNotification: {
            nothingSent.fulfill()
        })

        manager.handlePushReceived(SegmentifyPushPayload(userInfo: [:]))
        manager.handlePushClicked(SegmentifyPushPayload(userInfo: ["instanceId": ""]))

        wait(for: [nothingSent], timeout: 1)
        XCTAssertNil(UserDefaults.standard.string(forKey: "SEGMENTIFY_PUSH_CAMPAIGN_ID"))
    }

    func testActionTapSendsActionId() throws {
        let model = try XCTUnwrap(SegmentifyManager.pushActionInteractionModel(payload: twoButtonPayload(), actionIdentifier: "action1"))

        XCTAssertEqual(model.type, .CLICK)
        XCTAssertEqual(model.instanceId, "psh_abc")
        XCTAssertEqual(model.params, ["actionId": "action1"])
    }

    func testDefaultTapSendsClickWithoutActionId() throws {
        let model = try XCTUnwrap(SegmentifyManager.pushActionInteractionModel(payload: twoButtonPayload(), actionIdentifier: UNNotificationDefaultActionIdentifier))

        XCTAssertEqual(model.type, .CLICK)
        XCTAssertTrue(model.params.isEmpty)
    }

    func testDismissSendsNothing() {
        XCTAssertNil(SegmentifyManager.pushActionInteractionModel(payload: twoButtonPayload(), actionIdentifier: UNNotificationDismissActionIdentifier))
    }

    func testHandlePushClickedWithActionOpensItsTargetAndPostsTheClick() {
        let legacyPosted = expectation(description: "button click posted to the interaction endpoint")
        var opened: [URL] = []
        var postedBody: [String: Any]?
        SegmentifyManager.pushTargetOpener = { opened.append($0) }

        MockURLProtocol.requestHandler = stubAllRequests(onLegacyNotificationRequest: { request in
            postedBody = self.jsonBody(of: request)
            legacyPosted.fulfill()
        })

        manager.handlePushClicked(twoButtonPayload(), actionIdentifier: "action0")

        wait(for: [legacyPosted], timeout: 3)
        XCTAssertEqual(opened, [URL(string: "app://view")!])
        XCTAssertEqual(UserDefaults.standard.string(forKey: "SEGMENTIFY_PUSH_CAMPAIGN_ID"), "psh_abc")
        XCTAssertEqual(postedBody?["type"] as? String, "CLICK")
        XCTAssertEqual(postedBody?["instanceId"] as? String, "psh_abc")
        XCTAssertEqual(postedBody?["params"] as? [String: String], ["actionId": "action0"])
    }

    func testBodyTapGoesThroughTheOverridableHandlePushClicked() {
        let recording = RecordingPushManager()

        recording.handlePushClicked(twoButtonPayload(), actionIdentifier: UNNotificationDefaultActionIdentifier)

        XCTAssertEqual(recording.bodyTaps, 1)
    }

    func testButtonTapDoesNotGoThroughTheBodyTapHandler() {
        let recording = RecordingPushManager()
        SegmentifyManager.pushTargetOpener = { _ in }

        recording.handlePushClicked(twoButtonPayload(), actionIdentifier: "action1")

        XCTAssertEqual(recording.bodyTaps, 0)
    }

    func testHandlePushClickedWithDefaultTapOpensNothing() {
        let legacyPosted = expectation(description: "body click posted to the interaction endpoint")
        var opened: [URL] = []
        SegmentifyManager.pushTargetOpener = { opened.append($0) }

        MockURLProtocol.requestHandler = stubAllRequests(onLegacyNotification: {
            legacyPosted.fulfill()
        })

        manager.handlePushClicked(twoButtonPayload(), actionIdentifier: UNNotificationDefaultActionIdentifier)

        wait(for: [legacyPosted], timeout: 3)
        XCTAssertTrue(opened.isEmpty)
    }

    func testActionTargetIsTheDeeplinkThenTheTrackedUrlThenTheRedirectUrl() {
        let payload = twoButtonPayload()

        XCTAssertEqual(payload.actionTargetUrl(for: "action0"), "app://view")
        XCTAssertEqual(payload.actionTargetUrl(for: "action1"), "https://shop.example.com/shop?_sgm_campaign=psh_abc")

        let untracked = SegmentifyPushPayload(userInfo: ["instanceId": "psh_abc", "actions": twoButtonActions])
        XCTAssertEqual(untracked.actionTargetUrl(for: "action1"), "https://shop.example.com/shop")
    }

    func testActionKeepsItsOwnTrackedUrlWhenAnEarlierItemIsDropped() {
        let payload = SegmentifyPushPayload(userInfo: [
            "instanceId": "psh_abc",
            "actions": "[{\"title\":\"No action key\",\"redirectUrl\":\"https://shop.example.com/broken\"},"
                + "{\"action\":\"shop\",\"title\":\"Shop Now\",\"redirectUrl\":\"https://shop.example.com/shop\"}]",
            "actionUrls": "[\"https://shop.example.com/broken?_sgm_campaign=psh_abc\",\"https://shop.example.com/shop?_sgm_campaign=psh_abc\"]"
        ])

        XCTAssertEqual(payload.actions.map(\.action), ["shop"])
        XCTAssertEqual(payload.actionUrls, ["https://shop.example.com/shop?_sgm_campaign=psh_abc"])
        XCTAssertEqual(payload.actionTargetUrl(for: "action0"), "https://shop.example.com/shop?_sgm_campaign=psh_abc")
    }

    func testDefaultTapAndUnknownButtonsHaveNoActionTarget() {
        let payload = twoButtonPayload()

        XCTAssertNil(payload.actionTargetUrl(for: UNNotificationDefaultActionIdentifier))
        XCTAssertNil(payload.actionTargetUrl(for: "action2"))
    }

    private let twoButtonActions = "[{\"action\":\"view\",\"title\":\"View\",\"redirectUrl\":\"https://shop.example.com/view\",\"deeplink\":\"app://view\"},"
        + "{\"action\":\"shop\",\"title\":\"Shop Now\",\"redirectUrl\":\"https://shop.example.com/shop\"}]"

    private func twoButtonPayload() -> SegmentifyPushPayload {
        SegmentifyPushPayload(userInfo: [
            "instanceId": "psh_abc",
            "sgmVersion": "2",
            "actions": twoButtonActions,
            "actionUrls": "[\"https://shop.example.com/view?_sgm_campaign=psh_abc\",\"https://shop.example.com/shop?_sgm_campaign=psh_abc\"]"
        ])
    }

    private func makeClick(instanceId: String, interactionId: String?) -> NotificationModel {
        let model = NotificationModel()
        model.type = .CLICK
        model.instanceId = instanceId
        model.interactionId = interactionId
        return model
    }

    private func stubAllRequests(
        onInteraction: @escaping () -> Void = {},
        onLegacyNotification: @escaping () -> Void = {},
        onLegacyNotificationRequest: @escaping (URLRequest) -> Void = { _ in }
    ) -> (URLRequest) throws -> (HTTPURLResponse, Data) {
        { request in
            let path = request.url?.absoluteString ?? ""
            if path.contains("/add/events/") {
                onInteraction()
            }
            if path.contains("/native/interaction/notification") {
                onLegacyNotification()
                onLegacyNotificationRequest(request)
            }
            let response = SegmentifyTestSupport.httpResponse(for: request)
            let data = try SegmentifyTestSupport.emptyEventResponse()
            return (response, data)
        }
    }

    private func jsonBody(of request: URLRequest) -> [String: Any]? {
        var data = request.httpBody ?? Data()
        if data.isEmpty, let stream = request.httpBodyStream {
            stream.open()
            defer { stream.close() }
            var buffer = [UInt8](repeating: 0, count: 1024)
            while stream.hasBytesAvailable {
                let count = stream.read(&buffer, maxLength: buffer.count)
                guard count > 0 else { break }
                data.append(buffer, count: count)
            }
        }
        return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
    }
}

private final class RecordingPushManager: SegmentifyManager {
    var bodyTaps = 0

    override func handlePushClicked(_ payload: SegmentifyPushPayload) {
        bodyTaps += 1
    }
}
