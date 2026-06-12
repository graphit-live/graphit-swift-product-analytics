# Task 01 — Text values, errors, and validation helpers

If implementation shifts from this task/spec, stop and align before continuing.

## Refs

- `implementation/02_public_api_contract.md`
- `implementation/03_validation_and_codable.md`
- `.agents/PUBLIC_API_DESIGN.md`
- `.agents/TESTING_QUALITY.md`

## Prereqs

- Task 00 done.

## Implement

Full behavior for:

- `ProductAnalyticsEventName` raw value, description, `RawRepresentable`, `Hashable`, `Sendable`, and single-string `Codable`;
- `ProductAnalyticsPropertyKey` raw value, description, `RawRepresentable`, `Hashable`, `Sendable`, and single-string `Codable`;
- `ProductAnalyticsError` cases and sanitized `description` behavior;
- internal/private `ProductAnalyticsValidation` helpers for:
  - event-name validation;
  - property-key validation;
  - control-scalar detection;
  - finite date validation;
  - shared limit constants.

## Required decisions

- Event name construction and decoding do not validate.
- Property key construction and decoding do not validate.
- Codable shape for both text values is a single JSON string, not a raw-value object.
- No normalization is performed.
- Error descriptions must not include raw property values.

## Do not implement

- recursive property value validation beyond shared constants/helper stubs;
- full `ProductAnalyticsProperties` behavior;
- full `ProductAnalyticsEvent` or `ProductAnalyticsBatch` behavior;
- provider/loading/caching APIs;
- `ExpressibleByStringLiteral`;
- extra public conveniences.

## Tests

Add Swift Testing coverage for:

- event name raw value, `RawRepresentable`, equality, hashing, description;
- property key raw value, `RawRepresentable`, equality, hashing, description;
- text value Codable single-string shape;
- construction/decoding does not validate empty or control-character strings;
- error description categories and sanitized message behavior where possible.

Full aggregate validation tests happen in later tasks when public aggregate APIs are implemented.

## Verify

```bash
swift build
swift test --filter TextValue
swift test --filter Error
```

## Definition of done

- Text value behavior matches spec.
- Compact Codable shapes match spec.
- No semantic validation occurs during text value construction or decoding.
- No extra public API added.
