//
//  SegmentifyManager+PushActions.swift
//  Segmentify

import Foundation
import UserNotifications
#if canImport(UIKit)
import UIKit
#endif

extension SegmentifyManager {

    static var pushTargetOpener: (URL) -> Void = SegmentifyManager.openInApplication
    static var notificationCategoriesSetter: (Set<UNNotificationCategory>) -> Void = SegmentifyManager.setInNotificationCenter

    public func registerPushActionCategories(with appCategories: Set<UNNotificationCategory> = []) {
        SegmentifyManager.setPushActionCategories(with: appCategories)
    }

    public func pushActionCategories() -> Set<UNNotificationCategory> {
        SegmentifyManager.takePushActionCategories()
    }

    static func setPushActionCategories(with appCategories: Set<UNNotificationCategory>) {
        notificationCategoriesSetter(PushActionCategories.merged(with: appCategories))
        UserDefaults.standard.set(true, forKey: PushActionCategories.registeredKey)
    }

    static func takePushActionCategories() -> Set<UNNotificationCategory> {
        UserDefaults.standard.set(true, forKey: PushActionCategories.registeredKey)
        return PushActionCategories.merged(with: [])
    }

    static func setInNotificationCenter(_ categories: Set<UNNotificationCategory>) {
        UNUserNotificationCenter.current().setNotificationCategories(categories)
    }

    public func handlePushClicked(_ payload: SegmentifyPushPayload, actionIdentifier: String) {
        guard actionIdentifier != UNNotificationDismissActionIdentifier else {
            return
        }
        if let target = payload.actionTargetUrl(for: actionIdentifier) {
            SegmentifyManager.openPushTarget(target)
        }
        guard let model = SegmentifyManager.pushActionInteractionModel(payload: payload, actionIdentifier: actionIdentifier) else {
            print("Error - push payload has no instanceId, push CLICK event is not sent")
            return
        }
        sendNotificationInteraction(segmentifyObject: model)
    }

    static func registrationSupportsActions(for type: NotificationType?) -> Bool? {
        guard type == .PERMISSION_INFO, UserDefaults.standard.bool(forKey: PushActionCategories.registeredKey) else {
            return nil
        }
        return true
    }

    static func pushActionInteractionModel(payload: SegmentifyPushPayload, actionIdentifier: String) -> NotificationModel? {
        guard actionIdentifier != UNNotificationDismissActionIdentifier,
              let model = pushInteractionModel(payload: payload, type: .CLICK) else {
            return nil
        }
        if PushActionCategories.actionIndex(for: actionIdentifier) != nil {
            model.params[PushActionCategories.actionIdParam] = actionIdentifier
        }
        return model
    }

    static func openInApplication(_ url: URL) {
        #if canImport(UIKit)
        DispatchQueue.main.async {
            UIApplication.shared.open(url)
        }
        #endif
    }

    private static func openPushTarget(_ target: String) {
        guard let url = URL(string: target) else {
            print("Error - push button target is not a valid URL, it is not opened")
            return
        }
        pushTargetOpener(url)
    }
}
