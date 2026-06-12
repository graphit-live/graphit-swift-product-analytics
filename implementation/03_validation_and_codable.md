# Validation and Codable

## Text validation

Event names and property keys validate when used by aggregate values, not when leaf values are constructed or decoded.

Validation rules:

- non-empty;
- length <= 256 characters by `String.count`;
- no Unicode control scalars.

Control scalars include C0 controls, DEL, and C1 controls:

```text
scalar.value <= 0x1F || scalar.value == 0x7F || (0x80...0x9F).contains(scalar.value)
```

Do not normalize, trim, lowercase, Unicode-normalize, or otherwise rewrite caller data.

## Property validation

`ProductAnalyticsProperties.init` validates the whole property tree.

Limits:

| Rule | Limit |
| --- | ---: |
| properties per object | 100 |
| array elements per array | 100 |
| string value length (`String.count`) | 8,192 characters |
| nested array/object depth | 8 |

Depth counting starts at each root property value being validated. The top-level `ProductAnalyticsProperties` container itself does not add depth. A scalar has depth 0. Each array or object layer inside a value increments depth by 1.

Examples:

```swift
.string("x")                       // depth 0
.array([.string("x")])             // depth 1
.object(.empty)                     // depth 1 when used as a property value
```

Eight nested array/object layers from a root property value are valid. Nine nested array/object layers are invalid.

Numeric rules:

- `.number` accepts only finite `Double` values;
- NaN, positive infinity, and negative infinity are invalid;
- callers that need exact decimal text, arbitrary-precision numbers, or large integer identifiers should use `.string(...)`.

Privacy rule: validation errors must not include raw property values.

## Validation flow

### `ProductAnalyticsPropertyValue`

- Enum case construction is nonvalidating.
- Encoding validates the value as a root property value before writing JSON-shaped data.
- Decoding validates the decoded value as a root property value before returning it.

### `ProductAnalyticsProperties`

Construction and decoding should:

1. reject object width > 100;
2. validate every property key;
3. validate every property value from root depth 0;
4. store the original key/value pairs after validation succeeds.

`ProductAnalyticsProperties.empty` should be a prevalidated empty value.

### `ProductAnalyticsEvent`

Construction and decoding should:

1. validate event name;
2. validate `occurredAt.timeIntervalSinceReferenceDate.isFinite`;
3. accept already validated `ProductAnalyticsProperties`, or build/validate properties through the dictionary convenience initializer.

### `ProductAnalyticsBatch`

Construction and decoding should validate event count:

- `events.count >= 1`;
- `events.count <= 1_000`.

## Codable shapes

### Event name and property key

Encode/decode as a single-value string:

```json
"signup_completed"
```

Do not use synthesized `{ "rawValue": ... }` object shapes.

### Property value

Encode/decode as JSON-shaped data:

```json
null
true
19.99
"pro"
["seat", "storage"]
{ "source": "paywall" }
```

Decoding is type-preserving and non-coercing:

- JSON strings decode as `.string(...)`, even if the content looks numeric or equals `"NaN"`, `"Infinity"`, or `"-Infinity"`;
- JSON numbers decode as `.number(Double)` when finite and representable;
- JSON booleans decode as `.bool(...)`;
- JSON null decodes as `.null`;
- JSON arrays decode recursively;
- JSON objects decode as `.object(ProductAnalyticsProperties)`.

### Properties

Encode/decode as a JSON object keyed by each `ProductAnalyticsPropertyKey.rawValue`:

```json
{
  "plan": "pro",
  "amount": 19.99,
  "is_trial": false,
  "coupon": null
}
```

Duplicate raw JSON object keys are not a supported semantic. Decoder behavior for duplicates is outside the public contract.

### Event

Encode/decode as an object with `name`, `occurredAt`, and `properties`:

```json
{
  "name": "signup_completed",
  "occurredAt": "encoder-defined Date representation",
  "properties": {
    "plan": "pro"
  }
}
```

`occurredAt` intentionally uses the encoder/decoder's `Date` strategy.

### Batch

Encode/decode as an object with `events`:

```json
{
  "events": [
    {
      "name": "signup_completed",
      "occurredAt": "encoder-defined Date representation",
      "properties": {}
    }
  ]
}
```

## Error mapping

Package-owned semantic validation should throw:

- `ProductAnalyticsError.invalidProperties` for invalid property keys, values, widths, string lengths, number finiteness, and nesting depth;
- `ProductAnalyticsError.invalidEvent` for invalid event names or occurrence times;
- `ProductAnalyticsError.invalidBatch` for invalid batch counts.

Structural decoding failures, such as a wrong top-level shape or type mismatch, may remain `DecodingError`.

Tests should assert error cases and sanitized behavior. Avoid over-specifying exact message wording unless the wording itself is the behavior being protected.
