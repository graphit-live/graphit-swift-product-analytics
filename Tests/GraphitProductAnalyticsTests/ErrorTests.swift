import GraphitProductAnalytics
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

    @Test("package text validation messages do not echo supplied keys")
    func packageTextValidationMessagesDoNotEchoSuppliedKeys() {
        let rawKey = "secret-key\u{0000}"

        do {
            _ = try ProductAnalyticsProperties([ProductAnalyticsPropertyKey(rawKey): .null])
            Issue.record("Expected property-key validation to fail")
        } catch let error as ProductAnalyticsError {
            guard case .invalidProperties = error else {
                Issue.record("Expected ProductAnalyticsError.invalidProperties, received \(error)")
                return
            }

            #expect(error.description.contains("Invalid product analytics properties:"))
            #expect(!error.description.contains(rawKey))
            #expect(!error.description.contains("secret-key"))
        } catch {
            Issue.record("Expected ProductAnalyticsError.invalidProperties, received \(error)")
        }
    }

    @Test("package property validation messages do not echo raw property values")
    func packagePropertyValidationMessagesDoNotEchoRawPropertyValues() {
        let rawValue = "super-secret-token-" + String(repeating: "x", count: 8_193)

        do {
            _ = try ProductAnalyticsProperties([ProductAnalyticsPropertyKey("secret"): .string(rawValue)])
            Issue.record("Expected property-value validation to fail")
        } catch let error as ProductAnalyticsError {
            guard case .invalidProperties = error else {
                Issue.record("Expected ProductAnalyticsError.invalidProperties, received \(error)")
                return
            }

            #expect(error.description.contains("Invalid product analytics properties:"))
            #expect(!error.description.contains(rawValue))
            #expect(!error.description.contains("super-secret-token"))
        } catch {
            Issue.record("Expected ProductAnalyticsError.invalidProperties, received \(error)")
        }
    }
}
