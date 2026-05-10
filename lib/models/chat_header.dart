class ChatHeader {
  const ChatHeader({
    required this.id,
    required this.title,
    required this.preview,
    required this.createdAt,
    required this.updatedAt,
    required this.messageCount,
  });

  final String id;
  final String title;
  final String preview;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int messageCount;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'preview': preview,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'messageCount': messageCount,
    };
  }

  factory ChatHeader.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic raw) {
      if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
      if (raw is String) return DateTime.tryParse(raw) ?? DateTime.now();
      return DateTime.now();
    }

    return ChatHeader(
      id: (map['id'] as String?) ?? '',
      title: (map['title'] as String?) ?? '',
      preview: (map['preview'] as String?) ?? '',
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
      messageCount: (map['messageCount'] as int?) ?? 0,
    );
  }
}
