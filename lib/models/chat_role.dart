enum ChatRole { user, assistant, system }

extension ChatRoleGeminiMapper on ChatRole {
  String get geminiRole {
    switch (this) {
      case ChatRole.assistant:
        return 'model';
      case ChatRole.user:
      case ChatRole.system:
        return 'user';
    }
  }
}

extension ChatRoleStorageMapper on ChatRole {
  String get storageValue => name;
}

ChatRole chatRoleFromStorage(String? rawValue) {
  if (rawValue == null) return ChatRole.user;
  return ChatRole.values.firstWhere(
    (role) => role.name == rawValue,
    orElse: () => ChatRole.user,
  );
}
