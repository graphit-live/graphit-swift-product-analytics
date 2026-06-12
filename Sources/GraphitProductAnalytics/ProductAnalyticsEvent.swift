import Foundation

/// A validated immutable product analytics event value.
///
/// An event contains an app-defined name, an explicit occurrence time, and validated
/// event properties. Event construction and decoding validate the event name and
/// occurrence time. The Codable representation is an object with `name`, `occurredAt`,
/// and `properties` fields, using the encoder or decoder's normal `Date` strategy.
///
/// The core package only describes the event value; it does not read the clock, send,
/// queue, persist, enrich, identify users, start sessions, or observe app lifecycle.
public struct ProductAnalyticsEvent: Hashable, Codable, Sendable {
    /// The app-defined product analytics event name.
    ///
    /// Event names are schema identifiers. Avoid secrets, tokens, raw private
    /// identifiers, or sensitive user data in this value.
    public let name: ProductAnalyticsEventName

    /// The explicit time at which the event occurred.
    ///
    /// The core package does not read the clock or default this value for callers.
    public let occurredAt: Date

    /// The validated event properties associated with the event.
    ///
    /// The core package stores these properties as an immutable value only. It does
    /// not redact, persist, send, or attach provider-specific metadata.
    public let properties: ProductAnalyticsProperties

    /// Creates a product analytics event from a name, explicit occurrence time, and properties.
    ///
    /// - Parameters:
    ///   - name: The app-defined event name.
    ///   - occurredAt: The explicit time at which the event occurred.
    ///   - properties: Validated analytics properties for the event.
    /// - Throws: `ProductAnalyticsError.invalidEvent` when the event name or occurrence
    ///   time is invalid.
    public init(
        name: ProductAnalyticsEventName,
        occurredAt: Date,
        properties: ProductAnalyticsProperties = .empty
    ) throws {
        try ProductAnalyticsValidation.validateEventName(name)
        try ProductAnalyticsValidation.validateFiniteOccurrenceDate(occurredAt)

        self.name = name
        self.occurredAt = occurredAt
        self.properties = properties
    }

    /// Creates a product analytics event from dictionary-backed property values.
    ///
    /// - Parameters:
    ///   - name: The app-defined event name.
    ///   - occurredAt: The explicit time at which the event occurred.
    ///   - properties: App-defined property values to validate and attach to the event.
    /// - Throws: `ProductAnalyticsError.invalidEvent` when the event name or occurrence
    ///   time is invalid, or `ProductAnalyticsError.invalidProperties` when a property
    ///   key or value is invalid.
    public init(
        name: ProductAnalyticsEventName,
        occurredAt: Date,
        properties: [ProductAnalyticsPropertyKey: ProductAnalyticsPropertyValue]
    ) throws {
        try ProductAnalyticsValidation.validateEventName(name)
        try ProductAnalyticsValidation.validateFiniteOccurrenceDate(occurredAt)

        self.name = name
        self.occurredAt = occurredAt
        self.properties = try ProductAnalyticsProperties(properties)
    }

    /// Decodes an event from an object containing `name`, `occurredAt`, and `properties`.
    ///
    /// Decoding validates the event name, occurrence time, and decoded properties before
    /// returning an event value.
    ///
    /// - Parameter decoder: The decoder providing the object-shaped event representation.
    /// - Throws: `ProductAnalyticsError.invalidEvent` when the decoded event name or occurrence
    ///   time is invalid, `ProductAnalyticsError.invalidProperties` when decoded properties are
    ///   invalid, or `DecodingError` for structural decoding failures.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let name = try container.decode(ProductAnalyticsEventName.self, forKey: .name)
        let occurredAt = try container.decode(Date.self, forKey: .occurredAt)

        try ProductAnalyticsValidation.validateEventName(name)
        try ProductAnalyticsValidation.validateFiniteOccurrenceDate(occurredAt)

        self.name = name
        self.occurredAt = occurredAt
        self.properties = try container.decode(ProductAnalyticsProperties.self, forKey: .properties)
    }

    /// Encodes the event as an object containing `name`, `occurredAt`, and `properties`.
    ///
    /// The occurrence time uses the encoder's normal `Date` strategy. Encoding does not
    /// send, queue, persist, or otherwise deliver the event.
    ///
    /// - Parameter encoder: The encoder that receives the object-shaped event representation.
    /// - Throws: `ProductAnalyticsError.invalidEvent` if this event violates event validation
    ///   rules, or `ProductAnalyticsError.invalidProperties` if its properties violate property
    ///   validation rules.
    public func encode(to encoder: any Encoder) throws {
        try ProductAnalyticsValidation.validateEventName(name)
        try ProductAnalyticsValidation.validateFiniteOccurrenceDate(occurredAt)

        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(occurredAt, forKey: .occurredAt)
        try container.encode(properties, forKey: .properties)
    }
}

private enum CodingKeys: String, CodingKey {
    case name
    case occurredAt
    case properties
}
