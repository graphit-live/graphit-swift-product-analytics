# Task index

Each task is independently assignable after prerequisites. Required in every task: read `implementation/README.md`, `implementation/00_decisions.md`, relevant design docs, task file, and companion guides. If implementation shifts from task/spec, stop and align before continuing.

Minimal v1 scope: provider-neutral product analytics event vocabulary. No providers, no sending, no queueing, no persistence, no identity, no sessions, no lifecycle tracking, no UI adapters, no globals, no tasks, no actors, no locks, no GraphitCache dependency, no third-party dependencies.

## Vertical order

0. Bootstrap package and API shell.
1. Text values, errors, and validation helpers.
2. Property values and properties.
3. Events, batches, and aggregate Codable.
4. Public docs and README audit.
5. Test hardening and release check.

Why this order: every slice proves user-visible behavior before adding private detail. The implementation should remain small enough to understand in minutes.
