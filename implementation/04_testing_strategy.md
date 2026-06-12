# Testing strategy

Goal: prove behavior that callers and maintainers care about. Avoid vanity coverage and implementation trivia.

## Frameworks

- Use Swift Testing for v1 behavior tests.
- Tests may import Foundation for `JSONEncoder`, `JSONDecoder`, `Data`, and `Date`.
- No XCTest required in v1 unless a future benchmark lane is added.
- No sleeps, clocks, temp directories, mock frameworks, provider fakes, network tests, or public testing product are required for core v1.

## Suites

### Text value tests

Cover:

- `ProductAnalyticsEventName` raw value, `RawRepresentable`, equality, hashing, description;
- `ProductAnalyticsPropertyKey` raw value, `RawRepresentable`, equality, hashing, description;
- event name and property key Codable single-string shape;
- construction/decoding does not validate empty or control-character strings;
- aggregate construction rejects invalid text where appropriate.

### Property value Codable tests

Cover:

- encoding/decoding for `.null`, `.bool`, `.number`, `.string`, `.array`, and `.object`;
- string-vs-number preservation for values such as `"123"`, `"NaN"`, and `123`;
- root-value validation during encoding of enum-constructed invalid values;
- decoding semantic validation for too-long strings, too-wide arrays/objects, too-deep nesting, and invalid numbers when representable by the decoder;
- equality and hashing for representative values.

### Properties validation tests

Cover:

- empty properties;
- valid properties with scalar, array, and object values;
- subscript lookup;
- invalid property keys;
- non-finite numbers;
- too-long string values;
- too-wide arrays and objects;
- too-deep nesting;
- Codable object shape;
- semantic validation during decoding.

### Event validation tests

Cover:

- valid event construction with explicit date and empty properties;
- dictionary convenience initializer validates properties;
- invalid empty/control/too-long event names;
- non-finite dates;
- Codable object shape;
- semantic validation during decoding;
- no hidden clock read in public API examples.

### Batch validation tests

Cover:

- single-event initializer;
- multi-event initializer preserves order;
- empty batch rejection;
- too-large batch rejection;
- Codable object shape;
- semantic validation during decoding.

### Error and README example tests

Cover:

- public error descriptions are useful and sanitized;
- raw property values do not appear in validation error descriptions;
- README quick-start examples compile;
- provider composition examples, if present, do not require non-v1 core APIs.

## Minimal verification commands

```bash
swift package describe
swift build
swift build -c release
swift test
```

Useful focused filters after tests exist:

```bash
swift test --filter TextValue
swift test --filter PropertyValue
swift test --filter PropertiesValidation
swift test --filter EventValidation
swift test --filter BatchValidation
swift test --filter Codable
```

## Quality bar per test

- Proves public behavior, not private implementation steps.
- Deterministic input and assertions.
- No real network or filesystem dependency beyond normal package/test execution and in-memory `Data` encoding/decoding.
- Parallel-safe by default.
- Clear failure assertions.
- Avoid exact error-message assertions unless message wording is intentionally part of a test scenario.

## Do not add

- protocols only for mocks;
- broad mock framework;
- provider fakes;
- temp-directory helpers;
- clocks;
- network tests;
- persistence tests for app-owned storage;
- tests for hidden private representation details.
