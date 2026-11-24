---
title: "User Events"
description: "Tell Segmentify who the user is: sign-up, sign-in, profile changes, consent and channel subscriptions."
---

There are two sets of user methods. Use the **CDP user events** in new integrations. The older **user operations** are still supported.

## CDP user events

Each method takes the user's profile.

```swift
let profile: CdpEventsPayload = [
    "email": "jane@example.com",
    "phone": "905551234567",
    "username": "jane",
    "fullName": "Jane Doe",
    "gender": "female",
    "emailConsent": "SUBSCRIBED",
    "loyaltyLevel": "gold"
]

let manager = SegmentifyManager.sharedManager()
manager.registerUser(profile)   // after sign-up
manager.loginUser(profile)      // after sign-in
manager.identifyUser(profile)   // when the profile is known or has changed
manager.userTraits(profile)     // to update traits
manager.logoutUser(profile)     // after sign-out
```

`CdpEventsPayload` is a `[String: Any]` dictionary.

| Key | Type | Description |
| --- | --- | --- |
| `email`, `phone`, `username` | `String` | Identifiers of the user. |
| `fullName`, `gender` | `String` | Profile fields. |
| `source` | `String` | Where the data came from. |
| `emailConsent`, `smsConsent`, `whatsappConsent`, `callConsent` | `String` | `SUBSCRIBED`, `UNSUBSCRIBED` or `NOT_SET`. |
| any other key | `String`, number or `Bool` | Your own attributes. |

| Method | When |
| --- | --- |
| `registerUser` | The user completed sign-up. |
| `loginUser` | The user signed in. |
| `identifyUser` | The app knows who the user is, or the profile changed. Sent only when the profile differs from the last one sent, so it is safe to call often. |
| `userTraits` | To update profile traits. |
| `logoutUser` | The user signed out. |

Behaviour to know:

- An empty profile is not sent.
- If you set at least one consent field, the others are sent as `NOT_SET`. If you set none, no consent is sent and stored consents are left as they are.

## Channel subscriptions

Report when a user subscribes to, or unsubscribes from, a channel.

```swift
let manager = SegmentifyManager.sharedManager()

manager.subscribeUser(.email(email: "jane@example.com", purpose: "MARKETING"))
manager.subscribeUser(.sms(phoneNumber: "905551234567"))
manager.subscribeUser(.whatsapp(phoneNumber: "905551234567"))
manager.subscribeUser(.call(phoneNumber: "905551234567"))
manager.subscribeUser(.iosPush(pushSubscriptionId: fcmToken))

manager.unsubscribeUser(CdpUnsubscribePayload(channel: .email, email: "jane@example.com"))
manager.unsubscribeUser(CdpUnsubscribePayload(channel: .sms, phoneNumber: "905551234567"))
```

## User operations (legacy)

```swift
let user = UserModel()
user.email = "jane@example.com"
user.username = "jane"          // your username or user ID
user.fullName = "Jane Doe"

let manager = SegmentifyManager.sharedManager()
manager.sendUserRegister(segmentifyObject: user)   // sign-up
manager.sendUserLogin(segmentifyObject: user)      // sign-in
manager.sendUserUpdate(segmentifyObject: user)     // profile change
manager.sendUserLogout(segmentifyObject: user)     // sign-out
```

Do not send both sets for the same action. Pick one per integration.
