/// The app-defined identity for one product analytics event type.
///
/// Use `ProductAnalyticsEventName` instead of a raw string at API boundaries so
/// event names cannot be accidentally mixed with property keys or unrelated text.
/// Construction and standalone decoding do not validate the raw value; event
/// construction validates event names before an event is accepted.
public struct ProductAnalyticsEventName: RawRepresentable, Hashable, Codable, Sendable, CustomStringConvertible {
    /// The underlying app-defined event name.
    public let rawValue: String

    /// Creates an event name from an app-defined raw value without validation.
    ///
    /// - Parameter rawValue: The event name exactly as provided by the caller.
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    /// Creates an event name from an app-defined raw value without validation.
    ///
    /// - Parameter rawValue: The event name exactly as provided by the caller.
    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// Decodes an event name from a single string without semantic validation.
    ///
    /// Event construction validates event names before accepting an event.
    ///
    /// - Parameter decoder: The decoder providing the single-string event name representation.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.rawValue = try container.decode(String.self)
    }

    /// Encodes the event name as a single string.
    ///
    /// - Parameter encoder: The encoder that receives the single-string event name representation.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    /// The app-defined event name text.
    public var description: String {
        rawValue
    }
}

/// The app-defined identity for one product analytics event property.
///
/// Use `ProductAnalyticsPropertyKey` instead of a raw string at API boundaries so
/// property keys cannot be accidentally mixed with event names or unrelated text.
/// Construction and standalone decoding do not validate the raw value; properties
/// construction validates keys before properties are accepted.
public struct ProductAnalyticsPropertyKey: RawRepresentable, Hashable, Codable, Sendable, CustomStringConvertible {
    /// The underlying app-defined property key.
    public let rawValue: String

    /// Creates a property key from an app-defined raw value without validation.
    ///
    /// - Parameter rawValue: The property key exactly as provided by the caller.
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    /// Creates a property key from an app-defined raw value without validation.
    ///
    /// - Parameter rawValue: The property key exactly as provided by the caller.
    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// Decodes a property key from a single string without semantic validation.
    ///
    /// Properties construction validates keys before accepting a property collection.
    ///
    /// - Parameter decoder: The decoder providing the single-string property key representation.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.rawValue = try container.decode(String.self)
    }

    /// Encodes the property key as a single string.
    ///
    /// - Parameter encoder: The encoder that receives the single-string property key representation.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    /// The app-defined property key text.
    public var description: String {
        rawValue
    }
}
