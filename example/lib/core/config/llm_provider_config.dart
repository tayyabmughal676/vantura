enum LlmClientType {
  vantura, // OpenAI-compatible (OpenAI, Groq, Ollama, etc.)
  anthropic, // Native Anthropic Claude
  gemini, // Native Google Gemini
}

/// Defines a pre-configured LLM provider profile that can be selected
/// at runtime. This demonstrates how to dynamically swap `LlmClient`
/// implementations in a real-world application.
class LlmProviderConfig {
  final String name;
  final String displayName;
  final String apiKey;
  final String baseUrl;
  final String defaultModel;
  final List<String> availableModels;
  final String description;
  final LlmClientType clientType;
  final String? selectedModel;

  const LlmProviderConfig({
    required this.name,
    required this.displayName,
    required this.apiKey,
    required this.baseUrl,
    required this.defaultModel,
    required this.availableModels,
    required this.description,
    this.clientType = LlmClientType.vantura,
    this.selectedModel,
  });

  LlmProviderConfig copyWith({
    String? name,
    String? displayName,
    String? apiKey,
    String? baseUrl,
    String? defaultModel,
    List<String>? availableModels,
    String? description,
    LlmClientType? clientType,
    String? selectedModel,
  }) {
    return LlmProviderConfig(
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      apiKey: apiKey ?? this.apiKey,
      baseUrl: baseUrl ?? this.baseUrl,
      defaultModel: defaultModel ?? this.defaultModel,
      availableModels: availableModels ?? this.availableModels,
      description: description ?? this.description,
      clientType: clientType ?? this.clientType,
      selectedModel: selectedModel ?? this.selectedModel,
    );
  }

  /// Pre-configured Groq provider (default for the example app).
  factory LlmProviderConfig.groq({required String apiKey}) {
    return LlmProviderConfig(
      name: 'groq',
      displayName: 'Groq',
      apiKey: apiKey,
      baseUrl: 'https://api.groq.com/openai/v1/chat/completions',
      defaultModel: 'llama-3.3-70b-versatile',
      availableModels: [
        'llama-3.3-70b-versatile',
        'llama-3.1-8b-instant',
        'mixtral-8x7b-32768',
        'gemma2-9b-it',
      ],
      description: 'Ultra-fast inference with Groq LPU (free tier available)',
    );
  }

  /// Pre-configured OpenAI provider.
  factory LlmProviderConfig.openai({required String apiKey}) {
    return LlmProviderConfig(
      name: 'openai',
      displayName: 'OpenAI',
      apiKey: apiKey,
      baseUrl: 'https://api.openai.com/v1/chat/completions',
      defaultModel: 'gpt-4o-mini',
      availableModels: ['gpt-4o', 'gpt-4o-mini', 'gpt-4-turbo', 'o3-mini'],
      description: 'Industry-standard LLM provider by OpenAI',
    );
  }

  /// Pre-configured Anthropic provider.
  factory LlmProviderConfig.anthropic({required String apiKey}) {
    return LlmProviderConfig(
      name: 'anthropic',
      displayName: 'Anthropic',
      apiKey: apiKey,
      baseUrl: 'https://api.anthropic.com/v1/messages',
      defaultModel: 'claude-3-7-sonnet-latest',
      availableModels: [
        'claude-3-7-sonnet-latest',
        'claude-3-5-sonnet-latest',
        'claude-3-5-haiku-latest',
        'claude-3-opus-20240229',
      ],
      clientType: LlmClientType.anthropic,
      description: 'Advanced reasoning and tool-use with Claude 3.5/3.7',
    );
  }

  /// Pre-configured Google Gemini provider.
  factory LlmProviderConfig.gemini({required String apiKey}) {
    return LlmProviderConfig(
      name: 'gemini',
      displayName: 'Google Gemini',
      apiKey: apiKey,
      baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
      defaultModel: 'gemini-1.5-flash-latest',
      availableModels: [
        'gemini-1.5-pro-latest',
        'gemini-1.5-flash-latest',
        'gemini-2.0-flash-exp',
      ],
      clientType: LlmClientType.gemini,
      description: 'Multimodal intelligence on Google’s platform',
    );
  }

  /// Pre-configured local Ollama instance.
  factory LlmProviderConfig.ollama({String host = 'http://localhost:11434'}) {
    return LlmProviderConfig(
      name: 'ollama',
      displayName: 'Ollama (Local)',
      apiKey: 'ollama',
      baseUrl: '$host/v1/chat/completions',
      defaultModel: 'llama3.2',
      availableModels: ['llama3.2', 'llama3.1', 'mistral', 'codellama', 'phi3'],
      description: 'Run models locally with Ollama — fully private',
    );
  }

  /// Pre-configured Together AI provider.
  factory LlmProviderConfig.togetherAi({required String apiKey}) {
    return LlmProviderConfig(
      name: 'together',
      displayName: 'Together AI',
      apiKey: apiKey,
      baseUrl: 'https://api.together.xyz/v1/chat/completions',
      defaultModel: 'meta-llama/Meta-Llama-3.1-70B-Instruct-Turbo',
      availableModels: [
        'meta-llama/Meta-Llama-3.1-70B-Instruct-Turbo',
        'meta-llama/Meta-Llama-3.1-8B-Instruct-Turbo',
        'mistralai/Mixtral-8x7B-Instruct-v0.1',
      ],
      description: 'Affordable inference for open-source models',
    );
  }
}
