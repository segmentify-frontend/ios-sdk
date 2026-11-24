---
title: "Configuration"
description: "Initialise the Segmentify iOS SDK, and set session length, logging and the fields every event shares."
---

## Initialise the SDK

Configure the SDK once, when the app starts, before sending any event.

```swift
import Segmentify
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        SegmentifyManager.config(
            appkey: "YOUR_API_KEY",
            dataCenterUrl: "https://gandalf-eu.segmentify.com",   // your data center URL
            subDomain: "www.yourdomain.com"                        // the domain registered for your account
        )
        return true
    }
}
```

After `config`, use the shared instance for every event: `SegmentifyManager.sharedManager()`.

| Parameter | Description |
| --- | --- |
| API key | Your Segmentify API key. |
| Data center URL | The full URL of your data center, starting with `https://`. |
| Domain | The domain registered for your Segmentify account. It is sent as the `Origin` of every request and must match the account, or requests are rejected. |

- Call `config` before the first `sharedManager()`. Without an API key the SDK prints an error and events are not sent.
- Logging is on by default. Turn it off for release builds.

## Options

```swift
_ = SegmentifyManager.setSessionKeepSecond(sessionKeepSecond: 86400)   // session length in seconds; 86400 is the default
_ = SegmentifyManager.logStatus(isVisible: false)                      // SDK logs in the Xcode console; on by default
```

| Option | Default | Description |
| --- | --- | --- |
| Session length | `86400` seconds (24 hours) | How long a session ID is kept before a new one is created. |
| Logging | on | Prints what the SDK does, including why an event was not sent. |

## User and session IDs

You do not create user or session IDs. On first launch the SDK asks Segmentify for a user ID and a session ID and stores them in `UserDefaults`. The user ID is kept; the session ID is replaced when the session length has passed.

## Fields every event shares

Every event model has these properties. Set them on each event you send.

```swift
let page = PageModel()
page.category = "Home Page"
page.lang = "EN"
page.currency = "EUR"
page.testMode = true                                    // remove before going live
page.params = ["campaign": "summer" as AnyObject]       // optional custom values
```

| Property | Description |
| --- | --- |
| `lang` | Language of the content, for example `EN`. Must be a language configured for your account. Set it on every event: when it is missing, `EN` is assumed, and accounts without English get no result. |
| `currency` | Currency of the prices, for example `EUR`. Must be a currency configured for your account. |
| `region` | Region of the user, if your account uses regions. |
| `params` | Custom key-value pairs to send with the event. |
| `testMode` | `true` marks a test event. Test events are answered by test-mode campaigns and kept apart from live data. |
| `pageUrl` | URL or deep link of the screen. |

## Switching account at runtime

If one app serves several Segmentify accounts (for example one per country), change the configuration when the user switches:

```swift
SegmentifyManager.setConfig(apiKey: "OTHER_API_KEY", dataCenterUrl: "https://gandalf-eu.segmentify.com", subDomain: "www.otherdomain.com")
```

Next: [Your first integration](/getting-started/first-integration/).
