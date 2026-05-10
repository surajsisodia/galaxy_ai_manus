enum AiStreamEventType { deltaText, done, error }

class AiStreamEvent {
  const AiStreamEvent._({required this.type, this.text, this.errorMessage});

  factory AiStreamEvent.deltaText(String text) {
    return AiStreamEvent._(type: AiStreamEventType.deltaText, text: text);
  }

  factory AiStreamEvent.done() {
    return const AiStreamEvent._(type: AiStreamEventType.done);
  }

  factory AiStreamEvent.error(String message) {
    return AiStreamEvent._(
      type: AiStreamEventType.error,
      errorMessage: message,
    );
  }

  final AiStreamEventType type;
  final String? text;
  final String? errorMessage;
}
