# Deferred features and non-goals

Do not add placeholders for deferred features in v1. Public API should stay exactly the seven core types.

## Providers and transport

Deferred:

- provider protocol;
- `ProductAnalyticsProvider`, `ProductAnalyticsRecorder`, `AnalyticsClient`, `AnalyticsSink`, or similar abstractions;
- provider registry;
- PostHog integration;
- Google Analytics integration;
- Amplitude, Segment, Mixpanel, or custom backend providers;
- network transport;
- request/response models;
- retry/backoff;
- provider error mapping.

Reason: core v1 is the shared value vocabulary. Provider packages should expose concrete APIs and prove common shapes before core defines abstractions.

## Queueing, batching policy, and offline delivery

Deferred:

- in-memory queue;
- durable offline queue;
- GraphitCache queue adapter;
- file/database queue;
- flush timers;
- app lifecycle flush;
- background tasks;
- retry/backoff;
- deduplication;
- delivery receipts;
- queue size or byte-size policy;
- compression or encryption.

Reason: queueing policy depends on app lifecycle, privacy, storage limits, provider limits, and whether enqueue success means local acceptance or delivery.

## Identity and user state

Deferred:

- user ID;
- anonymous ID;
- distinct ID;
- device ID;
- session ID;
- group/account ID;
- identify/alias/logout/reset calls;
- super properties;
- persistent user context;
- consent state.

Reason: identity semantics differ across providers and privacy policies. Core does not reserve property keys or own mutable identity.

## Automatic collection

Deferred:

- app lifecycle events;
- session start/end;
- screen view tracking;
- crash/error tracking;
- device metadata;
- OS/app version metadata;
- attribution/campaign capture;
- revenue/ecommerce helpers.

Reason: automatic collection has privacy, volume, lifecycle, and provider-specific consequences. V1 remains explicit.

## UI and syntax sugar

Deferred:

- SwiftUI/UIKit/AppKit adapters;
- Observation or `ObservableObject` stores;
- property wrappers;
- macros;
- dynamic member lookup;
- global environment values;
- string-literal event names or property keys.

Reason: explicit event values are boring and hard to misuse.

## Advanced schema support

Deferred:

- generated event schema APIs;
- macro-generated event/property constants;
- typed event-specific builders;
- typed property schemas;
- compile-time required property checks;
- event catalog documentation generation.

Reason: apps can define simple constants today. Schema generation can be useful later but should not become the main human-facing API by accident.

## Observability and logging

Deferred:

- public event sink;
- OSLog adapter;
- metrics hooks;
- signposts;
- debug logging.

Reason: core v1 performs no I/O or async work and should not log property values. Provider packages can add sanitized observability around transport and queue behavior.

## Consequences for implementation

- Do not add placeholder public provider, queue, identity, session, storage, UI, schema, or instrumentation APIs.
- Do not add no-op recorder/sink protocols just for future shape.
- Do not import GraphitCache, URLSession, OSLog, SwiftUI, UIKit, AppKit, Combine, Observation, or vendor SDKs.
- Keep deferred examples in README clearly marked as future/provider-owned guidance, not core APIs.
