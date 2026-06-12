# Task 02 — Property values and properties

If implementation shifts from this task/spec, stop and align before continuing.

## Refs

- `implementation/02_public_api_contract.md`
- `implementation/03_validation_and_codable.md`
- `.agents/PUBLIC_API_DESIGN.md`
- `.agents/TESTING_QUALITY.md`
- `.agents/PERFORMANCE_MEMORY.md`

## Prereqs

- Tasks 00–01 done.

## Implement

Full behavior for:

- `ProductAnalyticsPropertyValue` enum cases, `Hashable`, `Sendable`, and JSON-shaped `Codable`;
- standalone property value encoding validation as a root property value;
- standalone property value decoding validation as a root property value;
- `ProductAnalyticsProperties.empty`;
- `ProductAnalyticsProperties.values`;
- throwing `ProductAnalyticsProperties.init(_:)`;
- property subscript lookup;
- properties object-shaped `Codable` keyed by `ProductAnalyticsPropertyKey.rawValue`;
- recursive validation for keys, numbers, strings, arrays, objects, widths, and depth.

## Required decisions

- `ProductAnalyticsPropertyValue` case construction is nonvalidating.
- Encoding an invalid enum-constructed property value throws `ProductAnalyticsError.invalidProperties`.
- Decoding invalid property values/properties throws `ProductAnalyticsError.invalidProperties` for package-owned semantic failures.
- JSON decoding is type-preserving and non-coercing.
- The top-level `ProductAnalyticsProperties` container does not add to root property-value depth.
- Error descriptions do not include raw property values.

## Do not implement

- event-name validation behavior beyond existing helpers;
- full event and batch Codable behavior;
- provider-specific reserved keys;
- property normalization, trimming, key remapping, flattening, null dropping, or string/number coercion;
- raw `[String: Any]` APIs;
- extra public conveniences.

## Tests

Add Swift Testing coverage for:

- property value encoding/decoding for null, bool, number, string, array, and object;
- string-vs-number preservation, including `"123"`, `"NaN"`, and `123`;
- invalid enum-constructed values fail during encoding;
- properties accept empty and valid values;
- subscript lookup;
- invalid property keys;
- non-finite numbers;
- too-long strings;
- too-wide arrays and objects;
- too-deep nesting, including the exact depth-8 valid/depth-9 invalid boundary;
- properties Codable object shape and decode-time semantic validation;
- sanitized property validation errors.

## Verify

```bash
swift build
swift test --filter PropertyValue
swift test --filter PropertiesValidation
swift test --filter Codable
```

## Definition of done

- Property values and properties match spec.
- Recursive validation is deterministic and context-aware.
- Codable boundaries validate as specified.
- No raw property values appear in public error descriptions.
