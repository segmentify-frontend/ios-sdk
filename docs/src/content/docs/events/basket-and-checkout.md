---
title: "Basket and Checkout"
description: "Report basket changes and the steps of the checkout funnel, from viewing the basket to a completed order."
---

## Basket changes

Call `sendAddOrRemoveBasket` when a product is added to or removed from the basket.

```swift
let basket = BasketModel()
basket.step = "add"            // or "remove"
basket.productId = "SKU-1001"
basket.quantity = 1
basket.price = 135.0
basket.lang = "EN"
basket.currency = "EUR"
SegmentifyManager.sharedManager().sendAddOrRemoveBasket(segmentifyObject: basket)
```

A shorter form takes the values directly:

```swift
SegmentifyManager.sharedManager().sendAddOrRemoveBasket(basketStep: "add", productID: "SKU-1001", quantity: 1, price: 135.0)
```

| Property | Required | Description |
| --- | --- | --- |
| `step` | Yes | `add` or `remove`. |
| `productId` | Yes | The product. |
| `quantity` | Yes | How many were added or removed. |
| `price` | Recommended | Unit price. |

Without `step`, `productId` or `quantity` the event is not sent.

## Checkout steps

The checkout methods all take the basket's total and its products.

```swift
let checkout = CheckoutModel()
checkout.totalPrice = 135.0
checkout.productList = [
    ["productId": "SKU-1001", "quantity": 1, "price": 135.0]
]
checkout.lang = "EN"
checkout.currency = "EUR"
```

Each item of `productList` is a dictionary with `productId`, `quantity` and `price`.

Then call the method for the step the user is on:

```swift
let manager = SegmentifyManager.sharedManager()

manager.sendViewBasket(segmentifyObject: checkout) { recommendations in }            // basket screen
manager.sendCustomerInformation(segmentifyObject: checkout) { recommendations in }   // address / customer step
manager.sendPaymentInformation(segmentifyObject: checkout) { recommendations in }    // payment step

checkout.orderNo = "ORDER-98765"
manager.sendPurchase(segmentifyObject: checkout) { recommendations in }              // order completed
```

| Method | When |
| --- | --- |
| `sendViewBasket` | The basket screen opens. |
| `sendCustomerInformation` | The user is on the customer or address step. |
| `sendPaymentInformation` | The user is on the payment step. |
| `sendPurchase` | The order is completed. |

| Property | Required | Description |
| --- | --- | --- |
| `totalPrice` | Yes | Total of the basket or order. |
| `productList` | Yes | The products, each with `productId`, `quantity` and `price`. |
| `orderNo` | For purchase | Your order number. |

## Rules

- Call `sendPurchase` **once per order**. Calling it again on a screen refresh counts the revenue twice.
- `totalPrice` and the product prices are in the currency named by `currency`.
- All four methods return recommendations to their callback, for example "you may also like" on the basket screen.
