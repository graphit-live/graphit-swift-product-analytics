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

    static func validateBatchEvents(_ events: [ProductAnalyticsEvent]) throws {
        guard !events.isEmpty else {
            throw ProductAnalyticsError.invalidBatch("batch must contain at least one event")
        }

        guard events.count <= batchMaximumEventCount else {
            throw ProductAnalyticsError.invalidBatch(
                "batch must contain no more than \(batchMaximumEventCount) events"
            )
        }
    }

    static func validateProperties(
        _ values: [ProductAnalyticsPropertyKey: ProductAnalyticsPropertyValue]
    ) throws {
        try validatePropertyObject(values, valueDepth: 0)
    }

    static func validatePropertyValue(_ value: ProductAnalyticsPropertyValue) throws {
        try validatePropertyValue(value, currentDepth: 0)
    }

    static func containsControlScalar(_ value: String) -> Bool {
        value.unicodeScalars.contains { scalar in
            scalar.value <= 0x1F || scalar.value == 0x7F || (0x80...0x9F).contains(scalar.value)
        }
    }

    private static func validatePropertyObject(
        _ values: [ProductAnalyticsPropertyKey: ProductAnalyticsPropertyValue],
        valueDepth: Int
    ) throws {
        guard values.count <= propertyCollectionMaximumElementCount else {
            throw ProductAnalyticsError.invalidProperties(
                "property objects must contain no more than \(propertyCollectionMaximumElementCount) properties"
            )
        }

        for key in values.keys.sorted(by: { $0.rawValue < $1.rawValue }) {
            try validatePropertyKey(key)
            if let value = values[key] {
                try validatePropertyValue(value, currentDepth: valueDepth)
            }
        }
    }

    private static func validatePropertyValue(
        _ value: ProductAnalyticsPropertyValue,
        currentDepth: Int
    ) throws {
        switch value {
        case .null, .bool:
            return

        case .number(let number):
            guard number.isFinite else {
                throw ProductAnalyticsError.invalidProperties("number property values must be finite")
            }

        case .string(let string):
            guard string.count <= propertyStringMaximumLength else {
                throw ProductAnalyticsError.invalidProperties(
                    "string property values must be no longer than \(propertyStringMaximumLength) characters"
                )
            }

        case .array(let values):
            let arrayDepth = currentDepth + 1
            try validatePropertyContainerDepth(arrayDepth)

            guard values.count <= propertyCollectionMaximumElementCount else {
                throw ProductAnalyticsError.invalidProperties(
                    "property arrays must contain no more than \(propertyCollectionMaximumElementCount) elements"
                )
            }

            for element in values {
                try validatePropertyValue(element, currentDepth: arrayDepth)
            }

        case .object(let properties):
            let objectDepth = currentDepth + 1
            try validatePropertyContainerDepth(objectDepth)
            try validatePropertyObject(properties.values, valueDepth: objectDepth)
        }
    }

    private static func validatePropertyContainerDepth(_ depth: Int) throws {
        guard depth <= propertyMaximumDepth else {
            throw ProductAnalyticsError.invalidProperties(
                "nested property arrays and objects must not exceed depth \(propertyMaximumDepth)"
            )
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
