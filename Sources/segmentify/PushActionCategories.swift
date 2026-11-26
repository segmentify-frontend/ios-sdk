//
//  PushActionCategories.swift
//  Segmentify

import Foundation
import UserNotifications

enum PushActionCategories {
    static let registeredKey = "SEGMENTIFY_PUSH_ACTIONS_REGISTERED"
    static let actionIdParam = "actionId"

    private static let categoryPrefix = "segmentify_"
    private static let actionPrefix = "action"
    private static let defaultLocalization = "en"
    private static let titleKeys = ["segmentify_push_action_view", "segmentify_push_action_shop_now"]

    static func merged(with existing: Set<UNNotificationCategory>) -> Set<UNNotificationCategory> {
        let own = categories(titles: titles(in: SDKVersion.resourceBundle))
        let ownIdentifiers = Set(own.map(\.identifier))
        return existing.filter { !ownIdentifiers.contains($0.identifier) }.union(own)
    }

    static func titles(localization: String) -> [String] {
        let bundle = localizedBundle(localization) ?? localizedBundle(defaultLocalization) ?? SDKVersion.resourceBundle
        return titles(in: bundle)
    }

    static func actionIndex(for actionIdentifier: String) -> Int? {
        guard actionIdentifier.hasPrefix(actionPrefix),
              let index = Int(actionIdentifier.dropFirst(actionPrefix.count)),
              titleKeys.indices.contains(index) else {
            return nil
        }
        return index
    }

    private static func categories(titles: [String]) -> Set<UNNotificationCategory> {
        let actions = titles.enumerated().map { index, title in
            UNNotificationAction(identifier: actionPrefix + String(index), title: title, options: [.foreground])
        }
        return Set(actions.indices.map { index in
            UNNotificationCategory(
                identifier: categoryPrefix + String(index + 1),
                actions: Array(actions.prefix(index + 1)),
                intentIdentifiers: [],
                options: []
            )
        })
    }

    private static func titles(in bundle: Bundle) -> [String] {
        titleKeys.map { bundle.localizedString(forKey: $0, value: nil, table: nil) }
    }

    private static func localizedBundle(_ localization: String) -> Bundle? {
        SDKVersion.resourceBundle.path(forResource: localization, ofType: "lproj").flatMap(Bundle.init(path:))
    }
}
