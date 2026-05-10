import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ai_stream_event.dart';
import '../models/chat_header.dart';
import '../models/chat_message.dart';
import '../models/chat_role.dart';
import '../services/ai_response_service.dart';
import '../services/chat_storage_service.dart';
import '../services/gemini_service.dart';
import '../utils/app_config.dart';
import '../utils/app_constants.dart';

class ChatState {
  const ChatState({
    this.messages = const [],
    this.isStreaming = false,
    this.streamError,
    this.currentInput = '',
  });

  final List<ChatMessage> messages;
  final bool isStreaming;
  final String? streamError;
  final String currentInput;

  static const _noValue = Object();

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isStreaming,
    Object? streamError = _noValue,
    String? currentInput,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isStreaming: isStreaming ?? this.isStreaming,
      streamError: identical(streamError, _noValue)
          ? this.streamError
          : streamError as String?,
      currentInput: currentInput ?? this.currentInput,
    );
  }
}

final chatStorageProvider = Provider<ChatStorageService>((ref) {
  return ChatStorageService();
});

final chatHeadersProvider = FutureProvider<List<ChatHeader>>((ref) async {
  final storage = ref.watch(chatStorageProvider);
  return storage.loadHeaders();
});

final aiResponseServiceProvider = Provider<AiResponseService>((ref) {
  if (AppConfig.shouldUseMockGemini) {
    return GeminiService.mock();
  }
  return GeminiService(apiKey: AppConfig.geminiApiKey);
});

class ChatNotifier extends FamilyNotifier<ChatState, String> {
  late final AiResponseService _aiService;
  late final ChatStorageService _storage;
  StreamSubscription<AiStreamEvent>? _streamSubscription;
  int _idCounter = 0;
  late final String _chatId;

  @override
  ChatState build(String arg) {
    _chatId = arg;
    _aiService = ref.read(aiResponseServiceProvider);
    _storage = ref.read(chatStorageProvider);
    ref.onDispose(() {
      _streamSubscription?.cancel();
    });

    final loaded = _storage.loadMessages(_chatId);
    _idCounter = loaded.messages.length;
    if (loaded.hadStreamingMessages && loaded.messages.isNotEmpty) {
      Future<void>.microtask(() => _persistMessages(loaded.messages));
    }

    return ChatState(messages: loaded.messages);
  }

  void updateCurrentInput(String value) {
    if (state.currentInput == value) return;
    state = state.copyWith(currentInput: value);
  }

  Future<void> sendCurrentInput(String model) async {
    final text = state.currentInput.trim();
    if (text.isEmpty) return;
    await sendUserMessage(text: text, model: model);
  }

  Future<void> sendUserMessage({
    required String text,
    required String model,
    bool appendUserMessage = true,
  }) async {
    if (state.isStreaming) return;
    final normalizedText = text.trim();
    if (normalizedText.isEmpty) return;

    var nextMessages = [...state.messages];
    if (appendUserMessage) {
      nextMessages = [
        ...nextMessages,
        ChatMessage(
          id: _nextMessageId(),
          role: ChatRole.user,
          text: normalizedText,
          createdAt: DateTime.now(),
        ),
      ];
    }

    nextMessages = [
      ...nextMessages,
      ChatMessage(
        id: _nextMessageId(),
        role: ChatRole.assistant,
        text: '',
        createdAt: DateTime.now(),
        isStreaming: true,
      ),
    ];

    state = state.copyWith(
      streamError: null,
      currentInput: '',
      isStreaming: true,
      messages: nextMessages,
    );
    await _persistMessages(nextMessages);

    await _streamSubscription?.cancel();
    final history = _buildRequestHistory(nextMessages);
    _streamSubscription = _aiService
        .streamResponse(history: history, model: model)
        .listen(
          _onStreamEvent,
          onError: (error) {
            state = state.copyWith(streamError: 'Streaming failed: $error');
            _finalizeStreaming();
          },
          onDone: () {
            if (state.isStreaming) {
              _finalizeStreaming();
            }
          },
        );
  }

  Future<void> retryLastRequest(String model) async {
    if (state.isStreaming) return;
    final lastUserText = _lastUserMessageText(state.messages);
    if (lastUserText == null) return;

    state = state.copyWith(streamError: null);
    await sendUserMessage(
      text: lastUserText,
      model: model,
      appendUserMessage: false,
    );
  }

  Future<void> cancelStreaming() async {
    if (!state.isStreaming) return;

    await _streamSubscription?.cancel();
    _streamSubscription = null;
    state = state.copyWith(streamError: 'Generation canceled.');
    _finalizeStreaming();
  }

  void _onStreamEvent(AiStreamEvent event) {
    switch (event.type) {
      case AiStreamEventType.deltaText:
        _appendAssistantDelta(event.text ?? '');
      case AiStreamEventType.done:
        _finalizeStreaming();
      case AiStreamEventType.error:
        state = state.copyWith(
          streamError: event.errorMessage ?? 'Streaming failed.',
        );
        _finalizeStreaming();
    }
  }

  void _appendAssistantDelta(String delta) {
    if (delta.isEmpty || state.messages.isEmpty) return;
    final lastIndex = state.messages.length - 1;
    final last = state.messages[lastIndex];
    if (last.role != ChatRole.assistant) return;

    final updatedMessages = [...state.messages];
    updatedMessages[lastIndex] = last.copyWith(
      text: '${last.text}$delta',
      isStreaming: true,
    );
    state = state.copyWith(messages: updatedMessages);
    _persistMessages(updatedMessages);
  }

  void _finalizeStreaming() {
    _streamSubscription?.cancel();
    _streamSubscription = null;

    var updatedMessages = [...state.messages];
    final streamError = state.streamError;

    if (updatedMessages.isNotEmpty) {
      final lastIndex = updatedMessages.length - 1;
      final last = updatedMessages[lastIndex];
      if (last.role == ChatRole.assistant) {
        if (last.text.trim().isEmpty && streamError != null) {
          updatedMessages = updatedMessages..removeLast();
        } else {
          updatedMessages[lastIndex] = last.copyWith(isStreaming: false);
        }
      }
    }

    state = state.copyWith(isStreaming: false, messages: updatedMessages);
    _persistMessages(updatedMessages);
  }

  Future<void> _persistMessages(List<ChatMessage> messages) async {
    if (messages.isEmpty) return;
    await _storage.saveChat(chatId: _chatId, messages: messages);
    ref.invalidate(chatHeadersProvider);
  }

  List<ChatMessage> _buildRequestHistory(List<ChatMessage> sourceMessages) {
    final filtered = sourceMessages
        .where(
          (message) =>
              message.text.trim().isNotEmpty &&
              (message.role == ChatRole.user || !message.isStreaming),
        )
        .toList();

    final maxMessages = AppConstants.geminiMaxTurns * 2;
    if (filtered.length <= maxMessages) {
      return filtered;
    }
    return filtered.sublist(filtered.length - maxMessages);
  }

  String? _lastUserMessageText(List<ChatMessage> sourceMessages) {
    for (var i = sourceMessages.length - 1; i >= 0; i--) {
      if (sourceMessages[i].role == ChatRole.user) {
        return sourceMessages[i].text;
      }
    }
    return null;
  }

  String _nextMessageId() {
    _idCounter += 1;
    return '${DateTime.now().microsecondsSinceEpoch}_$_idCounter';
  }
}

final chatProvider = NotifierProvider.family<ChatNotifier, ChatState, String>(
  ChatNotifier.new,
);
