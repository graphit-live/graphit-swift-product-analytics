import Foundation

/// A validated immutable product analytics event value.
///
/// An event contains an app-defined name, an explicit occurrence time, and validated
/// event properties. The core package only describes the event value; it does not
/// send, queue, persist, or enrich events.
public struct ProductAnalyticsEvent: Hashable, Codable, Sendable {
    /// The app-defined product analytics event name.
    public let name: ProductAnalyticsEventName

    /// The explicit time at which the event occurred.
    ///
    /// The core package does not read the clock or default this value for callers.
    public let occurredAt: Date

    /// The validated event properties associated with the event.
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
        try self.init(
            name: name,
            occurredAt: occurredAt,
            properties: ProductAnalyticsProperties(properties)
        )
    }
}
