import Foundation
import GraphitProductAnalytics
import Testing

@Suite("TextValue")
struct TextValueTests {
    @Test("event name stores raw value and description")
    func eventNameRawValueAndDescription() {
        let name = ProductAnalyticsEventName("signup_completed")
        let rawRepresentableName = ProductAnalyticsEventName(rawValue: "signup_completed")

        #expect(name.rawValue == "signup_completed")
        #expect(rawRepresentableName == name)
        #expect(name.description == "signup_completed")
    }

    @Test("event name supports equality and hashing")
    func eventNameEqualityAndHashing() {
        let names: Set<ProductAnalyticsEventName> = [
            ProductAnalyticsEventName("signup_completed"),
            ProductAnalyticsEventName("signup_completed"),
            ProductAnalyticsEventName("signup_started")
        ]

        #expect(names.count == 2)
        #expect(names.contains(ProductAnalyticsEventName("signup_completed")))
        #expect(names.contains(ProductAnalyticsEventName("signup_started")))
    }

    @Test("event name encodes and decodes as one string")
    func eventNameSingleStringCodableShape() throws {
        let name = ProductAnalyticsEventName("signup_completed")

        let encoded = try JSONEncoder().encode(name)
        #expect(String(decoding: encoded, as: UTF8.self) == #""signup_completed""#)

        let decoded = try JSONDecoder().decode(ProductAnalyticsEventName.self, from: encoded)
        #expect(decoded == name)
    }

    @Test("event name construction and decoding do not validate text")
    func eventNameConstructionAndDecodingDoNotValidate() throws {
        let empty = ProductAnalyticsEventName("")
        let control = ProductAnalyticsEventName("signup\u{0000}completed")

        #expect(empty.rawValue.isEmpty)
        #expect(control.rawValue == "signup\u{0000}completed")

        let decodedEmpty = try JSONDecoder().decode(
            ProductAnalyticsEventName.self,
            from: Data(#""""#.utf8)
        )
        let decodedControl = try JSONDecoder().decode(
            ProductAnalyticsEventName.self,
            from: Data(#""signup\u0000completed""#.utf8)
        )

        #expect(decodedEmpty.rawValue.isEmpty)
        #expect(decodedControl.rawValue == "signup\u{0000}completed")
    }

    @Test("property key stores raw value and description")
    func propertyKeyRawValueAndDescription() {
        let key = ProductAnalyticsPropertyKey("plan")
        let rawRepresentableKey = ProductAnalyticsPropertyKey(rawValue: "plan")

        #expect(key.rawValue == "plan")
        #expect(rawRepresentableKey == key)
        #expect(key.description == "plan")
    }

    @Test("property key supports equality and hashing")
    func propertyKeyEqualityAndHashing() {
        let keys: Set<ProductAnalyticsPropertyKey> = [
            ProductAnalyticsPropertyKey("plan"),
            ProductAnalyticsPropertyKey("plan"),
            ProductAnalyticsPropertyKey("source")
        ]

        #expect(keys.count == 2)
        #expect(keys.contains(ProductAnalyticsPropertyKey("plan")))
        #expect(keys.contains(ProductAnalyticsPropertyKey("source")))
    }

    @Test("property key encodes and decodes as one string")
    func propertyKeySingleStringCodableShape() throws {
        let key = ProductAnalyticsPropertyKey("plan")

        let encoded = try JSONEncoder().encode(key)
        #expect(String(decoding: encoded, as: UTF8.self) == #""plan""#)

        let decoded = try JSONDecoder().decode(ProductAnalyticsPropertyKey.self, from: encoded)
        #expect(decoded == key)
    }

    @Test("property key construction and decoding do not validate text")
    func propertyKeyConstructionAndDecodingDoNotValidate() throws {
        let empty = ProductAnalyticsPropertyKey("")
        let control = ProductAnalyticsPropertyKey("pl\u{0000}an")

        #expect(empty.rawValue.isEmpty)
        #expect(control.rawValue == "pl\u{0000}an")

        let decodedEmpty = try JSONDecoder().decode(
            ProductAnalyticsPropertyKey.self,
            from: Data(#""""#.utf8)
        )
        let decodedControl = try JSONDecoder().decode(
            ProductAnalyticsPropertyKey.self,
            from: Data(#""pl\u0000an""#.utf8)
        )

        #expect(decodedEmpty.rawValue.isEmpty)
        #expect(decodedControl.rawValue == "pl\u{0000}an")
    }
}
