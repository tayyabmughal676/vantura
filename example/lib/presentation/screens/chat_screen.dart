import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/entities/message.dart';
import '../providers/chat_provider.dart';
import 'package:vantura/core/cancellation_token.dart';
import 'package:vantura/core/index.dart'; // To get TokenUsage if needed
import '../../domain/use_cases/chat_service.dart';
import '../providers/business_providers.dart';
import '../../core/utils/logger.dart';
import 'package:vantura/markdown/markdown.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final ChatService _chatService;
  CancellationToken? _cancellationToken;

  @override
  void initState() {
    super.initState();
    appLogger.logScreenNavigation('app_start', 'chat_screen');
    _chatService = ChatService(
      clientRepository: ref.read(clientRepositoryProvider),
      inventoryRepository: ref.read(inventoryRepositoryProvider),
      invoiceRepository: ref.read(invoiceRepositoryProvider),
      ledgerRepository: ref.read(ledgerRepositoryProvider),
      onNavigate: (screen, params) {
        if (!mounted) return;
        // Handle root path mapping
        final route = screen == 'dashboard' ? '/' : '/$screen';
        context.push(route, extra: params);
        appLogger.info('Agent triggered navigation to $route', tag: 'UI');
      },
      onRefresh: () {
        appLogger.info(
          'Triggering manual provider invalidation from agent action',
          tag: 'UI',
        );
        ref.invalidate(clientsProvider);
        ref.invalidate(inventoryProvider);
        ref.invalidate(invoicesProvider);
        ref.invalidate(ledgerEntriesProvider);
        ref.invalidate(totalIncomeProvider);
        ref.invalidate(totalExpensesProvider);
        ref.invalidate(lowStockCountProvider);
      },
    );
  }

  @override
  void dispose() {
    _chatService.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _cancelGeneration() {
    _cancellationToken?.cancel();
    ref.read(chatProvider.notifier).setLoading(false);
  }

  void _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;
    final userMessage = _controller.text.trim();

    appLogger.logUserAction(
      'send_message',
      parameters: {'message_length': userMessage.length},
    );

    await ref.read(chatProvider.notifier).addMessage(userMessage, true);
    ref.read(chatProvider.notifier).setLoading(true);
    _controller.clear();

    try {
      appLogger.info(
        'Sending message via UI',
        tag: 'UI',
        extra: {'message_length': userMessage.length},
      );

      // Add a placeholder message for the assistant
      await ref.read(chatProvider.notifier).addMessage('', false);
      // Turn off loading indicator now that the placeholder bubble exists.
      // The empty bubble will fill with streamed text.
      ref.read(chatProvider.notifier).setLoading(false);
      _scrollToBottom();

      _cancellationToken = CancellationToken();

      final stream = _chatService.streamMessage(
        userMessage,
        cancellationToken: _cancellationToken,
        onUsage: (usage) {
          ref
              .read(chatProvider.notifier)
              .appendToLastMessage('\n\n_✓ Used ${usage.totalTokens} tokens_');
        },
      );
      bool receivedContent = false;

      await for (final chunk in stream) {
        receivedContent = true;
        ref.read(chatProvider.notifier).appendToLastMessage(chunk);
        _scrollToBottom();
      }

      if (!receivedContent) {
        ref
            .read(chatProvider.notifier)
            .appendToLastMessage('Action completed successfully.');
      }

      appLogger.debug('Streaming response sequence completed', tag: 'UI');
    } catch (e, stackTrace) {
      appLogger.error(
        'Error streaming message via UI',
        tag: 'UI',
        error: e,
        stackTrace: stackTrace,
      );
      ref.read(chatProvider.notifier).appendToLastMessage('\n\nError: $e');
    } finally {
      ref.read(chatProvider.notifier).setLoading(false);
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatAsync = ref.watch(chatProvider);

    return chatAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) =>
          Scaffold(body: Center(child: Text('Error loading chat: $err'))),
      data: (chatState) {
        final messages = chatState.messages;
        final isLoading = chatState.isLoading;

        return Scaffold(
          backgroundColor: const Color(0xFF0F0F13),
          appBar: AppBar(
            leading: context.canPop()
                ? IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white70,
                      size: 20,
                    ),
                    onPressed: () => context.pop(),
                  )
                : null,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vantura AI Assistant',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.greenAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Ready to help',
                      style: GoogleFonts.poppins(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            backgroundColor: const Color(0xFF16161E).withValues(alpha: 0.8),
            flexibleSpace: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(color: Colors.transparent),
              ),
            ),
            elevation: 0,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                color: Colors.white.withValues(alpha: 0.05),
                height: 1,
              ),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16.0),
                  itemCount: messages.length + (isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index < messages.length) {
                      final message = messages[index];
                      return MessageBubble(message: message);
                    } else {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 12.0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.blueAccent,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Agent is processing...',
                                    style: GoogleFonts.inter(
                                      color: Colors.white70,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                ),
              ),
              Container(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(context).padding.bottom + 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF16161E),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: TextField(
                          controller: _controller,
                          enabled: !isLoading,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                          maxLines: 4,
                          minLines: 1,
                          decoration: InputDecoration(
                            hintText: 'Message Vantura AI...',
                            hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.3),
                              fontSize: 15,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                          ),
                          onSubmitted: (_) => isLoading ? null : _sendMessage(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: isLoading ? _cancelGeneration : _sendMessage,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: isLoading
                              ? null
                              : const LinearGradient(
                                  colors: [
                                    Color(0xFF448AFF),
                                    Color(0xFF00E5FF),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                          color: isLoading
                              ? Colors.redAccent.withValues(alpha: 0.2)
                              : null,
                          shape: BoxShape.circle,
                          boxShadow: isLoading
                              ? []
                              : [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF00E5FF,
                                    ).withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                        ),
                        child: Icon(
                          isLoading ? Icons.stop_rounded : Icons.arrow_upward,
                          color: isLoading ? Colors.redAccent : Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class MessageBubble extends StatefulWidget {
  final Message message;

  const MessageBubble({super.key, required this.message});

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUser = widget.message.isUser;
    final timeStr =
        '${widget.message.timestamp.hour.toString().padLeft(2, '0')}:${widget.message.timestamp.minute.toString().padLeft(2, '0')}';

    return FadeTransition(
      opacity: _animation,
      child: Transform.translate(
        offset: Offset(0, (1 - _animation.value) * 10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            crossAxisAlignment: isUser
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              // Avatar row
              Padding(
                padding: EdgeInsets.only(
                  left: isUser ? 0 : 4,
                  right: isUser ? 4 : 0,
                  bottom: 4,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildAvatar(isUser: isUser),
                    const SizedBox(width: 6),
                    Text(
                      isUser ? 'You' : 'Vantura',
                      style: GoogleFonts.inter(
                        color: Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.3),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Message bubble — full width
              Padding(
                padding: EdgeInsets.only(
                  left: isUser ? 40 : 0,
                  right: isUser ? 0 : 40,
                ),
                child: GestureDetector(
                  onLongPress: () {
                    Clipboard.setData(ClipboardData(text: widget.message.text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Message copied to clipboard'),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: isUser
                          ? const LinearGradient(
                              colors: [Color(0xFF2196F3), Color(0xFF00BCD4)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isUser ? null : const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: Radius.circular(isUser ? 20 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: isUser
                          ? null
                          : Border.all(
                              color: Colors.white.withValues(alpha: 0.05),
                            ),
                    ),
                    child: MarkdownText(widget.message.text, isUser: isUser),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar({bool isUser = false}) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isUser
            ? const LinearGradient(colors: [Colors.orange, Colors.red])
            : const LinearGradient(colors: [Colors.blue, Colors.purple]),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4),
        ],
      ),
      child: Center(
        child: Icon(
          isUser ? Icons.person : Icons.auto_awesome,
          size: 16,
          color: Colors.white,
        ),
      ),
    );
  }
}
