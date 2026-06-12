# Public API contract

All public declarations require documentation comments. Public values are `Sendable` where specified. Do not add public symbols outside this contract without explicit alignment.

## `ProductAnalyticsEventName`

```swift
public struct ProductAnalyticsEventName: RawRepresentable, Hashable, Codable, Sendable, CustomStringConvertible {
    public let rawValue: String

    public init(_ rawValue: String)
    public init(rawValue: String)

    public var description: String { get }
}
```

Rules:

- Dedicated event-name type prevents raw-string mixups at call sites.
- No `ExpressibleByStringLiteral` in v1.
- Construction and decoding are nonvalidating.
- Semantic validation happens when constructing or decoding `ProductAnalyticsEvent`.
- Codable shape is a single JSON string, not `{ "rawValue": ... }`.
- `description` returns the raw value.

Validation when used in an event:

- non-empty;
- no Unicode control scalars;
- length <= 256 characters by `String.count`.

## `ProductAnalyticsPropertyKey`

```swift
public struct ProductAnalyticsPropertyKey: RawRepresentable, Hashable, Codable, Sendable, CustomStringConvertible {
    public let rawValue: String

    public init(_ rawValue: String)
    public init(rawValue: String)

    public var description: String { get }
}
```

Rules:

- Dedicated property-key type prevents raw-string mixups at call sites.
- No `ExpressibleByStringLiteral` in v1.
- Construction and decoding are nonvalidating.
- Semantic validation happens when constructing or decoding `ProductAnalyticsProperties`.
- Codable shape is a single JSON string.
- `description` returns the raw value.

Validation when used in properties:

- non-empty;
- no Unicode control scalars;
- length <= 256 characters by `String.count`.

## `ProductAnalyticsPropertyValue`

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

- Represents a provider-neutral JSON-shaped property value.
- Enum case construction is nonvalidating.
- Encoding and decoding validate the value as a root property value.
- JSON string values stay strings; JSON numbers stay numbers. No string/number coercion.
- Numbers must be finite when validated.
- Strings must be <= 8,192 characters.
- Arrays must contain <= 100 elements.
- Objects must contain <= 100 properties.
- Nested arrays/objects must not exceed depth 8 from the root property value.

## `ProductAnalyticsProperties`

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
- Empty properties are valid.
- Construction validates property keys and the full property tree.
- Property order is not semantic.
- Encoding uses a JSON object keyed by each `ProductAnalyticsPropertyKey.rawValue`.
- Decoding validates semantic rules.
- Duplicate object keys in raw JSON are not a supported public semantic.

## `ProductAnalyticsEvent`

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
- Construction validates event name and finite occurrence time.
- Dictionary convenience initializer also validates properties.
- `occurredAt` is explicit; core does not read the clock.
- Core does not reject old or future timestamps.
- Codable shape is an object with `name`, `occurredAt`, and `properties` fields.
- `occurredAt` uses the encoder/decoder's normal `Date` strategy.

## `ProductAnalyticsBatch`

```swift
public struct ProductAnalyticsBatch: Hashable, Codable, Sendable {
    public let events: [ProductAnalyticsEvent]

    public init(_ events: [ProductAnalyticsEvent]) throws
    public init(_ event: ProductAnalyticsEvent)
}
```

Rules:

- Represents an ordered immutable batch of events.
- A batch must contain at least one event and no more than 1,000 events.
- Event order is preserved.
- Core does not deduplicate, merge, split, persist, queue, or deliver batches.
- Codable shape is an object with an `events` array.
- Decoding validates batch count.

## `ProductAnalyticsError`

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
- Does not model filesystem, network, cache, provider, or vendor failures.
- Associated messages must be useful but sanitized.
- Public descriptions may mention event names and property keys when useful, but must not include raw property values.
