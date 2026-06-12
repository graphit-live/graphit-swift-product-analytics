/// A validated immutable collection of product analytics event properties.
///
/// Properties are keyed by `ProductAnalyticsPropertyKey` and contain JSON-shaped
/// `ProductAnalyticsPropertyValue` values. Property order is not semantic.
public struct ProductAnalyticsProperties: Hashable, Codable, Sendable {
    /// A prevalidated empty property collection.
    public static let empty = ProductAnalyticsProperties(unchecked: [:])

    /// The underlying property values keyed by app-defined property keys.
    public let values: [ProductAnalyticsPropertyKey: ProductAnalyticsPropertyValue]

    /// Creates analytics properties from app-defined key-value pairs.
    ///
    /// - Parameter values: The property values to include. Empty properties are valid.
    /// - Throws: `ProductAnalyticsError.invalidProperties` when a key or value violates
    ///   the analytics property validation rules.
    public init(_ values: [ProductAnalyticsPropertyKey: ProductAnalyticsPropertyValue] = [:]) throws {
        self.values = values
    }

    private init(unchecked values: [ProductAnalyticsPropertyKey: ProductAnalyticsPropertyValue]) {
        self.values = values
    }

    /// Returns the value for the supplied property key, if one is present.
    ///
    /// - Parameter key: The app-defined property key to look up.
    public subscript(_ key: ProductAnalyticsPropertyKey) -> ProductAnalyticsPropertyValue? {
        values[key]
    }
}
