# GraphitProductAnalytics Swift SDK — Minimal V1 Product and Engineering Specification

**Version:** Draft 4 minimal event vocabulary v1  
**Date:** 2026-06-12  
**Primary goal:** a tiny, reliable, provider-agnostic product analytics event vocabulary for Swift apps and SDKs.  
**Core rule:** GraphitProductAnalytics describes validated product analytics events and batches. It does not send events, queue events, flush events, identify users, track sessions, observe app lifecycle, or integrate with vendors in v1.

---

## 1. Product summary

GraphitProductAnalytics v1 is a **provider-neutral event value layer**.

It supports only:

- strongly typed event names;
- strongly typed property keys;
- JSON-shaped property values;
- validated immutable event properties;
- validated immutable product analytics events;
- ordered validated batches;
- compact `Codable` values for app-owned queues, files, caches, provider packages, or tests.

It intentionally does **not** include sender APIs, recorder APIs, provider protocols, PostHog integration, Google Analytics integration, network transport, batching queues, retry/backoff, persistence, offline storage, flush scheduling, identity state, anonymous IDs, user IDs, sessions, super properties, automatic screen tracking, app lifecycle hooks, UI adapters, property wrappers, macros, dynamic member lookup, task-local dependency lookup, service locators, or process-wide singletons in v1.

The v1 public SDK is exactly these seven core types:

- `ProductAnalyticsEventName`;
- `ProductAnalyticsPropertyKey`;
- `ProductAnalyticsPropertyValue`;
- `ProductAnalyticsProperties`;
- `ProductAnalyticsEvent`;
- `ProductAnalyticsBatch`;
- `ProductAnalyticsError`.

Do not add extra public types unless the v1 contract is explicitly re-reviewed.

The app-facing usage should be boring and explicit:

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

let event = try ProductAnalyticsEvent(
    name: AppAnalytics.Events.signupCompleted,
    occurredAt: Date.now,
    properties: [
        AppAnalytics.Properties.plan: .string("pro"),
        AppAnalytics.Properties.source: .string("paywall")
    ]
)
```

Provider packages can be added later by depending on this core package and accepting `ProductAnalyticsEvent` or `ProductAnalyticsBatch` values through concrete package-owned APIs:

```swift
let client = try PostHogProductAnalyticsClient(configuration: configuration)
try await client.capture(event, context: context)
```

A provider that buffers events should make that behavior explicit:

```swift
try await queue.enqueue(event, context: context) // accepted by the queue
try await queue.flush()                         // attempted delivery
```

The dependency direction is one-way:

```text
GraphitProductAnalytics                 // pure core values and validation
GraphitProductAnalyticsPostHog          // depends on GraphitProductAnalytics later
GraphitProductAnalyticsGoogleAnalytics  // possible external/provider package later
App                                     // owns state, queueing, cache, lifecycle, privacy, UI
```

A shared provider protocol should wait until real provider packages prove the common shape.

---

## 2. Platform and toolchain

- Swift 6.3.x.
- Swift language mode 6.
- SwiftPM source package.
- Official v1 product focus: iOS 18+.
- Package also supports macOS 15+ for SwiftPM builds/tests and Mac app use.
- No Linux support claim in v1 unless the repository later adds Linux CI.
- No third-party Swift dependencies.
- Core target may import Foundation for `Date`.
- No GraphitCache dependency in v1.
- No URLSession, networking, SQLite, file-system, OSLog, SwiftUI, UIKit, AppKit, Combine, Observation, or vendor SDK imports in core v1.

GraphitProductAnalytics values are `Codable` so apps or provider packages can queue, persist, or cache them using GraphitCache, files, databases, `UserDefaults`, provider-owned offline stores, or another app-owned mechanism. The core package does not choose storage, TTL, retry, or privacy policy.

---

## 3. Locked v1 decisions

### 3.1 Event vocabulary, not analytics platform

V1 describes product analytics events. It is not an analytics client, delivery engine, queue, session tracker, user identity store, or vendor adapter.

### 3.2 No sending in core

No `record`, `capture`, `track`, `send`, `enqueue`, `flush`, `drain`, or `shutdown` API exists in core v1.

Reason: delivery semantics differ by provider and by app policy:

- direct network delivery waits for a backend response;
- buffered recording may only mean local queue acceptance;
- offline queues need persistence, retention, retry, deduplication, and privacy policy;
- some providers batch by event count, some by byte size, some by time, and some by app lifecycle.

Core values stay useful for all of these shapes without pretending they have one universal execution model.

### 3.3 No provider protocol in core

No `ProductAnalyticsRecorder`, `ProductAnalyticsProvider`, `AnalyticsClient`, `AnalyticsSink`, or similar public protocol exists in v1.

A protocol can be introduced later only after multiple concrete providers prove the shared shape. For the first provider, a concrete package-owned client is clearer and avoids forcing Google Analytics, PostHog, Amplitude, Segment, Mixpanel, and custom backends into the wrong abstraction.

### 3.4 No identity model in core

No `UserID`, `AnonymousID`, `DistinctID`, `DeviceID`, `SessionID`, `GroupID`, or `AccountID` exists in core v1.

Identity is not universal:

- PostHog uses `distinct_id` and optional groups;
- Google Analytics has client/user/app-instance concepts;
- Amplitude separates user and device identity;
- Segment has `userId` and `anonymousId`;
- some apps intentionally avoid user identity.

Provider packages own provider-specific context. Apps may also include identity-like data as normal event properties when their privacy policy allows it, but the core package does not reserve or interpret any property key.

### 3.5 No sessions, screen tracking, or lifecycle hooks

Core v1 does not start sessions, end sessions, infer screen views, observe app foreground/background state, or automatically attach device/app metadata.

These policies are app/provider concerns because they affect privacy, event volume, lifecycle behavior, background work, and vendor-specific semantics.

### 3.6 Batches are values only

`ProductAnalyticsBatch` is an ordered immutable collection of already-created events. It does not own a queue, buffer, timer, retry policy, transport, file, task, or flush lifecycle.

Provider packages and apps can use batches as an explicit value when they decide to send or persist multiple events together.

### 3.7 No global or ambient analytics

No `ProductAnalytics.shared`, process-wide mutable configuration, service locator, environment lookup, task-local dependency, property wrapper, macro, or dynamic member lookup exists in v1.

Call sites should pass event values to explicit app/provider-owned objects.

### 3.8 Provider-neutral property model

Core properties are JSON-shaped values: null, booleans, numbers, strings, arrays, and objects.

Core does not include provider-specific reserved keys, `$`-prefixed conventions, revenue helpers, ecommerce schemas, attribution models, campaign fields, screen-name helpers, or typed SDK-specific payloads.

### 3.9 Validation without normalization

Core validates obvious structural issues but does not rewrite caller data.

It does not trim whitespace, lowercase names, convert spaces to underscores, rename reserved keys, flatten nested objects, coerce strings to numbers, coerce numbers to strings, drop nulls, or remove unsupported properties. Provider packages may apply provider-specific mapping rules later.

### 3.10 Similar taste to GraphitFeatureFlags

This SDK should be closer in complexity to GraphitFeatureFlags than GraphitCache. It should share the family posture: dedicated value types, explicit boundaries, small public surface, deterministic validation, no speculative abstractions.

It should not copy GraphitCache's storage architecture. There is no actor, lock, SQLite index, background task, file lease, cleanup engine, or transport required for core v1.

### 3.11 Validation boundaries are intentional

Construction of leaf values remains cheap and nonvalidating, matching GraphitFeatureFlags' preference for simple schema constants and explicit aggregate validation. However, analytics property values are recursive JSON-shaped payloads and can represent states that are invalid for persistence or interchange, such as non-finite numbers, over-wide arrays, over-deep objects, or over-long strings.

For that reason, standalone `ProductAnalyticsPropertyValue` encoding and decoding are validation boundaries in v1. This is intentional and is not considered extra framework machinery. It prevents invalid analytics payloads from being silently persisted or exchanged when callers use the public property-value type directly.

The family consistency target is the engineering posture, not byte-for-byte behavior with GraphitFeatureFlags: validate when a value crosses a meaningful boundary, keep validation deterministic, and avoid adding abstractions that do not protect an invariant.

---

## 4. Concept model

### 4.1 Event name

`ProductAnalyticsEventName` is the app-defined identity for one product analytics event type.

Use dedicated event names instead of raw strings so call sites do not accidentally pass a property key or unrelated string where an event name is expected.

```swift
enum AppAnalytics {
    enum Events {
        static let signupStarted = ProductAnalyticsEventName("signup_started")
        static let signupCompleted = ProductAnalyticsEventName("signup_completed")
        static let subscriptionPurchased = ProductAnalyticsEventName("subscription_purchased")
    }
}
```

No `ExpressibleByStringLiteral` in v1. This encourages schema constants instead of scattered magic strings.

### 4.2 Property key

`ProductAnalyticsPropertyKey` is the app-defined identity for one event property.

```swift
enum AppAnalytics {
    enum Properties {
        static let source = ProductAnalyticsPropertyKey("source")
        static let plan = ProductAnalyticsPropertyKey("plan")
        static let amount = ProductAnalyticsPropertyKey("amount")
        static let currency = ProductAnalyticsPropertyKey("currency")
    }
}
```

Core does not reserve keys and does not assign semantics to names such as `user_id`, `anonymous_id`, `session_id`, `screen`, `revenue`, or `distinct_id`.

### 4.3 Property value

`ProductAnalyticsPropertyValue` is a JSON-shaped value:

- `null`;
- Boolean;
- finite number;
- string;
- array of property values;
- object of analytics properties.

This is intentionally not `[String: Any]`. The value model is typed, `Sendable`, `Codable`, and explicit enough for providers to map without runtime type guessing. Strings are never parsed into numbers, and numbers are never converted into strings; callers choose the semantic type explicitly.

### 4.4 Properties

`ProductAnalyticsProperties` is an immutable dictionary-like value keyed by `ProductAnalyticsPropertyKey`.

It validates property keys and values when constructed or decoded. Property order is not semantic.

Empty properties are valid.

### 4.5 Event

`ProductAnalyticsEvent` is the validated immutable product analytics event value:

- event name;
- occurrence time;
- properties.

The occurrence time is explicit. Core v1 does not read the clock for the caller. Apps pass `Date.now`, a test-controlled date, a provider-recovered event time, or another app-owned timestamp.

### 4.6 Batch

`ProductAnalyticsBatch` is a non-empty ordered collection of events.

Batch order is preserved. Core does not deduplicate, merge, split, retry, or deliver batches.

---

## 5. Public API surface

All public declarations require documentation comments. Do not add public symbols outside this contract without explicit alignment.

Leaf construction is intentionally nonvalidating so apps can define schema constants and compose values cheaply. Event names and property keys also decode without semantic validation, matching their construction semantics. `ProductAnalyticsPropertyValue` enum case construction is nonvalidating, but its `Codable` implementation validates the encoded or decoded value as a root property value because standalone serialization is a persistence/interchange boundary. Aggregate validation happens when constructing or decoding `ProductAnalyticsProperties`, `ProductAnalyticsEvent`, and `ProductAnalyticsBatch`.

### 5.1 `ProductAnalyticsEventName`

```swift
public struct ProductAnalyticsEventName: RawRepresentable, Hashable, Codable, Sendable, CustomStringConvertible {
    public let rawValue: String

    public init(_ rawValue: String)
    public init(rawValue: String)

    public var description: String { get }
}
```

Rules:

- Represents one app-defined product analytics event name.
- Construction and decoding are nonvalidating.
- Event construction validates event names.
- Codable shape is a single string.
- `description` returns the raw value because event names are app schema, not provider credentials.
- Do not put secrets, tokens, raw private identifiers, or sensitive user data in event names.

Validation rules:

- non-empty;
- no Unicode control scalars;
- no longer than 256 characters, measured by Swift `String.count`.

No normalization is performed.

### 5.2 `ProductAnalyticsPropertyKey`

```swift
public struct ProductAnalyticsPropertyKey: RawRepresentable, Hashable, Codable, Sendable, CustomStringConvertible {
    public let rawValue: String

    public init(_ rawValue: String)
    public init(rawValue: String)

    public var description: String { get }
}
```

Rules:

- Represents one app-defined product analytics property key.
- Construction and decoding are nonvalidating.
- Properties construction validates keys.
- Codable shape is a single string.
- `description` returns the raw value because property keys are app schema, not provider credentials.
- Do not put secrets, tokens, raw private identifiers, or sensitive user data in property keys.

Validation rules:

- non-empty;
- no Unicode control scalars;
- no longer than 256 characters, measured by Swift `String.count`.

No normalization is performed. Provider packages may reject or map keys that their backend cannot accept.

### 5.3 `ProductAnalyticsPropertyValue`

```swift
public indirect enum ProductAnalyticsPropertyValue: Hashable, Codable, Sendable {
    case null
    case bool(Bool)
    case number(Double)
    case string(String)
    case array([ProductAnalyticsPropertyValue])
    case object(ProductAnalyticsProperties)
}
```

Rules:

- Represents a provider-neutral analytics property value.
- Construction through enum cases is nonvalidating.
- Encoding and decoding validate the value as a root property value.
- This standalone `Codable` validation is intentional even though text identifier construction/decoding is nonvalidating; property values can contain invalid JSON-boundary states that should not be silently persisted or exchanged.
- `ProductAnalyticsProperties` validates values recursively when values are used inside properties.
- Codable shape is JSON-shaped:
  - `.null` encodes as JSON `null`;
  - `.bool` encodes as JSON Boolean;
  - `.number` encodes as JSON number and must be finite when validated;
  - `.string` encodes as JSON string;
  - `.array` encodes as JSON array;
  - `.object` encodes as JSON object.
- JSON decoding is type-preserving and non-coercing:
  - JSON numbers decode as `.number(Double)` when finite and representable;
  - JSON strings decode as `.string(String)`, even when the contents look numeric or match non-conforming float tokens such as `"NaN"`, `"Infinity"`, or `"-Infinity"`;
  - reject non-finite or nonrepresentable numeric values.

Validation rules:

- numbers must be finite `Double` values; reject NaN and infinities;
- numbers use Swift `Double` precision; callers that need exact decimal text, arbitrary-precision numbers, or large integer identifiers should use `.string(...)`;
- strings must be no longer than 8,192 characters, measured by Swift `String.count`;
- arrays must contain no more than 100 elements;
- objects must contain no more than 100 properties;
- nested arrays/objects must not exceed depth 8 from the root property value.

String property values may contain ordinary user-visible text. Core does not trim, redact, normalize, or inspect them for privacy. Public error descriptions must not include raw property values.

Provider packages may impose stricter limits or support fewer shapes. For example, a provider that only accepts scalar event parameters can reject arrays or objects with a provider-owned error.

### 5.4 `ProductAnalyticsProperties`

```swift
public struct ProductAnalyticsProperties: Hashable, Codable, Sendable {
    public static let empty: ProductAnalyticsProperties

    public let values: [ProductAnalyticsPropertyKey: ProductAnalyticsPropertyValue]

    public init(_ values: [ProductAnalyticsPropertyKey: ProductAnalyticsPropertyValue] = [:]) throws

    public subscript(_ key: ProductAnalyticsPropertyKey) -> ProductAnalyticsPropertyValue? { get }
}
```

Rules:

- Represents validated immutable event properties.
- Construction validates keys, values, object width, array width, string length, number finiteness, and nesting depth.
- Empty properties are valid.
- Property order is not semantic.
- Encoding uses a JSON object keyed by each `ProductAnalyticsPropertyKey.rawValue`.
- Decoding validates semantic rules and throws for invalid properties.
- Duplicate object keys in raw JSON are not a supported semantic. JSON decoder behavior for duplicate object members is not part of the public contract.

Examples:

```swift
let properties = try ProductAnalyticsProperties([
    AppAnalytics.Properties.plan: .string("pro"),
    AppAnalytics.Properties.amount: .number(19.99),
    AppAnalytics.Properties.currency: .string("USD")
])
```

Most event call sites should use `ProductAnalyticsEvent`'s dictionary convenience initializer instead of constructing `ProductAnalyticsProperties` separately.

### 5.5 `ProductAnalyticsEvent`

```swift
public struct ProductAnalyticsEvent: Hashable, Codable, Sendable {
    public let name: ProductAnalyticsEventName
    public let occurredAt: Date
    public let properties: ProductAnalyticsProperties

    public init(
        name: ProductAnalyticsEventName,
        occurredAt: Date,
        properties: ProductAnalyticsProperties = .empty
    ) throws

    public init(
        name: ProductAnalyticsEventName,
        occurredAt: Date,
        properties: [ProductAnalyticsPropertyKey: ProductAnalyticsPropertyValue]
    ) throws
}
```

Rules:

- Represents one validated product analytics event.
- Construction validates event name and occurrence time.
- The dictionary convenience initializer also validates properties.
- `occurredAt` is explicit. Core does not default it to `Date.now` because tests, queues, retries, and offline delivery need the original event time.
- `occurredAt` must have a finite `timeIntervalSinceReferenceDate`.
- Core does not reject old or future timestamps. Provider packages may apply provider-specific timestamp policy.
- Codable shape is an object with `name`, `occurredAt`, and `properties` fields.
- `occurredAt` is encoded and decoded using the encoder/decoder's normal `Date` strategy. Core does not define a provider wire timestamp format.
- Decoding validates semantic rules.

Example:

```swift
let event = try ProductAnalyticsEvent(
    name: AppAnalytics.Events.subscriptionPurchased,
    occurredAt: Date.now,
    properties: [
        AppAnalytics.Properties.plan: .string("annual"),
        AppAnalytics.Properties.amount: .number(99.99),
        AppAnalytics.Properties.currency: .string("USD")
    ]
)
```

### 5.6 `ProductAnalyticsBatch`

```swift
public struct ProductAnalyticsBatch: Hashable, Codable, Sendable {
    public let events: [ProductAnalyticsEvent]

    public init(_ events: [ProductAnalyticsEvent]) throws
    public init(_ event: ProductAnalyticsEvent)
}
```

Rules:

- Represents an ordered immutable batch of events.
- A batch must contain at least one event.
- A batch must contain no more than 1,000 events in v1.
- Event order is preserved.
- Core does not deduplicate events.
- Core does not split large batches. Provider packages may split batches according to backend request limits.
- Codable shape is an object with an `events` array.
- Decoding validates batch count.

Examples:

```swift
let batch = try ProductAnalyticsBatch([eventA, eventB, eventC])
```

```swift
let singleEventBatch = ProductAnalyticsBatch(event)
```

### 5.7 `ProductAnalyticsError`

```swift
public enum ProductAnalyticsError: Error, Sendable, Hashable, CustomStringConvertible {
    case invalidEvent(String)
    case invalidProperties(String)
    case invalidBatch(String)

    public var description: String { get }
}
```

Rules:

- Used for package-owned validation failures.
- `invalidEvent` is thrown for invalid event names or occurrence times.
- `invalidProperties` is thrown for invalid property keys, values, widths, string lengths, number finiteness, or nesting depth.
- `invalidBatch` is thrown for empty or too-large batches.
- Associated messages must be useful but sanitized.
- Error descriptions may mention event names and property keys when useful, but must not include raw property values.
- No filesystem, network, transport, cache, provider, or vendor errors exist in core v1.

---

## 6. Required behavior

### 6.1 Text validation

Event names and property keys reject:

- empty strings;
- Unicode control scalars, including NUL;
- strings longer than 256 characters, measured by Swift `String.count`.

Control scalars include C0 controls, DEL, and C1 controls:

```text
scalar.value <= 0x1F || scalar.value == 0x7F || (0x80...0x9F).contains(scalar.value)
```

No trimming, normalization, lowercasing, Unicode normalization, or provider-specific character filtering is performed.

### 6.2 Property validation

`ProductAnalyticsProperties.init` validates the whole property tree.

Limits:

| Rule | Limit |
| --- | ---: |
| properties per object | 100 |
| array elements per array | 100 |
| string value length (`String.count`) | 8,192 characters |
| nested array/object depth | 8 |

Depth counting starts at each root property value being validated. The top-level `ProductAnalyticsProperties` container itself does not add depth. A scalar has depth 0. Each array or object layer inside a value increments depth by 1. For direct `ProductAnalyticsPropertyValue` serialization, treat the encoded or decoded value as the root property value.

Depth examples:

```swift
.string("x")                       // depth 0
.array([.string("x")])             // depth 1
.object(.empty)                     // depth 1 when used as a property value
```

Eight nested array/object layers from a root property value are valid. Nine nested array/object layers are invalid. A top-level `ProductAnalyticsProperties` container does not add one extra depth level to the values it contains.

Numeric rules:

- `.number` accepts only finite `Double` values;
- NaN, positive infinity, and negative infinity are invalid;
- numbers use Swift `Double` precision, not arbitrary-precision decimal or integer semantics.

Privacy rules:

- core never logs property values;
- public validation errors must not include raw property values;
- apps and providers own privacy decisions about which values are collected, persisted, or sent.

### 6.3 Event validation

`ProductAnalyticsEvent.init` validates:

- valid event name;
- finite `occurredAt` date;
- valid properties when the dictionary initializer is used.

An event with empty properties is valid.

The initializer does not perform I/O, spawn tasks, read clocks, use global state, log, contact providers, or consult app lifecycle.

### 6.4 Batch validation

`ProductAnalyticsBatch.init(_:)` validates:

- at least one event;
- no more than 1,000 events.

A batch initializer does not merge, sort, deduplicate, split, persist, or send events.

### 6.5 Codable behavior

Core values are `Codable` for app/provider composition. The documented storage and interchange shape is JSON-oriented; `JSONEncoder` and `JSONDecoder` are the canonical encoders for v1 examples and tests. Other `Codable` encoders/decoders are outside the public representation contract unless they preserve the same semantic shapes.

`ProductAnalyticsEventName` and `ProductAnalyticsPropertyKey` encode as single strings:

```json
"signup_completed"
```

`ProductAnalyticsPropertyValue` encodes as JSON-shaped data:

```json
{
  "plan": "pro",
  "amount": 19.99,
  "is_trial": false,
  "coupon": null,
  "items": ["seat", "storage"],
  "metadata": {
    "source": "paywall"
  }
}
```

`ProductAnalyticsEvent` encodes as:

```json
{
  "name": "signup_completed",
  "occurredAt": "encoder-defined Date representation",
  "properties": {
    "plan": "pro",
    "source": "paywall"
  }
}
```

`occurredAt` intentionally uses the encoder/decoder's `Date` strategy. Provider packages should map `Date` into their backend's required timestamp format at the transport boundary.

`ProductAnalyticsBatch` encodes as:

```json
{
  "events": [
    {
      "name": "signup_completed",
      "occurredAt": "encoder-defined Date representation",
      "properties": {}
    }
  ]
}
```

Decoding validates semantic rules for property values, properties, events, and batches. Standalone event names and property keys decode without semantic validation, matching their construction semantics. Standalone property value encoding and decoding support the JSON-shaped representation and validate the standalone value as a root property value because serialization is a persistence/interchange boundary. `ProductAnalyticsProperties` still performs the same recursive validation for values used in event properties.

Property value decoding must not coerce between strings and numbers. JSON `"123"`, `"19.99"`, `"NaN"`, `"Infinity"`, and `"-Infinity"` decode as `.string(...)`. JSON `123` and `19.99` decode as `.number(...)`. Callers that need opaque identifiers, exact decimal text, phone numbers, ZIP/postal codes, or formatted values should use `.string(...)`, not `.number(...)`.

Semantic validation failures thrown by package-owned decoding should use `ProductAnalyticsError.invalidProperties`, `ProductAnalyticsError.invalidEvent`, or `ProductAnalyticsError.invalidBatch` as appropriate. Structural decoding failures, such as a wrong top-level shape or type mismatch, may remain `DecodingError`. Encoding a nonvalidating constructed `ProductAnalyticsPropertyValue` with invalid content should throw `ProductAnalyticsError.invalidProperties`.

### 6.6 Concurrency and cancellation

All public values are `Sendable`.

Core v1 has no async API, actor, lock, task, stream, continuation, transport, queue, or cancellation behavior.

Provider packages that perform async work must document and test their own cancellation semantics.

---

## 7. Provider composition guidance

### 7.1 Direct network provider

A direct provider should expose delivery semantics clearly:

```swift
try await postHog.capture(event, context: context)
try await postHog.capture(batch, context: context)
```

For a direct network provider, `capture` should mean that the provider attempted delivery and received/processed the backend response according to that provider's contract.

### 7.2 Buffered provider or queue

A buffered provider should not hide delivery behind a vague method name.

Prefer explicit ownership and lifecycle:

```swift
let queue = PostHogProductAnalyticsQueue(client: client, storage: storage, policy: policy)

try await queue.enqueue(event, context: context)
try await queue.flush()
```

Rules for a future queue package:

- queue owner is explicit;
- accepted-vs-delivered semantics are documented;
- flush is explicit unless a separate lifecycle policy is intentionally designed;
- task ownership and cancellation are explicit;
- storage bounds are explicit;
- retry/backoff policy is explicit;
- privacy and redaction are documented;
- no hidden singleton queue.

This is not core v1.

### 7.3 Identity and context

Provider packages own context values:

```swift
let context = PostHogProductAnalyticsContext(
    distinctID: PostHogDistinctID("user-123")
)

try await postHog.capture(event, context: context)
```

Core event properties remain provider-neutral. A provider package may later offer explicit mapping options, but hidden conventions should be avoided:

```swift
// Possible future provider-owned configuration, not core v1.
PostHogProductAnalyticsMapping(
    distinctID: .property(AppAnalytics.Properties.userID)
)
```

### 7.4 App-owned and provider-owned queues

Most production apps should avoid one network request per event. That does not mean the base value SDK should own queueing.

Queueing policy depends on:

- app lifecycle;
- offline behavior;
- flush cadence;
- batch size limits;
- byte-size limits;
- privacy consent;
- user logout behavior;
- background execution policy;
- storage limits;
- retry and backoff;
- provider quota and rate limits;
- whether enqueue success means durable local persistence or only in-memory acceptance.

Core values are queue-friendly and `Codable`. The queue itself belongs in the app or in a concrete provider package.

---

## 8. Internal architecture

V1 internals should be almost boring:

```text
ProductAnalyticsEventName
ProductAnalyticsPropertyKey
ProductAnalyticsPropertyValue
ProductAnalyticsProperties
ProductAnalyticsEvent
ProductAnalyticsBatch
ProductAnalyticsValidation
ProductAnalyticsError
```

Implementation rules:

- keep recursive property validation small, deterministic, and context-aware so nested arrays and objects are checked against the current root-value depth;
- use custom `Codable` where synthesized shapes would weaken validation or expose the wrong representation;
- no actor;
- no lock;
- no task;
- no async API;
- no singleton;
- no provider registry;
- no service locator;
- no generated code;
- no vendor imports;
- no GraphitCache import;
- no network transport;
- no file-system access;
- no UI framework imports;
- no logging by default.

Suggested source tree:

```text
Sources/GraphitProductAnalytics/
  ProductAnalyticsTextValues.swift      // EventName, PropertyKey
  ProductAnalyticsPropertyValue.swift
  ProductAnalyticsProperties.swift
  ProductAnalyticsEvent.swift
  ProductAnalyticsBatch.swift
  ProductAnalyticsError.swift
  ProductAnalyticsValidation.swift

Tests/GraphitProductAnalyticsTests/
  TextValueTests.swift
  PropertyValueCodableTests.swift
  PropertiesValidationTests.swift
  EventValidationTests.swift
  BatchValidationTests.swift
  CodableTests.swift
  READMEExamplesTests.swift
```

The tree is a guide, not a mandate. Prefer fewer files when fewer files are clearer.

Suggested manifest:

```swift
// swift-tools-version: 6.3
import PackageDescription

let package = Package(
    name: "GraphitProductAnalytics",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(name: "GraphitProductAnalytics", targets: ["GraphitProductAnalytics"])
    ],
    targets: [
        .target(
            name: "GraphitProductAnalytics",
            dependencies: [],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "GraphitProductAnalyticsTests",
            dependencies: ["GraphitProductAnalytics"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
```

---

## 9. Testing strategy

Use Swift Testing for v1 behavior tests.

High-signal tests:

1. event name raw value, description, equality, and `Codable` string shape;
2. property key raw value, description, equality, and `Codable` string shape;
3. property value encoding/decoding for null, bool, number, string, array, and object, including root-value validation, rejection of invalid enum-constructed values during encoding, and string-vs-number preservation for values such as `"123"`, `"NaN"`, and `123`;
4. property validation rejects invalid keys;
5. property validation rejects non-finite numbers;
6. property validation rejects too-long string values;
7. property validation rejects too-wide arrays and objects;
8. property validation rejects too-deep nesting;
9. event construction accepts valid name, date, and empty properties;
10. event construction rejects empty, control-scalar, and too-long names;
11. event construction rejects non-finite dates;
12. dictionary convenience initializer validates properties;
13. event `Codable` decoding validates semantic rules;
14. batch construction accepts one or more events and preserves order;
15. batch construction rejects empty and too-large batches;
16. batch `Codable` decoding validates count;
17. public error descriptions are sanitized and do not include raw property values;
18. README examples compile.

Do not add test infrastructure beyond what these tests need. No mock frameworks, fake transports, clocks, temporary directories, public testing products, or network tests are required in core v1.

---

## 10. Documentation requirements

README should include:

- installation;
- platform/toolchain support;
- quick start;
- schema constants for event names and property keys;
- event construction examples;
- batch construction examples;
- note that `occurredAt` is explicit and core does not read the clock;
- `Codable` guidance for app/provider-owned queues;
- provider composition guidance;
- clear statement that core does not send, queue, flush, retry, identify users, track sessions, or observe app lifecycle;
- privacy notes for event names, property keys, and property values;
- deferred features/non-goals.

Public documentation comments must cover:

- purpose;
- validation timing;
- parameters;
- thrown errors;
- `Codable` shape where relevant;
- privacy notes where relevant;
- ownership and non-delivery semantics.

---

## 11. Deferred decisions and non-goals

Do not add placeholder public APIs for these areas in v1.

### 11.1 Providers and transport

Deferred:

- provider protocol;
- PostHog provider;
- Google Analytics provider;
- Amplitude, Segment, Mixpanel, or custom backend providers;
- sender/recorder/client abstractions in core;
- network transport;
- request/response models;
- retry/backoff;
- status-code handling;
- provider error mapping.

Reason: core v1 is the shared value vocabulary. Provider packages should expose concrete APIs and prove common shapes before core defines abstractions.

### 11.2 Queueing, batching policy, and offline delivery

Deferred:

- in-memory queue;
- durable offline queue;
- GraphitCache queue adapter;
- file/database queue;
- flush timers;
- app lifecycle flush;
- background tasks;
- retry/backoff;
- deduplication;
- delivery receipts;
- queue size policy;
- payload byte-size policy;
- compression;
- encryption.

Reason: event accumulation and flushing are real production needs, but their policy belongs in apps or concrete provider packages, not the universal core value package.

### 11.3 Identity and user state

Deferred:

- user ID;
- anonymous ID;
- distinct ID;
- device ID;
- session ID;
- group/account ID;
- identify calls;
- alias calls;
- logout/reset calls;
- super properties;
- persistent user context;
- consent state.

Reason: identity semantics differ across providers and privacy policies. Core does not reserve property keys or own mutable identity.

### 11.4 Automatic collection

Deferred:

- app lifecycle events;
- session start/end;
- screen view tracking;
- crash/error tracking;
- device metadata;
- OS/app version metadata;
- attribution/campaign capture;
- revenue/ecommerce helpers.

Reason: automatic collection has privacy, volume, lifecycle, and provider-specific consequences. V1 remains explicit.

### 11.5 UI and syntax sugar

Deferred:

- SwiftUI/UIKit/AppKit adapters;
- Observation or `ObservableObject` stores;
- property wrappers;
- macros;
- dynamic member lookup;
- global environment values;
- string-literal event names or property keys.

Reason: explicit event values are boring and hard to misuse.

### 11.6 Advanced schema support

Deferred:

- generated event schema APIs;
- macro-generated event/property constants;
- typed event-specific builders;
- typed property schemas;
- compile-time required property checks;
- event catalog documentation generation.

Reason: apps can define simple constants today. Schema generation can be useful later but should not become the main human-facing API by accident.

### 11.7 Observability and logging

Deferred:

- public event sink;
- OSLog adapter;
- metrics hooks;
- signposts;
- debug logging.

Reason: core v1 performs no I/O or async work and should not log property values. Provider packages can add sanitized observability around transport and queue behavior.

---

## 12. Engineering quality bar

- Swift 6 language mode.
- iOS 18+ and macOS 15+ package floor.
- One public product: `GraphitProductAnalytics`.
- No third-party dependencies.
- No GraphitCache dependency in core.
- Core imports Foundation only as needed for `Date`.
- Public APIs are documented.
- Public values are `Sendable`.
- Events and properties are immutable.
- `occurredAt` is explicit; core does not read the clock.
- No hidden global mutable state.
- No service locator.
- No public provider abstraction before real providers prove the common shape.
- No networking, storage, cache, analytics transport, queue, session, identity, or UI imports in core.
- No fire-and-forget work.
- No raw `Any` property values.
- No public API outside this spec without explicit alignment.
- Public v1 surface remains exactly the seven core types listed in the product summary.

GraphitProductAnalytics v1 should be small enough to understand in minutes and stable enough to serve as the common event vocabulary for PostHog, Google Analytics, and other provider integrations later.
