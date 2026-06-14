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

    @Test("property key length boundary is enforced by properties")
    func propertyKeyLengthBoundary() throws {
        let maximumKey = ProductAnalyticsPropertyKey(String(repeating: "k", count: 256))
        let properties = try ProductAnalyticsProperties([maximumKey: .null])

        #expect(properties[maximumKey] == .null)

        try expectInvalidProperties {
            _ = try ProductAnalyticsProperties([
                ProductAnalyticsPropertyKey(String(repeating: "k", count: 257)): .null
            ])
        }
    }

    @Test("empty and control-scalar property keys are rejected by properties")
    func invalidPropertyKeysAreRejected() throws {
        try expectInvalidProperties {
            _ = try ProductAnalyticsProperties([ProductAnalyticsPropertyKey(""): .null])
        }
        try expectInvalidProperties {
            _ = try ProductAnalyticsProperties([ProductAnalyticsPropertyKey("pl\u{0000}an"): .null])
        }
        try expectInvalidProperties {
            _ = try ProductAnalyticsProperties([ProductAnalyticsPropertyKey("pl\u{007F}an"): .null])
        }
        try expectInvalidProperties {
            _ = try ProductAnalyticsProperties([ProductAnalyticsPropertyKey("pl\u{009F}an"): .null])
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

    @Test("string value length boundary is enforced without echoing raw values")
    func stringValueLengthBoundaryAndSanitization() throws {
        let key = ProductAnalyticsPropertyKey("value")
        let maximumValue = String(repeating: "x", count: 8_192)
        let valid = try ProductAnalyticsProperties([key: .string(maximumValue)])

        #expect(valid[key] == .string(maximumValue))

        let rawValue = "super-secret-token-" + String(repeating: "x", count: 8_193)

        do {
            _ = try ProductAnalyticsProperties([ProductAnalyticsPropertyKey("secret"): .string(rawValue)])
            Issue.record("Expected properties construction to fail")
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

    @Test("array and object width boundaries are enforced")
    func arrayAndObjectWidthBoundaries() throws {
        let items = ProductAnalyticsPropertyKey("items")
        let maximumArray = Array(repeating: ProductAnalyticsPropertyValue.null, count: 100)
        let validArrayProperties = try ProductAnalyticsProperties([items: .array(maximumArray)])

        #expect(validArrayProperties[items] == .array(maximumArray))

        try expectInvalidProperties {
            _ = try ProductAnalyticsProperties([
                items: .array(Array(repeating: .null, count: 101))
            ])
        }

        let maximumProperties = makeProperties(count: 100)
        let validObject = try ProductAnalyticsProperties(maximumProperties)

        #expect(validObject.values.count == 100)

        try expectInvalidProperties {
            _ = try ProductAnalyticsProperties(makeProperties(count: 101))
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
        guard case .invalidProperties = error else {
            Issue.record("Expected ProductAnalyticsError.invalidProperties, received \(error)")
            return
        }

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
        guard case .invalidProperties = error else {
            Issue.record("Expected ProductAnalyticsError.invalidProperties, received \(error)")
            return
        }

        #expect(error.description.contains("Invalid product analytics properties:"))
    } catch {
        Issue.record("Expected ProductAnalyticsError.invalidProperties, received \(error)")
    }
}

private func makeProperties(count: Int) -> [ProductAnalyticsPropertyKey: ProductAnalyticsPropertyValue] {
    Dictionary(
        uniqueKeysWithValues: (0..<count).map { index in
            (ProductAnalyticsPropertyKey("key\(index)"), ProductAnalyticsPropertyValue.null)
        }
    )
}

private func nestedArrayValue(depth: Int) -> ProductAnalyticsPropertyValue {
    var value = ProductAnalyticsPropertyValue.null
    for _ in 0..<depth {
        value = .array([value])
    }
    return value
}
