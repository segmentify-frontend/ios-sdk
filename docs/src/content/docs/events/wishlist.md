---
title: "Wishlist"
description: "Report wishlist additions, removals and views."
---

```swift
let manager = SegmentifyManager.sharedManager()

manager.sendWishlistAdd(productId: "SKU-1001")
manager.sendWishlistRemove(productId: "SKU-1001")
manager.sendWishlistDetail(productId: "SKU-1001")
manager.sendWishlistViewFavorites(favoritesList: ["SKU-1001", "SKU-2002"])
```

To set `lang`, `currency` or `params`, build a `WishlistModel` and call `sendWishlist`:

```swift
let wishlist = WishlistModel()
wishlist.step = "add"          // add, remove, detail or view-favorites
wishlist.productId = "SKU-1001"
wishlist.lang = "EN"
manager.sendWishlist(segmentifyObject: wishlist)
```

| Step | Method | Needs |
| --- | --- | --- |
| `add` | `sendWishlistAdd` | `productId` |
| `remove` | `sendWishlistRemove` | `productId` |
| `detail` | `sendWishlistDetail` | `productId`. The user opened a product from the wishlist. |
| `view-favorites` | `sendWishlistViewFavorites` | `favoritesList`, the product IDs in the wishlist. May be empty. |

The event is not sent when the step is not one of the four, or when the field it needs is missing.
