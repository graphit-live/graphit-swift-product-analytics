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
        try ProductAnalyticsValidation.validateBatchEvents(events)
        self.events = events
    }

    /// Creates a batch containing exactly one event.
    ///
    /// - Parameter event: The event to include.
    public init(_ event: ProductAnalyticsEvent) {
        self.events = [event]
    }

    /// Decodes a batch from an object containing an ordered `events` array.
    ///
    /// Decoding validates that the batch contains at least one event and no more than
    /// the v1 batch limit.
    ///
    /// - Parameter decoder: The decoder providing the object-shaped batch representation.
    /// - Throws: `ProductAnalyticsError.invalidBatch` when the decoded event count is invalid,
    ///   or `DecodingError` for structural decoding failures.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let events = try container.decode([ProductAnalyticsEvent].self, forKey: .events)
        try ProductAnalyticsValidation.validateBatchEvents(events)
        self.events = events
    }

    /// Encodes the batch as an object containing an ordered `events` array.
    ///
    /// Encoding does not split, persist, queue, send, or otherwise deliver the batch.
    ///
    /// - Parameter encoder: The encoder that receives the object-shaped batch representation.
    /// - Throws: `ProductAnalyticsError.invalidBatch` if this batch violates batch count rules.
    public func encode(to encoder: any Encoder) throws {
        try ProductAnalyticsValidation.validateBatchEvents(events)

        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(events, forKey: .events)
    }
}

private enum CodingKeys: String, CodingKey {
    case events
}
