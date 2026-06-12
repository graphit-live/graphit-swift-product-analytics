/// A package-owned product analytics validation failure.
///
/// This error describes validation failures for the core value vocabulary only.
/// It does not model filesystem, network, cache, provider, vendor, queueing, or
/// transport failures.
public enum ProductAnalyticsError: Error, Sendable, Hashable, CustomStringConvertible {
    /// An invalid event name or occurrence time.
    case invalidEvent(String)

    /// Invalid analytics properties, property keys, or property values.
    case invalidProperties(String)

    /// An invalid event batch.
    case invalidBatch(String)

    /// A human-readable validation failure description.
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
