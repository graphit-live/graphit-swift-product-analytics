# Locked decisions — minimal event vocabulary v1

Change process: if implementation conflicts with this file or `Spec.md`, stop and align. Do not silently drift.

## Product scope

- Implement `Spec.md` Draft 4 minimal event vocabulary v1.
- V1 is a pure provider-neutral product analytics value layer.
- Core describes validated event names, property keys, JSON-shaped property values, immutable properties, immutable events, and ordered batches.
- Apps and future provider packages own sending, queueing, flushing, persistence, retry/backoff, privacy policy, identity, sessions, lifecycle hooks, transport, and vendor mapping.
- Official product focus: iOS 18+.
- Package also supports macOS 15+ for SwiftPM builds/tests and Mac app use.
- No Linux support claim in v1.
- No third-party Swift packages.
- Core target may import Foundation for `Date` and Codable/date behavior. Do not import UI, networking, storage, OSLog, GraphitCache, or vendor SDKs.
- No GraphitCache dependency in v1.

## Public surface

The v1 public SDK surface is exactly these seven public types:

1. `ProductAnalyticsEventName`
2. `ProductAnalyticsPropertyKey`
3. `ProductAnalyticsPropertyValue`
4. `ProductAnalyticsProperties`
5. `ProductAnalyticsEvent`
6. `ProductAnalyticsBatch`
7. `ProductAnalyticsError`

Do not add extra public types, public protocols, public helpers, public testing products, public adapters, or public convenience namespaces unless the v1 contract is explicitly re-reviewed.

Do not add `ExpressibleByStringLiteral` for event names or property keys in v1. Apps should define explicit schema constants.

## Package

- SwiftPM source package.
- Swift tools version: 6.3.
- Swift language mode: 6.
- Public product: `GraphitProductAnalytics` only.
- Targets: `GraphitProductAnalytics`, `GraphitProductAnalyticsTests`.
- Platforms: `.iOS(.v18)`, `.macOS(.v15)`.
- No linker settings.
- No resources required in v1.

## Implementation posture

Build in small vertical behavior slices:

1. package and compile-ready public API shell;
2. text values, package error, and validation helpers;
3. property values, properties, recursive validation, and Codable;
4. events, batches, validation, and Codable;
5. documentation and README audit;
6. release hardening.

Prefer plain structs/enums, private helpers, and direct validation. Do not build abstraction layers before behavior needs them.

## Validation boundaries

Leaf construction is intentionally nonvalidating:

- `ProductAnalyticsEventName.init` and decoding do not validate;
- `ProductAnalyticsPropertyKey.init` and decoding do not validate;
- `ProductAnalyticsPropertyValue` enum case construction does not validate.

Aggregate and interchange boundaries validate:

- `ProductAnalyticsPropertyValue` encoding/decoding validates the value as a root property value;
- `ProductAnalyticsProperties.init` and decoding validate keys and the full property tree;
- `ProductAnalyticsEvent.init` and decoding validate event name, occurrence time, and properties;
- `ProductAnalyticsBatch.init` and decoding validate batch count.

No validation path normalizes or rewrites caller data. Do not trim, lowercase, Unicode-normalize, coerce numbers/strings, flatten objects, drop nulls, or rename keys.

## Error policy

- `ProductAnalyticsError.invalidEvent` covers invalid event names and occurrence times.
- `ProductAnalyticsError.invalidProperties` covers invalid property keys, values, widths, string lengths, number finiteness, and nesting depth.
- `ProductAnalyticsError.invalidBatch` covers empty or too-large batches.
- Error messages should be useful but sanitized.
- Error descriptions may mention event names and property keys when useful, but must not include raw property values.
- Structural decoding failures may remain `DecodingError`.

## Explicit non-behavior

Core does not:

- record, capture, track, send, enqueue, flush, drain, or shut down analytics;
- define provider protocols, provider registries, analytics clients, sinks, or recorders;
- import or wrap PostHog, Google Analytics, Amplitude, Segment, Mixpanel, or any vendor;
- use `URLSession`, networking, filesystem persistence, SQLite, GraphitCache, queues, retry/backoff, or storage policies;
- own user IDs, anonymous IDs, distinct IDs, devices, sessions, groups, consent state, or super properties;
- observe app lifecycle, foreground/background transitions, screens, sessions, or automatic metadata;
- create tasks, actors, locks, streams, continuations, or background work;
- provide globals, process-wide mutable configuration, service locators, task-local dependencies, property wrappers, macros, or dynamic member lookup;
- log, emit metrics, or expose instrumentation hooks in v1.
