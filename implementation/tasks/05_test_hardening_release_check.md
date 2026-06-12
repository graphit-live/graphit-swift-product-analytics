# Task 05 — Test hardening and release check

If implementation shifts from this task/spec, stop and align before continuing.

## Refs

- `implementation/04_testing_strategy.md`
- `.agents/TESTING_QUALITY.md`
- `.agents/SWIFT_CONCURRENCY_6_3.md`
- `.agents/PACKAGE_RELEASE.md`

## Prereqs

- Implementation feature-complete.

## Implement/check

- Remove low-value duplicate tests.
- Add missing high-signal tests from `implementation/04_testing_strategy.md`.
- Audit public API for accidental deferred types, protocols, helpers, or conveniences.
- Audit imports to ensure `Sources/GraphitProductAnalytics` does not import UI, networking, storage, GraphitCache, OSLog, or vendor packages.
- Audit for accidental globals, singleton state, service locators, property wrappers, macros, dynamic member lookup, provider seams, cache APIs, tasks, actors, locks, streams, continuations, or background work.
- Confirm all public symbols have documentation comments.
- Confirm semantic validation failures map to the intended `ProductAnalyticsError` cases.
- Confirm public error descriptions do not include raw property values.
- Run debug and release builds.

## Quality gates

- deterministic tests;
- no real network;
- no app-owned persistence or filesystem tests beyond ordinary package/test execution;
- tests parallel-safe by default;
- failures assert public behavior;
- no concurrency warnings;
- no public API outside `Spec.md` without explicit alignment;
- no deferred provider/queue/identity/session/lifecycle/storage/UI behavior.

## Verify

```bash
swift package describe
swift build
swift build -c release
swift test
swift test --parallel
```

If `swift test --parallel` exposes a real issue, fix test isolation; do not serialize the whole suite without alignment.

## Definition of done

- Meaningful coverage of handwritten core behavior.
- No concurrency warnings.
- Public API remains exactly seven core types.
- Known untested risks documented as follow-up.
- Test count justified by regression value, not coverage vanity.
