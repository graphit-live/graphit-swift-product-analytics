import Foundation
import GraphitProductAnalytics
import Testing

@Suite("PropertiesValidation")
struct PropertiesValidationTests {
    @Test("empty properties are valid")
    func emptyPropertiesAreValid() throws {
        let explicitEmpty = try ProductAnalyticsProperties()
        let dictionaryEmpty = try ProductAnalyticsProperties([:])

        #expect(ProductAnalyticsProperties.empty.values.isEmpty)
        #expect(explicitEmpty == .empty)
        #expect(dictionaryEmpty == .empty)
    }

    @Test("valid scalar array and object properties are accepted")
    func validPropertiesAreAccepted() throws {
        let plan = ProductAnalyticsPropertyKey("plan")
        let items = ProductAnalyticsPropertyKey("items")
        let metadata = ProductAnalyticsPropertyKey("metadata")
        let source = ProductAnalyticsPropertyKey("source")
        let nested = try ProductAnalyticsProperties([source: .string("paywall")])

        let properties = try ProductAnalyticsProperties([
            plan: .string("pro"),
            items: .array([.string("seat"), .number(2)]),
            metadata: .object(nested)
        ])

        #expect(properties[plan] == .string("pro"))
        #expect(properties[items] == .array([.string("seat"), .number(2)]))
        #expect(properties[metadata] == .object(nested))
    }

    @Test("subscript returns nil for missing keys")
    func subscriptReturnsNilForMissingKeys() throws {
        let present = ProductAnalyticsPropertyKey("present")
        let missing = ProductAnalyticsPropertyKey("missing")
        let properties = try ProductAnalyticsProperties([present: .bool(true)])

        #expect(properties[present] == .bool(true))
        #expect(properties[missing] == nil)
    }

    @Test("invalid property keys are rejected by properties")
    func invalidPropertyKeysAreRejected() throws {
        try expectInvalidProperties {
            _ = try ProductAnalyticsProperties([ProductAnalyticsPropertyKey(""): .null])
        }
        try expectInvalidProperties {
            _ = try ProductAnalyticsProperties([ProductAnalyticsPropertyKey("pl\u{0000}an"): .null])
        }
        try expectInvalidProperties {
            _ = try ProductAnalyticsProperties([
                ProductAnalyticsPropertyKey(String(repeating: "k", count: 257)): .null
            ])
        }
    }

    @Test("non-finite numbers are rejected by properties")
    func nonFiniteNumbersAreRejected() throws {
        try expectInvalidProperties {
            _ = try ProductAnalyticsProperties([ProductAnalyticsPropertyKey("amount"): .number(.nan)])
        }
        try expectInvalidProperties {
            _ = try ProductAnalyticsProperties([ProductAnalyticsPropertyKey("amount"): .number(.infinity)])
        }
        try expectInvalidProperties {
            _ = try ProductAnalyticsProperties([ProductAnalyticsPropertyKey("amount"): .number(-.infinity)])
        }
    }

    @Test("too-long string values are rejected without echoing raw values")
    func tooLongStringValuesAreRejectedAndSanitized() throws {
        let rawValue = "super-secret-token-" + String(repeating: "x", count: 8_193)

        do {
            _ = try ProductAnalyticsProperties([ProductAnalyticsPropertyKey("secret"): .string(rawValue)])
            Issue.record("Expected properties construction to fail")
        } catch let error as ProductAnalyticsError {
            #expect(error.description.contains("Invalid product analytics properties:"))
            #expect(!error.description.contains(rawValue))
            #expect(!error.description.contains("super-secret-token"))
        } catch {
            Issue.record("Expected ProductAnalyticsError.invalidProperties, received \(error)")
        }
    }

    @Test("too-wide arrays and objects are rejected")
    func tooWideArraysAndObjectsAreRejected() throws {
        try expectInvalidProperties {
            _ = try ProductAnalyticsProperties([
                ProductAnalyticsPropertyKey("items"): .array(Array(repeating: .null, count: 101))
            ])
        }

        let tooManyProperties = Dictionary(
            uniqueKeysWithValues: (0..<101).map { index in
                (ProductAnalyticsPropertyKey("key\(index)"), ProductAnalyticsPropertyValue.null)
            }
        )
        try expectInvalidProperties {
            _ = try ProductAnalyticsProperties(tooManyProperties)
        }
    }

    @Test("depth eight is valid and depth nine is rejected")
    func depthBoundary() throws {
        let key = ProductAnalyticsPropertyKey("nested")

        let valid = try ProductAnalyticsProperties([key: nestedArrayValue(depth: 8)])
        #expect(valid[key] == nestedArrayValue(depth: 8))

        try expectInvalidProperties {
            _ = try ProductAnalyticsProperties([key: nestedArrayValue(depth: 9)])
        }
    }

    @Test("properties encode and decode as JSON objects")
    func propertiesCodableObjectShape() throws {
        let properties = try ProductAnalyticsProperties([
            ProductAnalyticsPropertyKey("plan"): .string("pro")
        ])

        let encoded = try JSONEncoder().encode(properties)
        #expect(String(decoding: encoded, as: UTF8.self) == #"{"plan":"pro"}"#)

        let decoded = try JSONDecoder().decode(ProductAnalyticsProperties.self, from: encoded)
        #expect(decoded == properties)
    }

    @Test("properties decoding validates keys and values")
    func propertiesDecodingValidatesSemantics() throws {
        try expectInvalidPropertiesWhenDecodingProperties(Data(#"{"":null}"#.utf8))

        let tooLongStringJSON = "{\"value\":\"" + String(repeating: "x", count: 8_193) + "\"}"
        try expectInvalidPropertiesWhenDecodingProperties(Data(tooLongStringJSON.utf8))

        let tooWideObjectJSON = "{" + (0..<101)
            .map { "\"key\($0)\":null" }
            .joined(separator: ",") + "}"
        try expectInvalidPropertiesWhenDecodingProperties(Data(tooWideObjectJSON.utf8))
    }
}

private func expectInvalidProperties(_ operation: () throws -> Void) throws {
    do {
        try operation()
        Issue.record("Expected invalid properties failure")
    } catch let error as ProductAnalyticsError {
        #expect(error.description.contains("Invalid product analytics properties:"))
    } catch {
        Issue.record("Expected ProductAnalyticsError.invalidProperties, received \(error)")
    }
}

private func expectInvalidPropertiesWhenDecodingProperties(_ data: Data) throws {
    do {
        _ = try JSONDecoder().decode(ProductAnalyticsProperties.self, from: data)
        Issue.record("Expected properties decoding to fail")
    } catch let error as ProductAnalyticsError {
        #expect(error.description.contains("Invalid product analytics properties:"))
    } catch {
        Issue.record("Expected ProductAnalyticsError.invalidProperties, received \(error)")
    }
}

private func nestedArrayValue(depth: Int) -> ProductAnalyticsPropertyValue {
    var value = ProductAnalyticsPropertyValue.null
    for _ in 0..<depth {
        value = .array([value])
    }
    return value
}
