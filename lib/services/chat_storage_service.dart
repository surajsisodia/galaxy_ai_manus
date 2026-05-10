import 'package:hive/hive.dart';

import '../models/chat_header.dart';
import '../models/chat_message.dart';
import '../models/chat_role.dart';
import '../utils/app_constants.dart';

class LoadedChatMessages {
  const LoadedChatMessages({
    required this.messages,
    required this.hadStreamingMessages,
  });

  final List<ChatMessage> messages;
  final bool hadStreamingMessages;
}

class ChatStorageService {
  Box<dynamic> get _headersBox =>
      Hive.box<dynamic>(AppConstants.hiveChatHeadersBox);
  Box<dynamic> get _messagesBox =>
      Hive.box<dynamic>(AppConstants.hiveChatMessagesBox);

  List<ChatHeader> loadHeaders() {
    final headers =
        _headersBox.values
            .whereType<Map>()
            .map((map) => ChatHeader.fromMap(Map<String, dynamic>.from(map)))
            .where((header) => header.id.trim().isNotEmpty)
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return headers;
  }

  LoadedChatMessages loadMessages(String chatId) {
    final rawValue = _messagesBox.get(chatId);
    if (rawValue is! List) {
      return const LoadedChatMessages(
        messages: <ChatMessage>[],
        hadStreamingMessages: false,
      );
    }

    var hadStreamingMessages = false;
    final messages = rawValue.whereType<Map>().map((item) {
      final message = ChatMessage.fromMap(Map<String, dynamic>.from(item));
      if (message.isStreaming) {
        hadStreamingMessages = true;
        return message.copyWith(isStreaming: false);
      }
      return message;
    }).toList();

    return LoadedChatMessages(
      messages: messages,
      hadStreamingMessages: hadStreamingMessages,
    );
  }

  Future<void> saveChat({
    required String chatId,
    required List<ChatMessage> messages,
  }) async {
    if (messages.isEmpty) {
      return;
    }

    final serialized = messages.map((message) => message.toMap()).toList();
    final header = _deriveHeader(chatId: chatId, messages: messages);

    await _messagesBox.put(chatId, serialized);
    await _headersBox.put(chatId, header.toMap());
  }

  ChatHeader _deriveHeader({
    required String chatId,
    required List<ChatMessage> messages,
  }) {
    final createdAt = messages.first.createdAt;
    final updatedAt = messages.last.createdAt;

    String title = AppConstants.untitledChatFallback;
    for (final message in messages) {
      if (message.role != ChatRole.user) continue;
      final normalized = _normalize(message.text);
      if (normalized.isEmpty) continue;
      title = _truncate(normalized, AppConstants.chatTitleMaxLength);
      break;
    }

    String preview = '';
    for (var i = messages.length - 1; i >= 0; i--) {
      final normalized = _normalize(messages[i].text);
      if (normalized.isEmpty) continue;
      preview = _truncate(normalized, AppConstants.chatPreviewMaxLength);
      break;
    }

    return ChatHeader(
      id: chatId,
      title: title,
      preview: preview,
      createdAt: createdAt,
      updatedAt: updatedAt,
      messageCount: messages.length,
    );
  }

  String _normalize(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _truncate(String value, int maxLength) {
    if (value.length <= maxLength) return value;
    return '${value.substring(0, maxLength - 1)}…';
  }
}
