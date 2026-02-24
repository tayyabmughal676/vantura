import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/message.dart';

part 'chat_provider.g.dart';

class ChatState {
  final List<Message> messages;
  final bool isLoading;

  ChatState({this.messages = const [], this.isLoading = false});

  ChatState copyWith({List<Message>? messages, bool? isLoading}) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

@riverpod
class Chat extends _$Chat {
  @override
  Future<ChatState> build() async {
    return ChatState(messages: []);
  }

  Future<void> addMessage(String text, bool isUser) async {
    // Update state
    state = AsyncData(
      state.value!.copyWith(
        messages: [
          ...state.value!.messages,
          Message(text: text, isUser: isUser),
        ],
      ),
    );
  }

  void setLoading(bool loading) {
    if (state is AsyncData) {
      state = AsyncData(state.value!.copyWith(isLoading: loading));
    }
  }

  void appendToLastMessage(String chunk) {
    if (state.value == null || state.value!.messages.isEmpty) return;

    final messages = List<Message>.from(state.value!.messages);
    final lastMessage = messages.last;

    if (lastMessage.isUser) return;

    messages[messages.length - 1] = lastMessage.copyWith(
      text: lastMessage.text + chunk,
    );

    state = AsyncData(state.value!.copyWith(messages: messages));
  }

  Future<void> clearMessages() async {
    state = AsyncData(ChatState());
  }
}
