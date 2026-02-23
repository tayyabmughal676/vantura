# Changelog

All notable changes to the Vantura SDK will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [0.1.3] - 2026-02-23

### Changed
- **Dependency Updates**: Modernized dependency constraints for `connectivity_plus` and `device_info_plus` to support latest major versions (7.0.0 and 12.0.0+), resolving pub.dev recommendations.
- **Documentation**: Minor link fixes in README.

## [0.1.2] - 2026-02-23

### Changed
- **Security & Privacy Hardening**:
  - Implemented automatic redaction of sensitive keys (API keys, Authorization tokens) in logs.
  - Added `VanturaLoggerOptions` to disable logging of sensitive content (prompts/responses) by default.
  - Hardened `ApiTestTool` with hostname blacklisting and strict output truncation to prevent SSRF and PII leakage.
  - Added SDK-level guardrails to `VanturaAgent` to prevent instruction overriding and prompt injection.
- **Robustness Improvements**:
  - Added execution timeouts to `VanturaTool` (default 30s) to prevent agent hangs.
  - Implemented robust JSON decoding in `VanturaAgent` to handle malformed or markdown-wrapped tool calls from LLMs.
  - Added `finishReason` to `VanturaResponse` for better observability.
- **Intelligence & Memory**:
  - Enhanced `VanturaMemory` and `VanturaPersistence` to persist tool calls and results, enabling consistent multi-turn reasoning across sessions.
- Moved `MARKETING.md` resources to root `vantura_marketing_assets.md`.
- Updated documentation and project structure for pub.dev compatibility.

## [0.1.1] - 2026-02-22

### Changed
- **Documentation Upgrade**: Completely rewritten "marketing-first" README with premium visuals, use-cases, and comparison tables.
- **Package Polishing**: Standardized LICENSE to BSD 3-Clause and added `.pubignore` for a leaner package size.
- **Bug Fixes**: Regenerated test mocks to ensure internal test suite compatibility.

## [0.1.0] - 2026-02-22

### Added
- **Core Agent Loop**: `VanturaAgent` with ReAct-style reasoning (up to 10 iterations), supporting both `run()` (blocking) and `runStreaming()` (SSE token-by-token).
- **HTTP Client**: `VanturaClient` with connection pooling, 3-retry exponential backoff, and automatic HTTP 429 rate-limit handling.
- **Memory System**: `VanturaMemory` with short-term (recent messages) and long-term (LLM-summarized) memory, plus automatic pruning.
- **Persistence Interface**: Abstract `VanturaPersistence` — plug in any storage backend (SQLite, Hive, Firestore, etc.) without SDK modification.
- **Tool Framework**: Generic `VanturaTool<T>` base class with type-safe argument parsing, JSON Schema definitions via `SchemaHelper`, and human-in-the-loop confirmation support.
- **Built-in Tools**: `CalculatorTool`, `NetworkConnectivityTool`, `DeviceInfoTool`, `ApiTestTool`.
- **Multi-Agent Coordination**: `AgentCoordinator` class for routing conversations between specialist agents with automatic `transfer_to_agent` tool injection.
- **Request Cancellation**: `CancellationToken` for aborting generation mid-request at both the HTTP and reasoning-loop levels.
- **Token Usage Tracking**: `TokenUsage` object returned in `VanturaResponse` with `promptTokens`, `completionTokens`, and `totalTokens`.
- **Error Callbacks**: `onToolError`, `onAgentFailure`, and `onWarning` hooks on `VanturaAgent` for structured error reporting and telemetry.
- **UI State Management**: `VanturaState` (`ChangeNotifier`) for syncing agent status (`isRunning`, `currentStep`, `errorMessage`) with Flutter UI.
- **Markdown Renderer**: Zero-dependency `MarkdownText` Flutter widget supporting headers, bold, italic, inline code, bullet lists, and horizontal rules.
- **Logger Interface**: Abstract `VanturaLogger` with a default `SimpleVanturaLogger` (colored console output).

### Notes
- First public release as an extracted, standalone Flutter package.
- Compatible with any OpenAI-compatible API provider (Groq, OpenAI, Ollama, Together AI, etc.).
