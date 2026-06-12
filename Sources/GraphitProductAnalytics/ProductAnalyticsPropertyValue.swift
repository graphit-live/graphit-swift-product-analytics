/// A provider-neutral JSON-shaped analytics property value.
///
/// Values are intentionally explicit instead of `[String: Any]`. Case construction
/// is nonvalidating; property and standalone Codable boundaries validate values
/// before accepting or serializing them. The Codable representation is JSON-shaped:
/// null, Boolean, number, string, array, or object.
///
/// Property values may contain user-visible or private application data. The core
/// package validates structure but does not redact, normalize, inspect for privacy,
/// log, send, queue, or persist values.
public indirect enum ProductAnalyticsPropertyValue: Hashable, Codable, Sendable {
    /// A JSON null value.
    case null

    /// A JSON Boolean value.
    case bool(Bool)

    /// A JSON number value.
    ///
    /// Valid analytics property numbers are finite `Double` values.
    case number(Double)

    /// A JSON string value.
    ///
    /// Strings are not parsed as numbers and are not redacted, trimmed, or normalized.
    case string(String)

    /// A JSON array of analytics property values.
    case array([ProductAnalyticsPropertyValue])

    /// A JSON object represented by validated analytics properties.
    case object(ProductAnalyticsProperties)

    /// Decodes a JSON-shaped property value and validates it as a root property value.
    ///
    /// Decoding is type-preserving: JSON strings remain strings and JSON numbers remain
    /// numbers. Semantic validation failures throw `ProductAnalyticsError.invalidProperties`.
    ///
    /// - Parameter decoder: The decoder providing the JSON-shaped property value.
    /// - Throws: `ProductAnalyticsError.invalidProperties` when the decoded value violates
    ///   property value limits, or `DecodingError` for structural decoding failures.
    public init(from decoder: any Decoder) throws {
        let value = try Self.decodeUnchecked(from: decoder)
        try ProductAnalyticsValidation.validatePropertyValue(value)
        self = value
    }

    /// Encodes the property value as JSON-shaped data after validating it as a root value.
    ///
    /// - Parameter encoder: The encoder that receives the JSON-shaped property value.
    /// - Throws: `ProductAnalyticsError.invalidProperties` when this value violates property
    ///   value limits.
    public func encode(to encoder: any Encoder) throws {
        try ProductAnalyticsValidation.validatePropertyValue(self)
        try encodeUnchecked(to: encoder)
    }
}

extension ProductAnalyticsPropertyValue {
    static func decodeUnchecked(from decoder: any Decoder) throws -> ProductAnalyticsPropertyValue {
        let singleValueContainer = try decoder.singleValueContainer()

        if singleValueContainer.decodeNil() {
            return .null
        }

        if let bool = try? singleValueContainer.decode(Bool.self) {
            return .bool(bool)
        }

        if let string = try? singleValueContainer.decode(String.self) {
            return .string(string)
        }

        if let number = try? singleValueContainer.decode(Double.self) {
            return .number(number)
        }

        if var unkeyedContainer = try? decoder.unkeyedContainer() {
            var values: [ProductAnalyticsPropertyValue] = []
            if let count = unkeyedContainer.count {
                values.reserveCapacity(count)
            }

            while !unkeyedContainer.isAtEnd {
                let elementDecoder = try unkeyedContainer.superDecoder()
                values.append(try decodeUnchecked(from: elementDecoder))
            }

            return .array(values)
        }

        return .object(try ProductAnalyticsProperties.decodeUnchecked(from: decoder))
    }

    func encodeUnchecked(to encoder: any Encoder) throws {
        switch self {
        case .null:
            var container = encoder.singleValueContainer()
            try container.encodeNil()

        case .bool(let bool):
            var container = encoder.singleValueContainer()
            try container.encode(bool)

        case .number(let number):
            var container = encoder.singleValueContainer()
            try container.encode(number)

        case .string(let string):
            var container = encoder.singleValueContainer()
            try container.encode(string)

        case .array(let values):
            var container = encoder.unkeyedContainer()
            for value in values {
                try value.encodeUnchecked(to: container.superEncoder())
            }

        case .object(let properties):
            try properties.encodeUnchecked(to: encoder)
        }
    }
}
