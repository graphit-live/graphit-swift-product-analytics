@testable import GraphitProductAnalytics
import Testing

@Suite("Error")
struct ProductAnalyticsErrorTests {
    @Test("error descriptions include validation categories")
    func descriptionsIncludeValidationCategories() {
        #expect(
            ProductAnalyticsError.invalidEvent("event name must not be empty").description ==
                "Invalid product analytics event: event name must not be empty"
        )
        #expect(
            ProductAnalyticsError.invalidProperties("property key must not be empty").description ==
                "Invalid product analytics properties: property key must not be empty"
        )
        #expect(
            ProductAnalyticsError.invalidBatch("batch must contain at least one event").description ==
                "Invalid product analytics batch: batch must contain at least one event"
        )
    }

    @Test("package text validation messages do not echo supplied text")
    func packageTextValidationMessagesDoNotEchoSuppliedText() {
        let rawKey = "secret-key\u{0000}"

        do {
            try ProductAnalyticsValidation.validatePropertyKey(ProductAnalyticsPropertyKey(rawKey))
            Issue.record("Expected property-key validation to fail")
        } catch let error as ProductAnalyticsError {
            #expect(error.description.contains("Invalid product analytics properties:"))
            #expect(!error.description.contains(rawKey))
            #expect(!error.description.contains("secret-key"))
        } catch {
            Issue.record("Expected ProductAnalyticsError, received \(error)")
        }
    }
}
