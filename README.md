# GraphitProductAnalytics

GraphitProductAnalytics is a tiny, provider-neutral product analytics event value vocabulary for Swift apps and SDKs.

It defines validated immutable analytics values. It does **not** send events, queue events, flush events, retry delivery, persist events, identify users, track sessions, observe app lifecycle, track screens, or integrate with vendors.

## Requirements

- Swift 6.3.x
- Swift language mode 6
- iOS 18+ primary support
- macOS 15+ package support
- No Linux support claim in v1
- No third-party Swift dependencies
- No GraphitCache dependency in core v1

## Installation

Add the package URL to your Swift package or Xcode project:

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/graphit-live/graphit-swift-product-analytics.git", from: "0.1.0")
]
```

Then depend on the library product:

```swift
.product(name: "GraphitProductAnalytics", package: "graphit-swift-product-analytics")
```

Use the repository URL with tagged releases for reproducible dependency resolution.

## What core v1 owns

The public v1 surface is exactly these seven core types:

- `ProductAnalyticsEventName`
- `ProductAnalyticsPropertyKey`
- `ProductAnalyticsPropertyValue`
- `ProductAnalyticsProperties`
- `ProductAnalyticsEvent`
- `ProductAnalyticsBatch`
- `ProductAnalyticsError`

Core v1 is responsible for:

- strongly typed event names;
- strongly typed property keys;
- JSON-shaped property values;
- validated immutable event properties;
- validated immutable product analytics events;
- ordered validated batches;
- compact `Codable` values for app-owned or provider-owned composition.

Core v1 intentionally has no providers, networking, storage, GraphitCache integration, UI adapters, globals, service locators, property wrappers, macros, dynamic member lookup, tasks, actors, locks, queues, or lifecycle hooks.

## Quick start

Define app-owned schema constants for event names and property keys:

```swift
import Foundation
import GraphitProductAnalytics

enum AppAnalytics {
    enum Events {
        static let signupCompleted = ProductAnalyticsEventName("signup_completed")
    }

    enum Properties {
        static let plan = ProductAnalyticsPropertyKey("plan")
        static let source = ProductAnalyticsPropertyKey("source")
    }
}
```

Create an event by passing the occurrence time explicitly:

```swift
let event = try ProductAnalyticsEvent(
    name: AppAnalytics.Events.signupCompleted,
    occurredAt: Date.now,
    properties: [
        AppAnalytics.Properties.plan: .string("pro"),
        AppAnalytics.Properties.source: .string("paywall")
    ]
)
```

`occurredAt` is explicit by design. The core package does not read the clock for you, which keeps tests, queues, retries, and offline delivery able to preserve the original event time.

## Dedicated names and keys

`ProductAnalyticsEventName` and `ProductAnalyticsPropertyKey` are dedicated types instead of raw strings so call sites cannot accidentally pass a property key where an event name is expected, or vice versa.

Leaf construction is intentionally nonvalidating so apps can define schema constants cheaply. Validation happens when names and keys are used by aggregate values such as `ProductAnalyticsEvent` and `ProductAnalyticsProperties`.

## Property values

`ProductAnalyticsPropertyValue` is JSON-shaped and explicit:

```swift
let properties = try ProductAnalyticsProperties([
    ProductAnalyticsPropertyKey("plan"): .string("pro"),
    ProductAnalyticsPropertyKey("seat_count"): .number(3),
    ProductAnalyticsPropertyKey("is_trial"): .bool(false),
    ProductAnalyticsPropertyKey("coupon"): .null,
    ProductAnalyticsPropertyKey("items"): .array([.string("seat"), .string("storage")])
])
```

It is not `[String: Any]`. JSON strings stay strings, JSON numbers stay numbers, and the SDK does not coerce between them.

## Batches

A `ProductAnalyticsBatch` is an ordered immutable value:

```swift
let batch = try ProductAnalyticsBatch([event])
let singleEventBatch = ProductAnalyticsBatch(event)
```

Batches are not queues. Core does not deduplicate, merge, split, store, send, flush, or retry batches.

## Codable guidance

All core values are `Codable` so apps and future provider packages can compose them with app-owned queues, files, caches, databases, provider-owned offline stores, or tests:

```swift
let data = try JSONEncoder().encode(event)
let decoded = try JSONDecoder().decode(ProductAnalyticsEvent.self, from: data)
```

`ProductAnalyticsEvent` encodes as an object with `name`, `occurredAt`, and `properties`. The `occurredAt` value uses the encoder or decoder's normal `Date` strategy. Provider packages should map `Date` to their backend timestamp format at the transport boundary.

## Provider composition

Provider packages should depend on GraphitProductAnalytics and expose concrete provider-owned APIs. For example, a future PostHog package might choose a shape like this:

```swift
let client = try PostHogProductAnalyticsClient(configuration: configuration)
try await client.capture(event, context: context)
```

A provider-owned queue should make accepted-vs-delivered behavior explicit:

```swift
try await queue.enqueue(event, context: context) // accepted by the queue
try await queue.flush()                         // attempted delivery
```

These examples are provider-package guidance only. `PostHogProductAnalyticsClient`, `queue`, `context`, `capture`, `enqueue`, and `flush` are not part of core v1.

## Privacy notes

- Event names and property keys are app schema. Do not put secrets, tokens, raw private identifiers, or sensitive user data in names or keys.
- Property values may contain user-visible or private app data. Core validates structure but does not redact, normalize, inspect, log, persist, or send values.
- Apps and providers own consent, privacy policy, persistence, retention, redaction, and vendor mapping.
- Package-generated validation errors avoid echoing raw property values.

## Deferred features and non-goals

Do not expect placeholders for these in core v1:

- provider protocols or vendor clients;
- network transport, request/response models, retry, or backoff;
- in-memory or durable queues;
- GraphitCache adapters;
- identity, anonymous IDs, user IDs, sessions, groups, consent, or super properties;
- app lifecycle observation, automatic screen tracking, device metadata, or session events;
- SwiftUI/UIKit/AppKit adapters;
- Observation or `ObservableObject` stores;
- property wrappers, macros, dynamic member lookup, global shared analytics, or service locators;
- logging, metrics, signposts, or instrumentation hooks.

Core v1 stays small: explicit event values in, validated immutable values out.
