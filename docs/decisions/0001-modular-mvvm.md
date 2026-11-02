# ADR 0001: Feature modules with MVVM and Observation

- **Status:** Accepted
- **Date:** 2026-11-02

## Context

A growing app with several engineers needs clear ownership boundaries, fast incremental builds and tests that don't need the whole app. The architecture also needs to be easy for a new team member to read in their first week.

## Decision

1. Split the code into Swift Package Manager targets: one core module, one data module, one design system and one module per feature.
2. Use MVVM with `@Observable` view models marked `@MainActor`.
3. Features depend on protocols in `HopCore`. The app target is the only place that creates concrete implementations.

## Alternatives considered

- **Single app target:** it's simple at first, but every change rebuilds everything, and nothing stops features from depending on each other.
- **The Composable Architecture (TCA):** it gives strong guarantees around state and effects, but it adds a third-party dependency and a learning curve. For a team of mixed experience, plain SwiftUI was the better default. It could be adopted later inside a single feature.

## Consequences

- The package manifest makes dependency rules visible and enforced by the compiler.
- View models are tested with small protocol stubs, with no UI and no simulator needed.
- Adding a feature means adding a target and wiring it in `AppDependencies`. That's a little more setup than adding a folder.
