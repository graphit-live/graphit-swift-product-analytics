# GraphitProductAnalytics implementation plan

Purpose: implement the minimal v1 described by `Spec.md` Draft 4. V1 is a provider-neutral product analytics event vocabulary. It defines validated immutable event values and batches; it does not send, queue, flush, persist, identify users, track sessions, observe app lifecycle, or integrate with vendors.

## Source order

1. `AGENTS.md`: engineering standard.
2. Relevant `.agents/*` companion guides.
3. `Spec.md`: product/API contract.
4. `implementation/*.md`: implementation notes.
5. `implementation/tasks/*.md`: vertical implementation slices.

## Local docs map

- `00_decisions.md`: locked minimal-v1 scope and implementation posture.
- `01_package_layout.md`: SwiftPM manifest, source tree, imports, and access-control rules.
- `02_public_api_contract.md`: exact seven-type public API contract.
- `03_validation_and_codable.md`: semantic validation, depth rules, error mapping, and custom Codable shapes.
- `04_testing_strategy.md`: high-signal Swift Testing plan and verification commands.
- `05_deferred_features.md`: non-goals that must not leak into v1.
- `tasks/*.md`: behavior-first implementation slices.

## Global task protocol

Before task:

- read this file, `00_decisions.md`, relevant design docs, task file, and companion guides;
- check `swift --version`; require Swift 6.3.x;
- check `git status --short`; do not overwrite unrelated work.

During task:

- implement one vertical behavior slice at a time;
- add public documentation comments as public symbols are introduced;
- keep the public v1 surface to exactly the seven types in `Spec.md`;
- keep `Sources/GraphitProductAnalytics` free of UI, networking, storage, GraphitCache, OSLog, and vendor imports;
- do not add providers, transport, queues, persistence, sessions, identity, lifecycle observers, globals, service locators, property wrappers, macros, dynamic member lookup, tasks, actors, locks, or third-party dependencies;
- if reality shifts from task/spec: stop, document the delta, and align before coding through it.

After task:

- run verification commands listed in the task;
- leave explicit follow-up notes in planning docs when needed; do not hide TODOs in code.

## Why small vertical slices

GraphitProductAnalytics v1 is intentionally closer to GraphitFeatureFlags than GraphitCache. It should be implemented as plain values, deterministic validation, custom Codable boundaries, and tests. The plan proves public behavior in narrow slices without introducing storage architecture, concurrency owners, provider seams, or speculative abstractions.
