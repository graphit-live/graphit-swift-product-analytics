# Task 04 — Public docs and README audit

If implementation shifts from this task/spec, stop and align before continuing.

## Refs

- `implementation/02_public_api_contract.md`
- `implementation/05_deferred_features.md`
- `.agents/PUBLIC_API_DESIGN.md`
- `.agents/PACKAGE_RELEASE.md`

## Prereqs

- Public API behavior mostly complete.

## Implement

- Audit/add documentation comments for every public type and public member.
- Create or update root `README.md` with minimal user docs.
- Compile-check examples where practical through tests.

## README must mention

- Swift 6.3.x and Swift language mode 6.
- iOS 18+ primary support and macOS 15+ package support.
- No Linux support claim in v1.
- Core is a provider-neutral event value vocabulary.
- The exact v1 responsibility: event names, property keys, JSON-shaped property values, validated properties, validated events, ordered batches, and Codable values.
- Core does not send, queue, flush, retry, persist, identify users, track sessions, observe lifecycle, track screens, or integrate with vendors.
- No providers, networking, GraphitCache dependency, storage, UI adapters, globals, property wrappers, macros, or dynamic member lookup.
- Why `ProductAnalyticsEventName` and `ProductAnalyticsPropertyKey` are dedicated types instead of raw strings.
- Property values are JSON-shaped and not `[String: Any]`.
- `occurredAt` is explicit and core does not read the clock.
- Codable guidance for app/provider-owned queues, files, caches, or tests.
- Batch values are ordered values only, not queues.
- Provider composition guidance with future provider-owned concrete APIs clearly marked as outside core v1.
- Privacy notes for event names, property keys, and property values.
- Deferred features/non-goals.

## Do not implement

- provider APIs;
- GraphitCache integration;
- bundle/file loading helpers;
- queueing or flushing;
- observation or UI adapters;
- instrumentation/events;
- public testing helper product;
- public APIs beyond the seven v1 types.

## Verify

```bash
swift build
swift test
```

## Definition of done

- Every public symbol has a documentation comment.
- README matches implemented API and minimal-v1 decisions.
- Examples do not show deferred APIs as core APIs.
- README examples are covered by compile tests where practical.
