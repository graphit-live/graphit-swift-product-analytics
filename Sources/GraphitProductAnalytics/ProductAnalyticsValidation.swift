import Foundation

enum ProductAnalyticsValidation {
    static let textIdentifierMaximumLength = 256
    static let propertyStringMaximumLength = 8_192
    static let propertyCollectionMaximumElementCount = 100
    static let propertyMaximumDepth = 8
    static let batchMaximumEventCount = 1_000

    static func validateEventName(_ name: ProductAnalyticsEventName) throws {
        try validateTextIdentifier(
            name.rawValue,
            emptyMessage: "event name must not be empty",
            tooLongMessage: "event name must be no longer than \(textIdentifierMaximumLength) characters",
            controlScalarMessage: "event name must not contain Unicode control scalars",
            error: ProductAnalyticsError.invalidEvent
        )
    }

    static func validatePropertyKey(_ key: ProductAnalyticsPropertyKey) throws {
        try validateTextIdentifier(
            key.rawValue,
            emptyMessage: "property key must not be empty",
            tooLongMessage: "property key must be no longer than \(textIdentifierMaximumLength) characters",
            controlScalarMessage: "property key must not contain Unicode control scalars",
            error: ProductAnalyticsError.invalidProperties
        )
    }

    static func validateFiniteOccurrenceDate(_ occurredAt: Date) throws {
        guard occurredAt.timeIntervalSinceReferenceDate.isFinite else {
            throw ProductAnalyticsError.invalidEvent("occurredAt must be finite")
        }
    }

    static func containsControlScalar(_ value: String) -> Bool {
        value.unicodeScalars.contains { scalar in
            scalar.value <= 0x1F || scalar.value == 0x7F || (0x80...0x9F).contains(scalar.value)
        }
    }

    private static func validateTextIdentifier(
        _ value: String,
        emptyMessage: String,
        tooLongMessage: String,
        controlScalarMessage: String,
        error: (String) -> ProductAnalyticsError
    ) throws {
        guard !value.isEmpty else {
            throw error(emptyMessage)
        }

        guard value.count <= textIdentifierMaximumLength else {
            throw error(tooLongMessage)
        }

        guard !containsControlScalar(value) else {
            throw error(controlScalarMessage)
        }
    }
}
