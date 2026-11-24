---
title: "Push Notifications"
description: "Register the device with Segmentify and report views and clicks of push campaigns."
---

Segmentify sends push campaigns through Firebase Cloud Messaging (FCM) or APNs. Your app receives and displays the notifications; the SDK registers the device and reports what happens to each notification.

## Set up

Set the push data center next to `config`:

```swift
SegmentifyManager.config(appkey: "YOUR_API_KEY", dataCenterUrl: "https://gandalf-eu.segmentify.com", subDomain: "www.yourdomain.com")
SegmentifyManager.setPushConfig(dataCenterUrlPush: "https://gimli-eu.segmentify.com")   // your push data center URL
```

Without it the push methods print an error and send nothing.

Enable the **Push Notifications** capability for your target, request the user's permission with `UNUserNotificationCenter`, and call `registerForRemoteNotifications()`. If you deliver through Firebase, add Firebase Messaging as described in the [Firebase documentation](https://firebase.google.com/docs/cloud-messaging/ios/client). The SDK does not include Firebase.

## Register the device token

Send the token to Segmentify whenever you receive or refresh it.

```swift
// Firebase: MessagingDelegate
func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    guard let fcmToken else { return }
    let model = NotificationModel()
    model.type = NotificationType.PERMISSION_INFO
    model.providerType = ProviderType.FIREBASE     // use ProviderType.APNS with a raw APNs token
    model.deviceToken = fcmToken
    SegmentifyManager.sharedManager().sendNotification(segmentifyObject: model)
}
```

With APNs directly, send the hex string of the device token from `application(_:didRegisterForRemoteNotificationsWithDeviceToken:)` and set `providerType` to `.APNS`.

Without a registered token the user cannot be targeted by push campaigns.

## Report views and clicks

Build a `SegmentifyPushPayload` from the incoming message and hand it to the SDK.

```swift
extension AppDelegate: UNUserNotificationCenterDelegate {
    // shown while the app is in the foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let payload = SegmentifyPushPayload(userInfo: notification.request.content.userInfo)
        SegmentifyManager.sharedManager().handlePushReceived(payload)
        completionHandler([.banner, .sound, .badge])
    }

    // the user tapped the notification
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let payload = SegmentifyPushPayload(userInfo: response.notification.request.content.userInfo)
        SegmentifyManager.sharedManager().handlePushClicked(payload)
        if let target = payload.targetUrl, let url = URL(string: target) {
            DispatchQueue.main.async { UIApplication.shared.open(url) }
        }
        completionHandler()
    }
}
```

Set the delegate at launch: `UNUserNotificationCenter.current().delegate = self`.

`handlePushReceived` reports a view and `handlePushClicked` reports a click. Both need the payload's `instanceId`; a message without one is not a Segmentify campaign and is ignored.

## The payload

| Property | Type | Description |
| --- | --- | --- |
| `title`, `message` | `String` | Text of the notification. Empty when not sent. |
| `image` | `String?` | Image URL. |
| `deeplink`, `redirectUrl` | `String?` | Where a tap should lead. |
| `targetUrl` | `String?` | `deeplink` if present, otherwise `redirectUrl`. |
| `instanceId` | `String?` | ID of the push campaign. Needed to report views and clicks. |
| `tag` | `String?` | Notification tag. |
| `actions` | `[SegmentifyPushAction]` | Action buttons, each with `action`, `title`, `icon`, `redirectUrl`, `deeplink`. |
| `providerType` | `ProviderType` | `.FIREBASE` or `.APNS`, detected from the message. |
| `isV2` | `Bool` | Whether the message uses the current payload format. |

## Attribute what happens next

After a click, the SDK remembers the campaign so you can attribute the visit that follows:

```swift
let utm = SegmentifyManager.sharedManager().getTrackingParameters()
// utm.utm_source, utm.utm_medium, utm.utm_campaign, utm.utm_content
```

Add these to the deep link or to your own analytics events if you track campaign sources.

## Checklist

- The push data center URL is set.
- The token is sent on first launch and on every refresh.
- Views are reported when a notification arrives, and clicks when it is tapped.
- The notification opens `targetUrl` when one is present.
