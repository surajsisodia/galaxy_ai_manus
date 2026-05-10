import 'chat_role.dart';

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
    this.isStreaming = false,
  });

  final String id;
  final ChatRole role;
  final String text;
  final DateTime createdAt;
  final bool isStreaming;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'role': role.storageValue,
      'text': text,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isStreaming': isStreaming,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    final createdAtRaw = map['createdAt'];
    final createdAt = switch (createdAtRaw) {
      int value => DateTime.fromMillisecondsSinceEpoch(value),
      String value => DateTime.tryParse(value) ?? DateTime.now(),
      _ => DateTime.now(),
    };

    return ChatMessage(
      id: (map['id'] as String?)?.trim().isNotEmpty == true
          ? map['id'] as String
          : '${DateTime.now().microsecondsSinceEpoch}',
      role: chatRoleFromStorage(map['role'] as String?),
      text: (map['text'] as String?) ?? '',
      createdAt: createdAt,
      isStreaming: (map['isStreaming'] as bool?) ?? false,
    );
  }

  ChatMessage copyWith({
    String? id,
    ChatRole? role,
    String? text,
    DateTime? createdAt,
    bool? isStreaming,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }
}
