---
title: "Product View"
description: "Report a product detail screen with sendProductView. Keeps the product catalogue current and returns product-page recommendations."
---

Send a product view when a product's detail screen opens. It does two jobs: it records the user's interest, and it updates the product (price, stock, image) in your Segmentify catalogue.

```swift
let product = ProductModel()
product.productId = "SKU-1001"
product.name = "Runner Sneakers"
product.url = "https://www.yourdomain.com/runner-sneakers"
product.image = "https://cdn.yourdomain.com/img/sku-1001.jpg"
product.categories = ["Shoes", "Sneakers"]
product.price = 135.0
product.oldPrice = 160.0
product.brand = "Acme"
product.inStock = true
product.lang = "EN"
product.currency = "EUR"

SegmentifyManager.sharedManager().sendProductView(segmentifyObject: product) { recommendations in
    // recommendations for the product screen
}
```

Send a [page view](/events/page-view/) with category `Product Page` for the same screen as well.

## Properties

| Property | Type | Required | Description |
| --- | --- | --- | --- |
| `productId` | `String` | Yes | Your ID of the product. |
| `name` | `String` | Yes | Product name. |
| `url` | `String` | Yes | Product page URL. |
| `image` | `String` | Yes | Main image URL. |
| `price` | `NSNumber` | Yes | Current price. |
| `category` | `String` | One of the two | A single category. |
| `categories` | `[String]` | One of the two | The category path. Set either `category` or `categories`, not both. |
| `oldPrice` | `NSNumber` | No | Price before discount. |
| `brand` | `String` | No | Brand name. |
| `inStock` | `Bool` | No | Whether the product can be bought. |
| `mUrl` | `String` | No | Mobile product page URL. |
| `imageXS`, `imageS`, `imageM`, `imageL`, `imageXL` | `String` | No | Image URLs in other sizes. |
| `gender` | `String` | No | Target gender. |
| `colors`, `sizes`, `labels` | `[String]` | No | Product attributes. |
| `noUpdate` | `Bool` | No | `true` sends the view without updating the product in the catalogue. |

Plus the [shared fields](/getting-started/configuration/#fields-every-event-shares).

## Rules

- The event is **not sent** if `productId`, `name`, `url`, `image` or `price` is missing, if both `category` and `categories` are set, or if neither is. The SDK logs which one.
- `productId` must be the same ID your product feed and website use for the product.
- `oldPrice` is only used when it is greater than `price`.
- Send `currency` with the price.
