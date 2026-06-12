import Foundation
import GraphitProductAnalytics
import Testing

@Suite("GraphitProductAnalytics API shell")
struct SmokeTests {
    @Test("public API shell constructs core values")
    func publicAPIShellConstructsCoreValues() throws {
        let name = ProductAnalyticsEventName("signup_completed")
        let key = ProductAnalyticsPropertyKey("plan")
        let properties = try ProductAnalyticsProperties([key: .string("pro")])
        let occurredAt = Date(timeIntervalSinceReferenceDate: 0)
        let event = try ProductAnalyticsEvent(
            name: name,
            occurredAt: occurredAt,
            properties: properties
        )
        let batch = try ProductAnalyticsBatch([event])

        #expect(name.rawValue == "signup_completed")
        #expect(key.rawValue == "plan")
        #expect(properties[key] == .string("pro"))
        #expect(event.name == name)
        #expect(batch.events == [event])
        #expect(ProductAnalyticsBatch(event).events == [event])
    }
}
