import Foundation
import GraphitProductAnalytics
import Testing

@Suite("READMEExamples")
struct READMEExamplesTests {
    @Test("quick-start event example compiles")
    func quickStartEventExampleCompiles() throws {
        let event = try ProductAnalyticsEvent(
            name: AppAnalytics.Events.signupCompleted,
            occurredAt: Date(timeIntervalSinceReferenceDate: 0),
            properties: [
                AppAnalytics.Properties.plan: .string("pro"),
                AppAnalytics.Properties.source: .string("paywall")
            ]
        )

        #expect(event.name == AppAnalytics.Events.signupCompleted)
        #expect(event.properties[AppAnalytics.Properties.plan] == .string("pro"))
        #expect(event.properties[AppAnalytics.Properties.source] == .string("paywall"))
    }

    @Test("property and batch examples compile")
    func propertyAndBatchExamplesCompile() throws {
        let properties = try ProductAnalyticsProperties([
            ProductAnalyticsPropertyKey("plan"): .string("pro"),
            ProductAnalyticsPropertyKey("seat_count"): .number(3),
            ProductAnalyticsPropertyKey("is_trial"): .bool(false),
            ProductAnalyticsPropertyKey("coupon"): .null,
            ProductAnalyticsPropertyKey("items"): .array([.string("seat"), .string("storage")])
        ])
        let event = try ProductAnalyticsEvent(
            name: AppAnalytics.Events.signupCompleted,
            occurredAt: Date(timeIntervalSinceReferenceDate: 0),
            properties: properties
        )

        let batch = try ProductAnalyticsBatch([event])
        let singleEventBatch = ProductAnalyticsBatch(event)

        #expect(batch.events == [event])
        #expect(singleEventBatch.events == [event])
    }

    @Test("Codable example compiles and round trips")
    func codableExampleCompilesAndRoundTrips() throws {
        let event = try ProductAnalyticsEvent(
            name: AppAnalytics.Events.signupCompleted,
            occurredAt: Date(timeIntervalSinceReferenceDate: 0),
            properties: [AppAnalytics.Properties.plan: .string("pro")]
        )

        let data = try JSONEncoder().encode(event)
        let decoded = try JSONDecoder().decode(ProductAnalyticsEvent.self, from: data)

        #expect(decoded == event)
    }
}

private enum AppAnalytics {
    enum Events {
        static let signupCompleted = ProductAnalyticsEventName("signup_completed")
    }

    enum Properties {
        static let plan = ProductAnalyticsPropertyKey("plan")
        static let source = ProductAnalyticsPropertyKey("source")
    }
}
