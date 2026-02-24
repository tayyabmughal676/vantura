# Changelog

All notable changes to this project will be documented in this file.

## [0.2.0] - 2026-02-22

### Added
- Multi-agent architecture via `AgentCoordinator` with handoff capabilities.
- `CancellationToken` for safely aborting requests mid-generation.
- `TokenUsage` object now dynamically included in `VanturaResponse`.
- Error callback hooks (`onToolError`, `onAgentFailure`, `onWarning`) added to `VanturaAgent` for robust exception handling and telemetry.
- Basic mock configuration tests for `VanturaClient`.

### Changed
- `VanturaAgent` now natively accepts `name` and `description` to support deterministic multi-agent routing priorities.

## [0.1.0] - Initial Beta
- Added complete agentic reasoning loop.
- Added `VanturaClient` with SSE streaming and automatic HTTP 429 backoff handling.
- Added abstract `VanturaPersistence` and SQLite implementations.
- Added `ChatProvider` Riverpod architectures.
- Built-in Markdown text rendering natively on Flutter.
