---
title: "Search"
description: "Get instant and faceted search results from Segmentify and report clicks on them."
---

Segmentify Search has two modes. **Instant search** answers while the user types, in the search box. **Faceted search** returns a full results screen with filters, sorting and paging.

## Instant search

Send the current text each time it changes. Send an empty `query` when the search box opens, to get the "before search" content such as popular products and last searches.

```swift
let search = SearchPageModel()
search.query = "sneak"      // empty string before the user types
search.lang = "EN"
search.currency = "EUR"

SegmentifyManager.sharedManager().sendSearchPageView(segmentifyObject: search) { response in
    // response.products, response.keywords, response.categories, response.brands, response.lastSearches
}
```

The response holds `products`, plus `keywords`, `categories`, `brands`, `categoryProducts`, `brandProducts` and `lastSearches` to build the search box's sections.

## Faceted search

```swift
let search = SearchFacetPageModel()
search.query = "sneakers"
search.type = "faceted"
search.trigger = "keyword"                 // what caused the search: keyword, filter, order or page
search.ordering = FacetedOrdering(page: 1, sort: "SMART_SORTING")
search.filters = [FacetedFilter(facet: "brand", values: ["Acme"])]
search.lang = "EN"
search.currency = "EUR"

SegmentifyManager.sharedManager().sendFacetedSearchPageView(segmentifyObject: search) { response in
    // response.products, response.facets, response.meta, response.banners, response.instanceId
}
```

| Property | Description |
| --- | --- |
| `query` | The text searched. |
| `trigger` | What caused this request: `keyword` (a new search), `filter` (a filter changed), `order` (the sort changed) or `page` (another page). |
| `ordering` | The page number, starting at 1, and the sort. |
| `filters` | The selected filters, each a facet name and its selected values. |

The response holds `products`, `facets` (the available filters and their values), `meta` (paging and totals), `banners` and the `instanceId` of the search campaign.

## Report clicks

When the user taps a product in search results, report it with the search campaign's `instanceId` and the product ID:

```swift
SegmentifyManager.sharedManager().sendSearchClickView(instanceId: instanceId, interactionId: "SKU-1001")
```

Report when the results are shown with `sendImpression` and `sendWidgetView`, as for recommendation widgets. See [Interactions and Banners](/events/interactions/).

## Clear a last search

When the user deletes an entry from their last searches:

```swift
let user = UserModel()
user.lastSearchDeletedKeywords = "sneakers"
SegmentifyManager.sharedManager().sendUserClearLastSearchHistory(segmentifyObject: user)
```
