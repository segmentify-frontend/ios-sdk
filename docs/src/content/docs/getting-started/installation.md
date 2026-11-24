---
title: "Installation"
description: "Add the Segmentify iOS SDK to your project."
---

The Segmentify iOS SDK supports **iOS 13** and higher.

## Add the SDK

**Swift Package Manager** (recommended). In Xcode choose **File > Add Package Dependencies**, enter the repository URL and add the `Segmentify` library to your app target:

```text
https://github.com/segmentify/ios-sdk
```

Or add it to a `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/segmentify/ios-sdk", from: "1.7.0")
]
```

**CocoaPods** (legacy). Add the pod to your `Podfile` and run `pod install`:

```ruby
pod "Segmentify"
```

Then import the module where you use it:

```swift
import Segmentify
```

## What you need from Segmentify

Have these ready before you configure the SDK. The API key and data center are under **Settings > Integrations** in the Segmentify panel.

| You need | Example | Used for |
| --- | --- | --- |
| API key | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` | Identifies your account. |
| Data center URL | `https://gandalf-eu.segmentify.com` | The host your account lives on. |
| Domain | `www.yourdomain.com` | The domain registered for your account. The SDK sends it with every request. |
| Push data center URL | `https://gimli-eu.segmentify.com` | Only if you use push notifications. |

Data centers by region:

| Region | Data center URL | Push data center URL |
| --- | --- | --- |
| Türkiye | `https://per2.segmentify.com` | `https://psh2.segmentify.com` |
| Europe | `https://gandalf-eu.segmentify.com` | `https://gimli-eu.segmentify.com` |
| Latin America | `https://gandalf-br.segmentify.com` | `https://gimli-br.segmentify.com` |

Use the one shown in your panel. An API key sent to another data center is not found.

Next: [Configuration](/getting-started/configuration/).
