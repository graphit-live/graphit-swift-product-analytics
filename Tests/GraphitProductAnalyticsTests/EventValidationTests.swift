import Foundation
import GraphitProductAnalytics
import Testing

@Suite("EventValidation")
struct EventValidationTests {
    @Test("valid event construction accepts explicit date and empty properties")
    func validEventConstructionWithEmptyProperties() throws {
        let occurredAt = Date(timeIntervalSinceReferenceDate: 0)
        let event = try ProductAnalyticsEvent(
            name: ProductAnalyticsEventName("signup_completed"),
            occurredAt: occurredAt
        )

        #expect(event.name == ProductAnalyticsEventName("signup_completed"))
        #expect(event.occurredAt == occurredAt)
        #expect(event.properties == .empty)
    }

    @Test("valid event construction accepts dictionary properties")
    func validEventConstructionWithDictionaryProperties() throws {
        let plan = ProductAnalyticsPropertyKey("plan")
        let event = try ProductAnalyticsEvent(
            name: ProductAnalyticsEventName("signup_completed"),
            occurredAt: Date(timeIntervalSinceReferenceDate: 0),
            properties: [plan: .string("pro")]
        )

        #expect(event.properties[plan] == .string("pro"))
    }

    @Test("dictionary convenience initializer validates properties")
    func dictionaryInitializerValidatesProperties() throws {
        try expectInvalidProperties {
            _ = try ProductAnalyticsEvent(
                name: ProductAnalyticsEventName("signup_completed"),
                occurredAt: Date(timeIntervalSinceReferenceDate: 0),
                properties: [ProductAnalyticsPropertyKey(""): .null]
            )
        }
    }

    @Test("invalid event names are rejected")
    func invalidEventNamesAreRejected() throws {
        try expectInvalidEvent {
            _ = try ProductAnalyticsEvent(
                name: ProductAnalyticsEventName(""),
                occurredAt: Date(timeIntervalSinceReferenceDate: 0)
            )
        }
        try expectInvalidEvent {
            _ = try ProductAnalyticsEvent(
                name: ProductAnalyticsEventName("signup\u{0000}completed"),
                occurredAt: Date(timeIntervalSinceReferenceDate: 0)
            )
        }
        try expectInvalidEvent {
            _ = try ProductAnalyticsEvent(
                name: ProductAnalyticsEventName(String(repeating: "e", count: 257)),
                occurredAt: Date(timeIntervalSinceReferenceDate: 0)
            )
        }
    }

    @Test("non-finite dates are rejected")
    func nonFiniteDatesAreRejected() throws {
        try expectInvalidEvent {
            _ = try ProductAnalyticsEvent(
                name: ProductAnalyticsEventName("signup_completed"),
                occurredAt: Date(timeIntervalSinceReferenceDate: .nan)
            )
        }
        try expectInvalidEvent {
            _ = try ProductAnalyticsEvent(
                name: ProductAnalyticsEventName("signup_completed"),
                occurredAt: Date(timeIntervalSinceReferenceDate: .infinity)
            )
        }
        try expectInvalidEvent {
            _ = try ProductAnalyticsEvent(
                name: ProductAnalyticsEventName("signup_completed"),
                occurredAt: Date(timeIntervalSinceReferenceDate: -.infinity)
            )
        }
    }

    @Test("old and future finite timestamps are valid")
    func oldAndFutureFiniteTimestampsAreValid() throws {
        let oldEvent = try ProductAnalyticsEvent(
            name: ProductAnalyticsEventName("historic_event"),
            occurredAt: Date(timeIntervalSinceReferenceDate: -1_000_000_000)
        )
        let futureEvent = try ProductAnalyticsEvent(
            name: ProductAnalyticsEventName("future_event"),
            occurredAt: Date(timeIntervalSinceReferenceDate: 1_000_000_000)
        )

        #expect(oldEvent.occurredAt.timeIntervalSinceReferenceDate < 0)
        #expect(futureEvent.occurredAt.timeIntervalSinceReferenceDate > 0)
    }

    @Test("event Codable uses object shape")
    func eventCodableObjectShape() throws {
        let event = try ProductAnalyticsEvent(
            name: ProductAnalyticsEventName("signup_completed"),
            occurredAt: Date(timeIntervalSinceReferenceDate: 0),
            properties: .empty
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]

        let encoded = try encoder.encode(event)
        #expect(
            String(decoding: encoded, as: UTF8.self) ==
                #"{"name":"signup_completed","occurredAt":0,"properties":{}}"#
        )

        let decoded = try JSONDecoder().decode(ProductAnalyticsEvent.self, from: encoded)
        #expect(decoded == event)
    }

    @Test("event decoding validates event semantics")
    func eventDecodingValidatesEventSemantics() throws {
        try expectInvalidEventWhenDecoding(
            Data(#"{"name":"","occurredAt":0,"properties":{}}"#.utf8)
        )

        let decoder = JSONDecoder()
        decoder.nonConformingFloatDecodingStrategy = .convertFromString(
            positiveInfinity: "Infinity",
            negativeInfinity: "-Infinity",
            nan: "NaN"
        )
        try expectInvalidEventWhenDecoding(
            Data(#"{"name":"signup_completed","occurredAt":"NaN","properties":{}}"#.utf8),
            decoder: decoder
        )
    }

    @Test("event decoding preserves property validation errors")
    func eventDecodingPreservesPropertyValidationErrors() throws {
        try expectInvalidPropertiesWhenDecodingEvent(
            Data(#"{"name":"signup_completed","occurredAt":0,"properties":{"":null}}"#.utf8)
        )
    }
}

private func expectInvalidEvent(_ operation: () throws -> Void) throws {
    do {
        try operation()
        Issue.record("Expected invalid event failure")
    } catch let error as ProductAnalyticsError {
        guard case .invalidEvent = error else {
            Issue.record("Expected ProductAnalyticsError.invalidEvent, received \(error)")
            return
        }
    } catch {
        Issue.record("Expected ProductAnalyticsError.invalidEvent, received \(error)")
    }
}

private func expectInvalidProperties(_ operation: () throws -> Void) throws {
    do {
        try operation()
        Issue.record("Expected invalid properties failure")
    } catch let error as ProductAnalyticsError {
        guard case .invalidProperties = error else {
            Issue.record("Expected ProductAnalyticsError.invalidProperties, received \(error)")
            return
        }
    } catch {
        Issue.record("Expected ProductAnalyticsError.invalidProperties, received \(error)")
    }
}

private func expectInvalidEventWhenDecoding(
    _ data: Data,
    decoder: JSONDecoder = JSONDecoder()
) throws {
    do {
        _ = try decoder.decode(ProductAnalyticsEvent.self, from: data)
        Issue.record("Expected event decoding to fail")
    } catch let error as ProductAnalyticsError {
        guard case .invalidEvent = error else {
            Issue.record("Expected ProductAnalyticsError.invalidEvent, received \(error)")
            return
        }
    } catch {
        Issue.record("Expected ProductAnalyticsError.invalidEvent, received \(error)")
    }
}

private func expectInvalidPropertiesWhenDecodingEvent(_ data: Data) throws {
    do {
        _ = try JSONDecoder().decode(ProductAnalyticsEvent.self, from: data)
        Issue.record("Expected event decoding to fail")
    } catch let error as ProductAnalyticsError {
        guard case .invalidProperties = error else {
            Issue.record("Expected ProductAnalyticsError.invalidProperties, received \(error)")
            return
        }
    } catch {
        Issue.record("Expected ProductAnalyticsError.invalidProperties, received \(error)")
    }
}
