/// A validated immutable collection of product analytics event properties.
///
/// Properties are keyed by `ProductAnalyticsPropertyKey` and contain JSON-shaped
/// `ProductAnalyticsPropertyValue` values. Construction and decoding validate keys,
/// values, object width, array width, string length, number finiteness, and nesting
/// depth. Property order is not semantic.
///
/// The Codable representation is a JSON object keyed by each property key's raw value.
/// The core package does not assign provider-specific meaning to any key and does not
/// send, queue, persist, redact, or log property values.
public struct ProductAnalyticsProperties: Hashable, Codable, Sendable {
    /// A prevalidated empty property collection.
    public static let empty = ProductAnalyticsProperties(unchecked: [:])

    /// The validated property values keyed by app-defined property keys.
    ///
    /// Treat this dictionary as an immutable snapshot. Dictionary iteration order is
    /// not semantic and should not be used as an analytics contract.
    public let values: [ProductAnalyticsPropertyKey: ProductAnalyticsPropertyValue]

    /// Creates analytics properties from app-defined key-value pairs.
    ///
    /// - Parameter values: The property values to include. Empty properties are valid.
    /// - Throws: `ProductAnalyticsError.invalidProperties` when a key or value violates
    ///   the analytics property validation rules.
    public init(_ values: [ProductAnalyticsPropertyKey: ProductAnalyticsPropertyValue] = [:]) throws {
        try ProductAnalyticsValidation.validateProperties(values)
        self.values = values
    }

    private init(unchecked values: [ProductAnalyticsPropertyKey: ProductAnalyticsPropertyValue]) {
        self.values = values
    }

    /// Decodes properties from a JSON object keyed by property-key raw values.
    ///
    /// Decoding validates property keys and values before returning a property collection.
    ///
    /// - Parameter decoder: The decoder providing the object-shaped properties representation.
    /// - Throws: `ProductAnalyticsError.invalidProperties` when decoded properties violate
    ///   semantic limits, or `DecodingError` for structural decoding failures.
    public init(from decoder: any Decoder) throws {
        let decoded = try Self.decodeUnchecked(from: decoder)
        try ProductAnalyticsValidation.validateProperties(decoded.values)
        self = decoded
    }

    /// Encodes properties as a JSON object keyed by each property key's raw value.
    ///
    /// - Parameter encoder: The encoder that receives the object-shaped properties representation.
    /// - Throws: `ProductAnalyticsError.invalidProperties` if an internally constructed value
    ///   violates property validation rules.
    public func encode(to encoder: any Encoder) throws {
        try ProductAnalyticsValidation.validateProperties(values)
        try encodeUnchecked(to: encoder)
    }

    /// Returns the value for the supplied property key, if one is present.
    ///
    /// Lookup is synchronous and reads only this immutable value; it performs no I/O,
    /// logging, provider mapping, or normalization.
    ///
    /// - Parameter key: The app-defined property key to look up.
    public subscript(_ key: ProductAnalyticsPropertyKey) -> ProductAnalyticsPropertyValue? {
        values[key]
    }
}

extension ProductAnalyticsProperties {
    static func decodeUnchecked(from decoder: any Decoder) throws -> ProductAnalyticsProperties {
        let container = try decoder.container(keyedBy: ProductAnalyticsPropertyCodingKey.self)
        var values: [ProductAnalyticsPropertyKey: ProductAnalyticsPropertyValue] = [:]
        values.reserveCapacity(container.allKeys.count)

        for codingKey in container.allKeys {
            let valueDecoder = try container.superDecoder(forKey: codingKey)
            values[ProductAnalyticsPropertyKey(codingKey.stringValue)] = try ProductAnalyticsPropertyValue.decodeUnchecked(
                from: valueDecoder
            )
        }

        return ProductAnalyticsProperties(unchecked: values)
    }

    func encodeUnchecked(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: ProductAnalyticsPropertyCodingKey.self)

        for key in values.keys.sorted(by: { $0.rawValue < $1.rawValue }) {
            guard let value = values[key] else {
                continue
            }

            let codingKey = ProductAnalyticsPropertyCodingKey(stringValue: key.rawValue)!
            try value.encodeUnchecked(to: container.superEncoder(forKey: codingKey))
        }
    }
}

private struct ProductAnalyticsPropertyCodingKey: CodingKey {
    let stringValue: String
    let intValue: Int? = nil

    init?(stringValue: String) {
        self.stringValue = stringValue
    }

    init?(intValue: Int) {
        nil
    }
}
