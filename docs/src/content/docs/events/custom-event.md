---
title: "Custom Event"
description: "Send an event of your own to trigger Segmentify campaigns."
---

Use a custom event for anything the standard events do not cover, such as a newsletter sign-up or a store-locator search. Campaigns in the panel can be triggered by its `type`.

```swift
let event = CustomEventModel()
event.type = "newsletter-signup"
event.params = ["source": "footer" as AnyObject]
event.lang = "EN"
SegmentifyManager.sharedManager().sendCustomEvent(segmentifyObject: event) { recommendations in }

// or, with the values passed directly
SegmentifyManager.sharedManager().sendCustomEvent(type: "newsletter-signup", params: nil, lang: "EN") { recommendations in }
```

| Property | Required | Description |
| --- | --- | --- |
| `type` | Yes | Your name for the event. Must match the name used in the panel. |
| `params` | No | Extra values to send with the event. |

The callback receives recommendations if a campaign answers the event.
