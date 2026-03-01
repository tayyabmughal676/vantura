# Changelog

All notable changes to the Vantura SDK will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] - 2026-02-28

### Added
- **Stable 1.0.0 Release**: First major stable, production-ready version of Vantura.
- **Multi-Provider LLM Support**: Introduced `LlmClient` interface alongside fully native `AnthropicClient` (Claude 3.5/3.7+) and `GeminiClient` (Google Gemini 1.5/2.0+) wrappers, complementing the existing OpenAI-compatible `VanturaClient`.
- **Agent Checkpointing**: Implemented `AgentStateCheckpoint` serialization, allowing `VanturaAgent` to seamlessly `resumeFrom()` interrupted ReAct loops via the `VanturaPersistence` layer.
- **Conditional Confirmation**: Expanded tool logic with dynamic `requiresConfirmationFor(args)`, allowing agents to skip UI confirmation dialogs for low-risk actions automatically.
- **Unified Main Library**: Created `lib/vantura.dart` as the primary standard entry point for the package.
- **VanturaException Hierarchy**: Integrated standardized exception types (`VanturaToolException`, `VanturaCancellationException`, `VanturaIterationException`, etc.) for robust error handling.
- **VanturaClient Transparency**: Added `onRetry` callback to clients for better observability during network retries.

### Changed
- **Hardened Reasoning Loop**: Refactored `VanturaAgent` ReAct loop with improved scoping, iteration control, and standardized failure state updates.
- **Dependency Optimization**: Removed `google_fonts` from the core framework to drastically lighten the compiled application footprint.
- **Documentation Coverage**: Achieved 100% dartdoc coverage for all core public classes and methods.
- **Polished Examples**: Updated `example/example.dart` and the Orbit "Business Management" suite to showcase multi-provider instantiation and dynamic confirmation logic.
- **Lint Optimization**: Resolved all static analysis issues and major pub.dev lint warnings.

## [0.1.3] - 2026-02-24

### Added
- **Official Example App**: Complete Flutter business management app demonstrating client management, inventory tracking, invoicing, financial ledger, and analytics with advanced tool features.
- **Advanced Tool Documentation**: Added sections for confirmation flows, complex parameter schemas (arrays, enums, nested objects), and business logic integration.
- **Enhanced Examples Section**: Expanded README.md Examples section with detailed feature descriptions.

### Changed
- **Documentation Improvements**: Polished code examples, updated example repository URLs, and ensured consistency across all .md files.
- **Package Description**: Extended pubspec.yaml description to meet pub.dev requirements.

### Notes
- Improved package presentation and developer experience with comprehensive examples and documentation.

## [0.1.2] - 2026-02-23

### Added
- **Example**: Created a standard `example/example.dart` and `example/README.md` for better package presentation.
- **Enhanced Intelligence**: Finalized persistence for `tool_calls` and `tool_results` in `VanturaMemory`, enabling consistent multi-turn reasoning.

### Changed
- **Security & Privacy Hardening**:
  - Implemented recursive redaction of sensitive keys (API keys, Authorization tokens) in logs.
  - Added `VanturaLoggerOptions` to disable logging of sensitive content (prompts/responses) by default.
  - Added `VanturaLogLevel` to filter SDK logs.
  - Hardened `ApiTestTool` with hostname blacklisting (SSRF protection) and strict output truncation.
  - Added SDK-level guardrails to prevent instruction overriding and prompt injection.
- **Robustness**: 
  - Added execution timeouts to `VanturaTool` (default 30s) to prevent agent hangs.
  - Implemented robust JSON extraction to handle LLM conversational filler and markdown blocks.
  - Added `finishReason` to `VanturaResponse` for better observability.
- **Dependency Updates**: Modernized constraints for `connectivity_plus` (v7) and `device_info_plus` (v12).
- **Documentation**: SIGNIFICANT improvements to API documentation (dartdoc) and a completely rewritten high-end README guide.
- **Project Structure**: Moved repository marketing assets to root and cleaned up `.pubignore`.

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
