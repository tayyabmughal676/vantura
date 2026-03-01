import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/config/llm_provider_config.dart';
import '../providers/business_providers.dart';

/// A settings screen demonstrating how to configure and swap LLM providers
/// at runtime with Vantura's `VanturaClient`.
///
/// ## What This Demonstrates
/// Vantura's `VanturaClient` uses the OpenAI-compatible API format, which
/// means you can point it at **any** provider that exposes the same endpoint
/// shape — Groq, OpenAI, Together AI, or a local Ollama instance.
///
/// This screen shows developers how to:
/// 1. Define provider profiles via [LlmProviderConfig]
/// 2. Let the user pick a provider at runtime
/// 3. Re-initialize the `VanturaClient` with the new credentials
///
/// > **Note**: In a production app, you would persist the selected provider
/// > to shared_preferences or your .env file and reinitialize `ChatService`
/// > on change. This screen serves as a reference implementation.
class ProviderSettingsScreen extends ConsumerStatefulWidget {
  const ProviderSettingsScreen({super.key});

  @override
  ConsumerState<ProviderSettingsScreen> createState() =>
      _ProviderSettingsScreenState();
}

class _ProviderSettingsScreenState
    extends ConsumerState<ProviderSettingsScreen> {
  String _selectedProvider = 'groq';
  String _selectedModel = 'llama-3.3-70b-versatile';

  final List<LlmProviderConfig> _providers = [
    LlmProviderConfig.groq(apiKey: ''),
    LlmProviderConfig.openai(apiKey: ''),
    LlmProviderConfig.anthropic(apiKey: ''),
    LlmProviderConfig.gemini(apiKey: ''),
    LlmProviderConfig.ollama(),
    LlmProviderConfig.togetherAi(apiKey: ''),
  ];

  LlmProviderConfig get _activeProvider =>
      _providers.firstWhere((p) => p.name == _selectedProvider);

  IconData _providerIcon(String name) {
    switch (name) {
      case 'groq':
        return Icons.bolt;
      case 'openai':
        return Icons.auto_awesome;
      case 'anthropic':
        return Icons.psychology;
      case 'gemini':
        return Icons.diamond;
      case 'ollama':
        return Icons.computer;
      case 'together':
        return Icons.groups;
      default:
        return Icons.cloud;
    }
  }

  Color _providerColor(String name) {
    switch (name) {
      case 'groq':
        return const Color(0xFFF55036);
      case 'openai':
        return const Color(0xFF10A37F);
      case 'anthropic':
        return const Color(0xFFD97706);
      case 'gemini':
        return const Color(0xFF1A73E8);
      case 'ollama':
        return const Color(0xFF7C4DFF);
      case 'together':
        return const Color(0xFF2196F3);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16161E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white70,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'LLM Provider Settings',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header explanation
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.blueAccent.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blueAccent.withValues(alpha: 0.8),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Vantura supports OpenAI-compatible APIs natively through VanturaClient, and provides specialized adapters for Anthropic and Google Gemini.',
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Section title
            Text(
              'SELECT PROVIDER',
              style: GoogleFonts.inter(
                color: Colors.white38,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),

            // Provider cards
            ..._providers.map((provider) => _buildProviderCard(provider)),

            const SizedBox(height: 24),

            // Model selector
            Text(
              'SELECT MODEL',
              style: GoogleFonts.inter(
                color: Colors.white38,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            ..._activeProvider.availableModels.map(
              (model) => _buildModelTile(model),
            ),

            const SizedBox(height: 24),

            // Code preview
            Text(
              'GENERATED CONFIGURATION',
              style: GoogleFonts.inter(
                color: Colors.white38,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            _buildCodePreview(),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderCard(LlmProviderConfig provider) {
    final isSelected = provider.name == _selectedProvider;
    final color = _providerColor(provider.name);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedProvider = provider.name;
            _selectedModel = provider.defaultModel;
          });
          // Update the global ChatService provider
          ref.read(chatServiceProvider).updateProvider(provider);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.1)
                : Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? color.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.08),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _providerIcon(provider.name),
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.displayName,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      provider.description,
                      style: GoogleFonts.inter(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 14),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModelTile(String model) {
    final isSelected = model == _selectedModel;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedModel = model);
          // Re-update the provider with the new model
          ref
              .read(chatServiceProvider)
              .updateProvider(
                _activeProvider,
              ); // Note: _activeProvider uses _selectedModel internally if updated correctly
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? _providerColor(_selectedProvider).withValues(alpha: 0.1)
                : Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? _providerColor(_selectedProvider).withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.06),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: isSelected
                    ? _providerColor(_selectedProvider)
                    : Colors.white30,
                size: 18,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  model,
                  style: GoogleFonts.jetBrainsMono(
                    color: isSelected ? Colors.white : Colors.white60,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (model == _activeProvider.defaultModel)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'default',
                    style: GoogleFonts.inter(
                      color: Colors.white38,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCodePreview() {
    final provider = _activeProvider;
    String clientName = 'VanturaClient';
    if (provider.clientType == LlmClientType.anthropic) {
      clientName = 'AnthropicClient';
    } else if (provider.clientType == LlmClientType.gemini) {
      clientName = 'GeminiClient';
    }

    final code =
        '''
// Vantura ${provider.displayName} Configuration
final client = $clientName(
  apiKey: '${provider.name == 'ollama' ? 'ollama' : 'YOUR_${provider.name.toUpperCase()}_API_KEY'}',
  model: '$_selectedModel',
);''';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text(
        code,
        style: GoogleFonts.jetBrainsMono(
          color: const Color(0xFF00E5FF),
          fontSize: 12,
          height: 1.6,
        ),
      ),
    );
  }
}
