/// A package-owned product analytics validation failure.
///
/// This error describes validation failures for the core value vocabulary only.
/// It does not model filesystem, network, cache, provider, vendor, queueing, or
/// transport failures. Package-generated messages are sanitized and do not include
/// raw property values.
public enum ProductAnalyticsError: Error, Sendable, Hashable, CustomStringConvertible {
    /// An invalid event name or occurrence time.
    case invalidEvent(String)

    /// Invalid analytics properties, property keys, or property values.
    ///
    /// Package-generated messages identify the invalid rule without including raw
    /// property values.
    case invalidProperties(String)

    /// An invalid event batch.
    case invalidBatch(String)

    /// A human-readable validation failure description.
    ///
    /// Package-generated property validation descriptions are sanitized and do not
    /// include raw property values.
    public var description: String {
        switch self {
        case .invalidEvent(let message):
            "Invalid product analytics event: \(message)"
        case .invalidProperties(let message):
            "Invalid product analytics properties: \(message)"
        case .invalidBatch(let message):
            "Invalid product analytics batch: \(message)"
        }
    }
}
