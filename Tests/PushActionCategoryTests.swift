import XCTest
import UserNotifications
@testable import Segmentify

final class PushActionCategoryTests: XCTestCase {

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: PushActionCategories.registeredKey)
        SegmentifyManager.notificationCategoriesSetter = SegmentifyManager.setInNotificationCenter
        super.tearDown()
    }

    func testRegisteringSetsTheAppAndSegmentifyCategoriesInOneCall() {
        var calls: [Set<UNNotificationCategory>] = []
        SegmentifyManager.notificationCategoriesSetter = { calls.append($0) }
        let appCategory = UNNotificationCategory(identifier: "app_category", actions: [], intentIdentifiers: [], options: [])

        SegmentifyManager.setPushActionCategories(with: [appCategory])

        XCTAssertEqual(calls.count, 1)
        XCTAssertEqual(Set(calls.first?.map(\.identifier) ?? []), ["app_category", "segmentify_1", "segmentify_2"])
        XCTAssertTrue(UserDefaults.standard.bool(forKey: PushActionCategories.registeredKey))
    }

    func testHostCanTakeTheSegmentifyCategoriesForItsOwnCall() {
        var calls: [Set<UNNotificationCategory>] = []
        SegmentifyManager.notificationCategoriesSetter = { calls.append($0) }

        let categories = SegmentifyManager.takePushActionCategories()

        XCTAssertEqual(Set(categories.map(\.identifier)), ["segmentify_1", "segmentify_2"])
        XCTAssertTrue(calls.isEmpty)
        XCTAssertTrue(UserDefaults.standard.bool(forKey: PushActionCategories.registeredKey))
    }

    func testRegistersBothCategoriesAndKeepsExisting() {
        let appCategory = UNNotificationCategory(identifier: "app_category", actions: [], intentIdentifiers: [], options: [])

        let categories = PushActionCategories.merged(with: [appCategory])

        XCTAssertEqual(Set(categories.map(\.identifier)), ["app_category", "segmentify_1", "segmentify_2"])
        XCTAssertEqual(actionIdentifiers(of: "segmentify_1", in: categories), ["action0"])
        XCTAssertEqual(actionIdentifiers(of: "segmentify_2", in: categories), ["action0", "action1"])
    }

    func testReplacesAnEarlierSegmentifyCategoryInsteadOfAddingASecondOne() {
        let earlier = UNNotificationCategory(identifier: "segmentify_2", actions: [], intentIdentifiers: [], options: [])

        let categories = PushActionCategories.merged(with: [earlier])

        XCTAssertEqual(categories.filter { $0.identifier == "segmentify_2" }.count, 1)
        XCTAssertEqual(actionIdentifiers(of: "segmentify_2", in: categories), ["action0", "action1"])
    }

    func testButtonsOpenTheApp() {
        let categories = PushActionCategories.merged(with: [])

        let actions = categories.flatMap(\.actions)
        XCTAssertFalse(actions.isEmpty)
        XCTAssertTrue(actions.allSatisfy { $0.options.contains(.foreground) })
    }

    func testButtonTitlesInEnglishTurkishAndArabic() {
        XCTAssertEqual(PushActionCategories.titles(localization: "en"), ["View", "Shop Now"])
        XCTAssertEqual(PushActionCategories.titles(localization: "tr"), ["Görüntüle", "Alışverişe Başla"])
        XCTAssertEqual(PushActionCategories.titles(localization: "ar"), ["عرض", "تسوق الآن"])
    }

    func testOtherLanguagesUseTheEnglishTitles() {
        XCTAssertEqual(PushActionCategories.titles(localization: "de"), ["View", "Shop Now"])
    }

    func testRegisteredButtonTitlesFollowThePhoneLanguage() {
        XCTAssertEqual(buttonTitles(preferredLanguages: ["tr-TR", "en-US"]), ["Görüntüle", "Alışverişe Başla"])
        XCTAssertEqual(buttonTitles(preferredLanguages: ["ar-SA"]), ["عرض", "تسوق الآن"])
        XCTAssertEqual(buttonTitles(preferredLanguages: ["en-GB", "tr-TR"]), ["View", "Shop Now"])
    }

    func testRegisteredButtonTitlesAreEnglishForOtherPhoneLanguages() {
        XCTAssertEqual(buttonTitles(preferredLanguages: ["de-DE", "fr-FR"]), ["View", "Shop Now"])
    }

    func testRegistrationSendsSupportsActionsOnceTheCategoriesAreRegistered() throws {
        UserDefaults.standard.set(true, forKey: PushActionCategories.registeredKey)

        let json = try subscriptionJson(type: .PERMISSION_INFO)

        XCTAssertEqual(json["supportsActions"] as? Bool, true)
    }

    func testRegistrationHasNoSupportsActionsWithoutTheCategories() throws {
        let json = try subscriptionJson(type: .PERMISSION_INFO)

        XCTAssertNil(json["supportsActions"])
    }

    func testInteractionsDoNotCarrySupportsActions() {
        UserDefaults.standard.set(true, forKey: PushActionCategories.registeredKey)

        XCTAssertNil(SegmentifyManager.registrationSupportsActions(for: .VIEW))
        XCTAssertNil(SegmentifyManager.registrationSupportsActions(for: .CLICK))
    }

    private func buttonTitles(preferredLanguages: [String]) -> [String] {
        let categories = PushActionCategories.merged(with: [], preferredLanguages: preferredLanguages)
        return categories.first { $0.identifier == "segmentify_2" }?.actions.map(\.title) ?? []
    }

    private func actionIdentifiers(of category: String, in categories: Set<UNNotificationCategory>) -> [String] {
        categories.first { $0.identifier == category }?.actions.map(\.identifier) ?? []
    }

    private func subscriptionJson(type: NotificationType) throws -> [String: Any] {
        let model = NotificationModel()
        model.type = type
        model.deviceToken = "device-token"
        let body = try XCTUnwrap(SegmentifyManager.subscriptionBody(for: model))
        return try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
    }
}
