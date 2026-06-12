import Foundation
import GraphitProductAnalytics
import Testing

@Suite("BatchValidation")
struct BatchValidationTests {
    @Test("single-event initializer creates one-event batch")
    func singleEventInitializerCreatesOneEventBatch() throws {
        let event = try makeEvent(0)
        let batch = ProductAnalyticsBatch(event)

        #expect(batch.events == [event])
    }

    @Test("multi-event initializer preserves order")
    func multiEventInitializerPreservesOrder() throws {
        let first = try makeEvent(1)
        let second = try makeEvent(2)
        let third = try makeEvent(3)

        let batch = try ProductAnalyticsBatch([first, second, third])

        #expect(batch.events == [first, second, third])
        #expect(batch.events.map(\.name.rawValue) == ["event_1", "event_2", "event_3"])
    }

    @Test("empty batch is rejected")
    func emptyBatchIsRejected() throws {
        try expectInvalidBatch {
            _ = try ProductAnalyticsBatch([])
        }
    }

    @Test("too-large batch is rejected")
    func tooLargeBatchIsRejected() throws {
        let event = try makeEvent(0)

        try expectInvalidBatch {
            _ = try ProductAnalyticsBatch(Array(repeating: event, count: 1_001))
        }
    }

    @Test("batch Codable uses object shape")
    func batchCodableObjectShape() throws {
        let event = try makeEvent(0)
        let batch = ProductAnalyticsBatch(event)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]

        let encoded = try encoder.encode(batch)
        #expect(
            String(decoding: encoded, as: UTF8.self) ==
                #"{"events":[{"name":"event_0","occurredAt":0,"properties":{}}]}"#
        )

        let decoded = try JSONDecoder().decode(ProductAnalyticsBatch.self, from: encoded)
        #expect(decoded == batch)
    }

    @Test("batch decoding rejects empty event arrays")
    func batchDecodingRejectsEmptyEventArrays() throws {
        try expectInvalidBatchWhenDecoding(Data(#"{"events":[]}"#.utf8))
    }

    @Test("batch decoding rejects too-large event arrays")
    func batchDecodingRejectsTooLargeEventArrays() throws {
        let eventJSON = #"{"name":"event","occurredAt":0,"properties":{}}"#
        let json = #"{"events":["# + Array(repeating: eventJSON, count: 1_001).joined(separator: ",") + "]}"

        try expectInvalidBatchWhenDecoding(Data(json.utf8))
    }

    @Test("batch decoding preserves event validation errors")
    func batchDecodingPreservesEventValidationErrors() throws {
        try expectInvalidEventWhenDecodingBatch(
            Data(#"{"events":[{"name":"","occurredAt":0,"properties":{}}]}"#.utf8)
        )
    }
}

private func makeEvent(_ index: Int) throws -> ProductAnalyticsEvent {
    try ProductAnalyticsEvent(
        name: ProductAnalyticsEventName("event_\(index)"),
        occurredAt: Date(timeIntervalSinceReferenceDate: TimeInterval(index))
    )
}

private func expectInvalidBatch(_ operation: () throws -> Void) throws {
    do {
        try operation()
        Issue.record("Expected invalid batch failure")
    } catch let error as ProductAnalyticsError {
        guard case .invalidBatch = error else {
            Issue.record("Expected ProductAnalyticsError.invalidBatch, received \(error)")
            return
        }
    } catch {
        Issue.record("Expected ProductAnalyticsError.invalidBatch, received \(error)")
    }
}

private func expectInvalidBatchWhenDecoding(_ data: Data) throws {
    do {
        _ = try JSONDecoder().decode(ProductAnalyticsBatch.self, from: data)
        Issue.record("Expected batch decoding to fail")
    } catch let error as ProductAnalyticsError {
        guard case .invalidBatch = error else {
            Issue.record("Expected ProductAnalyticsError.invalidBatch, received \(error)")
            return
        }
    } catch {
        Issue.record("Expected ProductAnalyticsError.invalidBatch, received \(error)")
    }
}

private func expectInvalidEventWhenDecodingBatch(_ data: Data) throws {
    do {
        _ = try JSONDecoder().decode(ProductAnalyticsBatch.self, from: data)
        Issue.record("Expected batch decoding to fail")
    } catch let error as ProductAnalyticsError {
        guard case .invalidEvent = error else {
            Issue.record("Expected ProductAnalyticsError.invalidEvent, received \(error)")
            return
        }
    } catch {
        Issue.record("Expected ProductAnalyticsError.invalidEvent, received \(error)")
    }
}
