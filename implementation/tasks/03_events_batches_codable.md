# Task 03 — Events, batches, and aggregate Codable

If implementation shifts from this task/spec, stop and align before continuing.

## Refs

- `implementation/02_public_api_contract.md`
- `implementation/03_validation_and_codable.md`
- `.agents/PUBLIC_API_DESIGN.md`
- `.agents/TESTING_QUALITY.md`

## Prereqs

- Tasks 00–02 done.

## Implement

Full behavior for:

- `ProductAnalyticsEvent` stored properties;
- `ProductAnalyticsEvent.init(name:occurredAt:properties:)`;
- `ProductAnalyticsEvent.init(name:occurredAt:properties:)` dictionary convenience initializer;
- event validation for name and finite occurrence time;
- event object-shaped `Codable` with `name`, `occurredAt`, and `properties`;
- `ProductAnalyticsBatch.events`;
- throwing array batch initializer;
- nonthrowing single-event batch initializer;
- batch count validation;
- batch object-shaped `Codable` with `events`.

## Required decisions

- `occurredAt` is explicit. Core does not read the clock or default to `Date.now`.
- `occurredAt.timeIntervalSinceReferenceDate` must be finite.
- Old and future timestamps are valid.
- Event decoding validates semantic rules.
- Batch decoding validates event count.
- Batch order is preserved.
- Core does not deduplicate, merge, split, persist, queue, or deliver events.

## Do not implement

- `record`, `capture`, `track`, `send`, `enqueue`, `flush`, or `shutdown` APIs;
- provider protocols or clients;
- identity/session/context models;
- lifecycle/screen tracking;
- storage or GraphitCache integration;
- async APIs, tasks, actors, locks, streams, or cancellation behavior;
- Date formatting policy beyond the encoder/decoder's normal Date strategy.

## Tests

Add Swift Testing coverage for:

- valid event construction with explicit date and empty properties;
- valid event construction with dictionary properties;
- dictionary convenience initializer validates properties;
- invalid empty/control/too-long event names;
- non-finite dates;
- event Codable object shape and decode-time semantic validation;
- single-event batch initializer;
- multi-event batch preserves order;
- empty and too-large batch rejection;
- batch Codable object shape and decode-time count validation;
- relevant error categories.

## Verify

```bash
swift build
swift test --filter EventValidation
swift test --filter BatchValidation
swift test --filter Codable
swift test
```

## Definition of done

- Events and batches match `Spec.md`.
- Aggregate Codable behavior validates semantic rules.
- No delivery, queueing, provider, identity, lifecycle, storage, or async behavior added.
