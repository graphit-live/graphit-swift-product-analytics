import Foundation
import GraphitProductAnalytics
import Testing

@Suite("PropertyValueCodable")
struct PropertyValueCodableTests {
    @Test("property values encode as JSON-shaped values")
    func propertyValuesEncodeAsJSONShapes() throws {
        try expectEncoded(.null, equals: "null")
        try expectEncoded(.bool(true), equals: "true")
        try expectEncoded(.number(19.99), equals: "19.99")
        try expectEncoded(.string("pro"), equals: #""pro""#)
        try expectEncoded(.array([.string("seat"), .bool(false)]), equals: #"["seat",false]"#)

        let object = ProductAnalyticsPropertyValue.object(
            try ProductAnalyticsProperties([ProductAnalyticsPropertyKey("plan"): .string("pro")])
        )
        try expectEncoded(object, equals: #"{"plan":"pro"}"#)
    }

    @Test("property values decode from JSON-shaped values")
    func propertyValuesDecodeFromJSONShapes() throws {
        try expectDecoded("null", equals: .null)
        try expectDecoded("false", equals: .bool(false))
        try expectDecoded("19.99", equals: .number(19.99))
        try expectDecoded(#""pro""#, equals: .string("pro"))
        try expectDecoded(#"["seat",true]"#, equals: .array([.string("seat"), .bool(true)]))
        try expectDecoded(
            #"{"source":"paywall"}"#,
            equals: .object(
                try ProductAnalyticsProperties([ProductAnalyticsPropertyKey("source"): .string("paywall")])
            )
        )
    }

    @Test("JSON strings and numbers stay distinct during decoding")
    func stringAndNumberDecodingIsTypePreserving() throws {
        try expectDecoded(#""123""#, equals: .string("123"))
        try expectDecoded(#""NaN""#, equals: .string("NaN"))
        try expectDecoded(#""Infinity""#, equals: .string("Infinity"))
        try expectDecoded(#""-Infinity""#, equals: .string("-Infinity"))
        try expectDecoded("123", equals: .number(123))
    }

    @Test("property value encoding accepts exact v1 limits")
    func propertyValueEncodingAcceptsExactLimits() throws {
        _ = try JSONEncoder().encode(ProductAnalyticsPropertyValue.string(String(repeating: "x", count: 8_192)))
        _ = try JSONEncoder().encode(
            ProductAnalyticsPropertyValue.array(Array(repeating: .null, count: 100))
        )
        _ = try JSONEncoder().encode(
            ProductAnalyticsPropertyValue.object(try ProductAnalyticsProperties(makeProperties(count: 100)))
        )
        _ = try JSONEncoder().encode(nestedArray(depth: 8))
        _ = try JSONEncoder().encode(try nestedObject(depth: 8))
    }

    @Test("invalid enum-constructed property values fail during encoding")
    func invalidConstructedValuesFailDuringEncoding() throws {
        try expectInvalidPropertiesWhenEncoding(.number(.nan))
        try expectInvalidPropertiesWhenEncoding(.number(.infinity))
        try expectInvalidPropertiesWhenEncoding(.number(-.infinity))
        try expectInvalidPropertiesWhenEncoding(.string(String(repeating: "x", count: 8_193)))
        try expectInvalidPropertiesWhenEncoding(.array(Array(repeating: .null, count: 101)))
        try expectInvalidPropertiesWhenEncoding(nestedArray(depth: 9))
        try expectInvalidPropertiesWhenEncoding(nestedObject(depth: 9))
    }

    @Test("standalone object property values count the root object in depth validation")
    func standaloneObjectValuesCountRootObjectDepth() throws {
        _ = try JSONEncoder().encode(nestedObject(depth: 8))
        try expectInvalidPropertiesWhenEncoding(nestedObject(depth: 9))
    }

    @Test("property value decoding validates nested object depth boundary")
    func propertyValueDecodingValidatesNestedObjectDepthBoundary() throws {
        let decoded = try JSONDecoder().decode(
            ProductAnalyticsPropertyValue.self,
            from: Data(nestedObjectJSON(depth: 8).utf8)
        )

        #expect(decoded == (try nestedObject(depth: 8)))
        try expectInvalidPropertiesWhenDecoding(Data(nestedObjectJSON(depth: 9).utf8))
    }

    @Test("property value decoding validates semantic limits")
    func propertyValueDecodingValidatesSemanticLimits() throws {
        let tooLongString = try JSONEncoder().encode(String(repeating: "x", count: 8_193))
        try expectInvalidPropertiesWhenDecoding(tooLongString)

        let tooWideArrayJSON = "[" + Array(repeating: "null", count: 101).joined(separator: ",") + "]"
        try expectInvalidPropertiesWhenDecoding(Data(tooWideArrayJSON.utf8))

        let tooWideObjectJSON = "{" + (0..<101)
            .map { "\"key\($0)\":null" }
            .joined(separator: ",") + "}"
        try expectInvalidPropertiesWhenDecoding(Data(tooWideObjectJSON.utf8))

        let tooDeepArrayJSON = String(repeating: "[", count: 9) + "null" + String(repeating: "]", count: 9)
        try expectInvalidPropertiesWhenDecoding(Data(tooDeepArrayJSON.utf8))
    }

    @Test("property values support equality and hashing")
    func equalityAndHashing() throws {
        let values: Set<ProductAnalyticsPropertyValue> = [
            .null,
            .null,
            .bool(true),
            .number(1),
            .string("one"),
            .array([.string("one")]),
            .object(try ProductAnalyticsProperties([ProductAnalyticsPropertyKey("one"): .number(1)]))
        ]

        #expect(values.count == 6)
        #expect(values.contains(.array([.string("one")])))
    }
}

private func expectEncoded(_ value: ProductAnalyticsPropertyValue, equals expectedJSON: String) throws {
    let encoded = try JSONEncoder().encode(value)
    #expect(String(decoding: encoded, as: UTF8.self) == expectedJSON)
}

private func expectDecoded(_ json: String, equals expected: ProductAnalyticsPropertyValue) throws {
    let decoded = try JSONDecoder().decode(ProductAnalyticsPropertyValue.self, from: Data(json.utf8))
    #expect(decoded == expected)
}

private func expectInvalidPropertiesWhenEncoding(_ value: ProductAnalyticsPropertyValue) throws {
    do {
        _ = try JSONEncoder().encode(value)
        Issue.record("Expected property value encoding to fail")
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

private func expectInvalidPropertiesWhenDecoding(_ data: Data) throws {
    do {
        _ = try JSONDecoder().decode(ProductAnalyticsPropertyValue.self, from: data)
        Issue.record("Expected property value decoding to fail")
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

private func nestedArray(depth: Int) -> ProductAnalyticsPropertyValue {
    var value = ProductAnalyticsPropertyValue.null
    for _ in 0..<depth {
        value = .array([value])
    }
    return value
}

private func nestedObject(depth: Int) throws -> ProductAnalyticsPropertyValue {
    var value = ProductAnalyticsPropertyValue.null
    for level in 0..<depth {
        let properties = try ProductAnalyticsProperties([ProductAnalyticsPropertyKey("level_\(level)"): value])
        value = .object(properties)
    }
    return value
}

private func nestedObjectJSON(depth: Int) -> String {
    var json = "null"
    for level in 0..<depth {
        json = #"{"level_\#(level)":\#(json)}"#
    }
    return json
}
