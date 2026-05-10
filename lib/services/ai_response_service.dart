import '../models/ai_stream_event.dart';
import '../models/chat_message.dart';

abstract class AiResponseService {
  Stream<AiStreamEvent> streamResponse({
    required List<ChatMessage> history,
    required String model,
  });
}
