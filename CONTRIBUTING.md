# Contributing to Vantura

Thank you for your interest in contributing to **Vantura** — The Agentic AI Framework for Flutter! Every contribution, whether it's a bug fix, new feature, documentation improvement, or test case, helps make Vantura better for the entire Flutter community.

---

## 📋 Table of Contents

1. [Code of Conduct](#code-of-conduct)
2. [Getting Started](#getting-started)
3. [Project Structure](#project-structure)
4. [Development Workflow](#development-workflow)
5. [Coding Standards](#coding-standards)
6. [Testing](#testing)
7. [Submitting a Pull Request](#submitting-a-pull-request)
8. [Reporting Issues](#reporting-issues)
9. [Feature Requests](#feature-requests)
10. [License](#license)

---

## 📜 Code of Conduct

By participating in this project, you agree to abide by our standards of respectful and constructive communication. We are committed to providing a welcoming and inclusive experience for everyone. In short:

- **Be respectful.** Disagreement is fine; disrespect is not.
- **Be constructive.** Offer solutions, not just criticism.
- **Be collaborative.** We're all working toward the same goal.

---

## 🚀 Getting Started

### Prerequisites

| Tool       | Minimum Version |
|------------|-----------------|
| Dart SDK   | `^3.11.0`       |
| Flutter    | `>=3.22.0`      |
| Git        | Latest stable   |

### Fork & Clone

```bash
# 1. Fork the repository on GitHub

# 2. Clone your fork
git clone https://github.com/<your-username>/vantura.git
cd vantura

# 3. Add the upstream remote
git remote add upstream https://github.com/tayyabmughal676/vantura.git

# 4. Install dependencies
flutter pub get
```

### Verify Your Setup

```bash
# Run the test suite to make sure everything works
flutter test

# Check for lint issues
dart analyze
```

If all tests pass and there are no analysis issues, you're ready to contribute!

---

## 📁 Project Structure

Understanding the codebase layout will help you navigate and contribute effectively:

```
vantura/
├── lib/
│   ├── vantura.dart              # Main library entry point
│   ├── core/
│   │   ├── index.dart            # Core barrel export
│   │   ├── vantura_agent.dart    # ReAct loop agent (run, runStreaming)
│   │   ├── vantura_client.dart   # HTTP client (retry, streaming, rate limits)
│   │   ├── vantura_memory.dart   # Dual-layer memory (short + long-term)
│   │   ├── vantura_state.dart    # ChangeNotifier for UI sync
│   │   ├── vantura_tool.dart     # Abstract tool base class
│   │   ├── vantura_persistence.dart  # Persistence interface
│   │   ├── agent_coordinator.dart    # Multi-agent routing
│   │   ├── cancellation_token.dart   # Request cancellation
│   │   ├── exceptions.dart       # VanturaException hierarchy
│   │   ├── schema_helper.dart    # JSON Schema builder for tools
│   │   └── logger.dart           # Logging with redaction
│   ├── tools/
│   │   ├── index.dart            # Tools barrel export
│   │   ├── calculator_tool.dart
│   │   ├── network_connectivity_tool.dart
│   │   ├── device_info_tool.dart
│   │   └── api_test_tool.dart
│   └── markdown/                 # Zero-dependency Markdown renderer
├── test/
│   ├── core/                     # Unit tests for core modules
│   ├── tools/                    # Unit tests for built-in tools
│   ├── markdown/                 # Unit tests for Markdown renderer
│   └── mocks/                    # Mock classes for testing
├── example/                      # Full Flutter example app (Orbit)
├── docs/                         # Additional design docs & proposals
├── pubspec.yaml
├── CHANGELOG.md
├── LICENSE                       # BSD 3-Clause
└── README.md
```

### Key Modules

| Module | Purpose |
|--------|---------|
| `VanturaAgent` | The core ReAct loop — handles reasoning, tool calls, and streaming |
| `VanturaClient` | HTTP communication with LLM providers (retry, rate-limit handling) |
| `VanturaMemory` | Conversation memory with auto-summarization and persistence |
| `VanturaTool<T>` | Type-safe tool framework with JSON Schema and confirmation flows |
| `AgentCoordinator` | Multi-agent hand-off and routing |
| `VanturaState` | `ChangeNotifier` for real-time UI synchronization |
| `VanturaException` | Structured exception hierarchy for robust error handling |

---

## 🔄 Development Workflow

### 1. Create a Branch

Always work on a feature branch, not `main`:

```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/issue-description
```

**Branch naming conventions:**
- `feature/` — New features or enhancements
- `fix/` — Bug fixes
- `docs/` — Documentation-only changes
- `test/` — Test additions or improvements
- `refactor/` — Code refactoring without behavior change

### 2. Make Your Changes

- Keep commits **small and focused** — one logical change per commit.
- Write clear, descriptive commit messages:

```
feat: add timeout configuration to VanturaClient

- Added `requestTimeout` parameter to VanturaClient constructor
- Applied timeout to both standard and streaming requests
- Added unit tests for timeout behavior
```

We loosely follow [Conventional Commits](https://www.conventionalcommits.org/):

| Prefix     | Usage                                 |
|------------|---------------------------------------|
| `feat:`    | New feature                           |
| `fix:`     | Bug fix                               |
| `docs:`    | Documentation changes                 |
| `test:`    | Adding or updating tests              |
| `refactor:`| Code change without behavior change   |
| `chore:`   | Maintenance tasks (deps, CI, etc.)    |

### 3. Keep Your Branch Up to Date

```bash
git fetch upstream
git rebase upstream/main
```

---

## 🎨 Coding Standards

### Dart Style

- Follow the official [Dart Style Guide](https://dart.dev/effective-dart/style).
- Run `dart analyze` before submitting — **zero warnings** is the goal.
- Use `dart format .` to auto-format your code.

### Documentation

- **All public APIs must have dartdoc comments.** Vantura maintains 100% documentation coverage for public classes and methods.
- Use `///` for documentation comments (not `//`).
- Include code examples in dartdoc where helpful:

```dart
/// Creates a new [VanturaTool] with the given parameters.
///
/// Example:
/// ```dart
/// final tool = MyCustomTool();
/// final result = await tool.execute(args);
/// ```
```

### API Design Principles

- **Non-breaking changes only** on patch/minor versions. Follow [Semantic Versioning](https://semver.org/).
- **Backwards compatibility** — avoid removing or renaming public APIs. Deprecate first.
- **Null safety** — all code must be fully null-safe.
- **Type safety** — prefer strong types over `dynamic` wherever possible.

### Security Considerations

Vantura is a security-conscious framework. When contributing:

- **Never log sensitive data** (API keys, user content) in default logging flows.
- **Always redact** credentials in error messages and stack traces.
- **Validate tool inputs** — tools should handle malformed arguments gracefully.
- **Follow the existing patterns** for anti-SSRF guards and SDK guardrails.

---

## 🧪 Testing

Tests are critical to Vantura's stability. **All PRs must include tests** for new or modified functionality.

### Running Tests

```bash
# Run all tests
flutter test

# Run a specific test file
flutter test test/core/vantura_agent_test.dart

# Run tests with coverage
flutter test --coverage
```

### Test Structure

Tests mirror the `lib/` structure:

```
test/
├── core/
│   ├── vantura_agent_test.dart
│   ├── vantura_client_test.dart
│   ├── vantura_client_extended_test.dart
│   ├── vantura_memory_test.dart
│   ├── vantura_state_test.dart
│   ├── vantura_tool_test.dart
│   ├── schema_helper_test.dart
│   ├── cancellation_token_test.dart
│   ├── agent_coordinator_test.dart
│   └── logger_test.dart
├── tools/
│   └── ...
├── markdown/
│   └── ...
└── mocks/
    └── ...
```

### Writing Good Tests

- **Use descriptive test names** that explain *what* is being tested and the *expected outcome*:

```dart
test('runStreaming throws VanturaCancellationException when token is cancelled', () async {
  // ...
});
```

- **Use mocks** via `mockito` for external dependencies (`VanturaClient`, `VanturaPersistence`).
- **Test edge cases**: empty inputs, null values, timeouts, and error paths.
- **Keep tests independent** — no test should depend on the execution order of others.

### Regenerating Mocks

If you modify interfaces that are mocked in tests, regenerate the mock files:

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## 📬 Submitting a Pull Request

### Before You Submit

- [ ] Your code compiles without errors (`dart analyze` passes cleanly)
- [ ] All existing tests pass (`flutter test`)
- [ ] You've added tests for new functionality
- [ ] All public APIs have dartdoc comments
- [ ] Code is formatted (`dart format .`)
- [ ] You've updated `CHANGELOG.md` under an `[Unreleased]` section
- [ ] Commit messages follow conventional commit format

### PR Process

1. **Push your branch** to your fork:
   ```bash
   git push origin feature/your-feature-name
   ```

2. **Open a Pull Request** against `tayyabmughal676/vantura:main`.

3. **Fill out the PR template:**
   - **What** does this PR do?
   - **Why** is this change needed?
   - **How** was it tested?
   - **Screenshots** (if UI-related changes in the example app)

4. **Respond to review feedback** — maintainers may request changes. Please address all comments before requesting re-review.

### PR Size Guidelines

- **Small PRs are preferred.** They're easier to review and less likely to introduce bugs.
- If your change is large, consider splitting it into multiple PRs with a clear sequence.

---

## 🐛 Reporting Issues

Found a bug? Please [open an issue](https://github.com/tayyabmughal676/vantura/issues/new) with the following information:

### Bug Report Template

```markdown
**Description:**
A clear description of the bug.

**Steps to Reproduce:**
1. Initialize VanturaAgent with...
2. Call runStreaming with...
3. Observe...

**Expected Behavior:**
What you expected to happen.

**Actual Behavior:**
What actually happened.

**Environment:**
- Vantura version: (e.g., 1.0.0)
- Flutter version: (output of `flutter --version`)
- Dart SDK version:
- OS: (e.g., macOS 15, Android 14, iOS 18)
- LLM Provider: (e.g., Groq, OpenAI, Ollama)

**Logs / Stack Trace:**
(paste relevant logs here)
```

---

## 💡 Feature Requests

Have an idea for Vantura? We'd love to hear it! Please [open a feature request](https://github.com/tayyabmughal676/vantura/issues/new) with:

- **Problem Statement:** What limitation or pain point does this address?
- **Proposed Solution:** How would you like it to work? Include API sketches if possible.
- **Alternatives Considered:** Any other approaches you thought about.
- **Use Cases:** Real-world scenarios where this would be valuable.

### Current Roadmap Areas

For context, these are areas we're actively exploring (see `docs/` for proposals):

- Multi-LLM provider support (Anthropic, Gemini, Cohere)
- Enhanced guardrails and content filtering
- Advanced memory strategies
- Performance optimizations (Isolate-based processing)

We especially welcome contributions in these areas!

---

## 📄 License

By contributing to Vantura, you agree that your contributions will be licensed under the [BSD 3-Clause License](LICENSE), the same license that covers the project.

---

## 🙏 Thank You!

Every contribution makes Vantura better. Whether you're fixing a typo, adding a test, or implementing a major feature — **your work matters**. Thank you for being part of the Vantura community!

---

*Built with ❤️ for the Flutter community by [DataDaur AI Consulting](https://datadaur.com).*
