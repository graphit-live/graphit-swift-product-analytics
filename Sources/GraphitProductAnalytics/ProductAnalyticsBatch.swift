/// A validated ordered batch of product analytics events.
///
/// A batch is an immutable value only. It does not own a queue, timer, transport,
/// retry policy, persistence layer, or flush lifecycle.
public struct ProductAnalyticsBatch: Hashable, Codable, Sendable {
    /// The ordered events in the batch.
    public let events: [ProductAnalyticsEvent]

    /// Creates an ordered batch from one or more events.
    ///
    /// - Parameter events: Events to include in their existing order.
    /// - Throws: `ProductAnalyticsError.invalidBatch` when the event count is empty or
    ///   exceeds the v1 batch limit.
    public init(_ events: [ProductAnalyticsEvent]) throws {
        self.events = events
    }

    /// Creates a batch containing exactly one event.
    ///
    /// - Parameter event: The event to include.
    public init(_ event: ProductAnalyticsEvent) {
        self.events = [event]
    }
}
