/// A provider-neutral JSON-shaped analytics property value.
///
/// Values are intentionally explicit instead of `[String: Any]`. Case construction
/// is nonvalidating; property and standalone Codable boundaries validate values
/// before accepting or serializing them.
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
    case string(String)

    /// A JSON array of analytics property values.
    case array([ProductAnalyticsPropertyValue])

    /// A JSON object represented by analytics properties.
    case object(ProductAnalyticsProperties)
}
