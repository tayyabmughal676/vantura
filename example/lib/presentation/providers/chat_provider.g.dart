// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Chat)
final chatProvider = ChatProvider._();

final class ChatProvider extends $AsyncNotifierProvider<Chat, ChatState> {
  ChatProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatHash();

  @$internal
  @override
  Chat create() => Chat();
}

String _$chatHash() => r'1e72e7d485b029dd0244f4cf16bd4a351b75d45d';

abstract class _$Chat extends $AsyncNotifier<ChatState> {
  FutureOr<ChatState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<ChatState>, ChatState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ChatState>, ChatState>,
              AsyncValue<ChatState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
