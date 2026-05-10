import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:dio/dio.dart';

import '../models/ai_stream_event.dart';
import '../models/chat_message.dart';
import '../models/chat_role.dart';
import '../utils/app_constants.dart';
import 'ai_response_service.dart';

class GeminiStreamHttpResponse {
  const GeminiStreamHttpResponse({
    required this.statusCode,
    this.stream,
    this.body,
  });

  final int statusCode;
  final Stream<List<int>>? stream;
  final String? body;
}

typedef GeminiStreamExecutor =
    Future<GeminiStreamHttpResponse> Function({
      required Uri uri,
      required Map<String, dynamic> payload,
      required Duration timeout,
    });

class GeminiService implements AiResponseService {
  GeminiService({
    required String apiKey,
    Dio? dio,
    Uri? baseUri,
    GeminiStreamExecutor? streamExecutor,
  }) : _apiKey = apiKey.trim(),
       _dio = dio ?? Dio(),
       _baseUri = baseUri ?? Uri.parse(AppConstants.geminiBaseUrl),
       _timeout = const Duration(
         seconds: AppConstants.geminiRequestTimeoutSeconds,
       ),
       _streamExecutor = streamExecutor;

  factory GeminiService.mock({
    Duration chunkDelay = const Duration(milliseconds: 10),
  }) {
    return GeminiService(
      apiKey: 'mock-gemini-key',
      streamExecutor:
          ({required payload, required timeout, required uri}) async {
            final responseText = _buildMockAssistantText(payload);
            return GeminiStreamHttpResponse(
              statusCode: 200,
              stream: _buildMockSseByteStream(
                fullText: responseText,
                chunkDelay: chunkDelay,
              ),
            );
          },
    );
  }

  final String _apiKey;
  final Dio _dio;
  final Uri _baseUri;
  final Duration _timeout;
  final GeminiStreamExecutor? _streamExecutor;

  @override
  Stream<AiStreamEvent> streamResponse({
    required List<ChatMessage> history,
    required String model,
  }) async* {
    if (_apiKey.isEmpty) {
      yield AiStreamEvent.error(
        'Missing Gemini API key. Pass --dart-define=GEMINI_API_KEY=...',
      );
      return;
    }

    final endpoint = _buildEndpoint(model);
    final payload = {
      'contents': history
          .map(
            (message) => {
              'role': message.role.geminiRole,
              'parts': [
                {'text': message.text},
              ],
            },
          )
          .toList(),
    };

    GeminiStreamHttpResponse response;
    try {
      response =
          await (_streamExecutor?.call(
                uri: endpoint,
                payload: payload,
                timeout: _timeout,
              ) ??
              _sendWithDio(uri: endpoint, payload: payload, timeout: _timeout));
    } on TimeoutException {
      yield AiStreamEvent.error('Gemini request timed out.');
      return;
    } on DioException catch (error) {
      yield AiStreamEvent.error('Gemini request failed: ${error.message}');
      return;
    } on Object catch (error) {
      yield AiStreamEvent.error('Gemini request failed: $error');
      return;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      yield AiStreamEvent.error(
        _extractApiErrorMessage(response.statusCode, response.body ?? ''),
      );
      return;
    }

    final byteStream = response.stream;
    if (byteStream == null) {
      yield AiStreamEvent.error('Gemini stream payload missing.');
      return;
    }

    bool emittedDone = false;
    try {
      final lines = byteStream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      StringBuffer? eventBuffer;

      await for (final line in lines) {
        if (line.startsWith(':')) {
          continue;
        }

        if (line.isEmpty) {
          if (eventBuffer != null && eventBuffer.isNotEmpty) {
            final processed = _processSseData(
              eventBuffer.toString(),
              onDone: () => emittedDone = true,
            );
            if (processed != null) {
              yield processed;
            }
            eventBuffer = null;
          }
          continue;
        }

        if (!line.startsWith('data:')) {
          continue;
        }

        final value = line.substring(5).trimLeft();
        eventBuffer ??= StringBuffer();
        if (eventBuffer.isNotEmpty) {
          eventBuffer.writeln();
        }
        eventBuffer.write(value);
      }

      if (eventBuffer != null && eventBuffer.isNotEmpty) {
        final processed = _processSseData(
          eventBuffer.toString(),
          onDone: () => emittedDone = true,
        );
        if (processed != null) {
          yield processed;
        }
      }

      if (!emittedDone) {
        yield AiStreamEvent.done();
      }
    } on FormatException {
      yield AiStreamEvent.error('Malformed Gemini stream payload.');
    } on TimeoutException {
      yield AiStreamEvent.error('Gemini stream timed out.');
    } on Object catch (error) {
      yield AiStreamEvent.error('Gemini stream failed: $error');
    }
  }

  Future<GeminiStreamHttpResponse> _sendWithDio({
    required Uri uri,
    required Map<String, dynamic> payload,
    required Duration timeout,
  }) async {
    final response = await _dio.postUri<ResponseBody>(
      uri,
      data: jsonEncode(payload),
      options: Options(
        headers: const {'Content-Type': 'application/json'},
        responseType: ResponseType.stream,
        validateStatus: (_) => true,
        sendTimeout: timeout,
        receiveTimeout: timeout,
      ),
    );

    final statusCode = response.statusCode ?? 500;
    final bodyStream = response.data?.stream;
    final normalizedStream = bodyStream?.map((chunk) => chunk.toList());

    if (statusCode < 200 || statusCode >= 300) {
      final body = bodyStream == null
          ? ''
          : await normalizedStream!.transform(utf8.decoder).join();
      return GeminiStreamHttpResponse(statusCode: statusCode, body: body);
    }

    return GeminiStreamHttpResponse(
      statusCode: statusCode,
      stream: normalizedStream,
    );
  }

  Uri _buildEndpoint(String model) {
    final basePath = _baseUri.path.endsWith('/')
        ? _baseUri.path.substring(0, _baseUri.path.length - 1)
        : _baseUri.path;

    final selectedModel = model.trim().isEmpty
        ? AppConstants.geminiDefaultModel
        : model.trim();

    return _baseUri.replace(
      path: '$basePath/models/$selectedModel:streamGenerateContent',
      queryParameters: {'alt': 'sse', 'key': _apiKey},
    );
  }

  AiStreamEvent? _processSseData(
    String data, {
    required void Function() onDone,
  }) {
    final payload = data.trim();
    if (payload.isEmpty) return null;
    if (payload == '[DONE]') {
      onDone();
      return AiStreamEvent.done();
    }

    final decoded = jsonDecode(payload);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Unexpected SSE payload shape.');
    }

    final chunks = _extractTextChunks(decoded);
    if (chunks.isEmpty) return null;
    return AiStreamEvent.deltaText(chunks.join());
  }

  List<String> _extractTextChunks(Map<String, dynamic> payload) {
    final candidates = payload['candidates'];
    if (candidates is! List) {
      return const [];
    }

    final chunks = <String>[];
    for (final candidate in candidates) {
      if (candidate is! Map<String, dynamic>) continue;
      final content = candidate['content'];
      if (content is! Map<String, dynamic>) continue;
      final parts = content['parts'];
      if (parts is! List) continue;

      for (final part in parts) {
        if (part is! Map<String, dynamic>) continue;
        final text = part['text'];
        if (text is String && text.isNotEmpty) {
          chunks.add(text);
        }
      }
    }
    return chunks;
  }

  String _extractApiErrorMessage(int statusCode, String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final error = decoded['error'];
        if (error is Map<String, dynamic>) {
          final message = error['message'];
          if (message is String && message.isNotEmpty) {
            return 'Gemini API error ($statusCode): $message';
          }
        }
      }
    } on Object {
      // fall through
    }
    return 'Gemini API error ($statusCode).';
  }
}

Stream<List<int>> _buildMockSseByteStream({
  required String fullText,
  required Duration chunkDelay,
}) async* {
  final semanticChunks = _splitMockText(fullText);
  final sseEvents = <String>[
    ': keep-alive',
    '',
    for (final chunk in semanticChunks)
      'data: ${jsonEncode({
        'candidates': [
          {
            'content': {
              'parts': [
                {'text': chunk},
              ],
              'role': 'model',
            },
          },
        ],
      })}\n',
    'data: [DONE]\n',
  ];

  final ssePayload = sseEvents.join('\n');
  final bytes = utf8.encode(ssePayload);
  const packetSizes = [7, 13, 5, 17, 9, 21, 6, 11];
  var cursor = 0;
  var packetIndex = 0;

  while (cursor < bytes.length) {
    final packetSize = packetSizes[packetIndex % packetSizes.length];
    final end = math.min(cursor + packetSize, bytes.length);
    yield bytes.sublist(cursor, end);
    cursor = end;
    packetIndex += 1;
    await Future<void>.delayed(chunkDelay);
  }
}

List<String> _splitMockText(String text) {
  if (text.isEmpty) {
    return const ['I am ready.'];
  }

  // Keep original markdown formatting intact (line breaks, indentation, fences).
  // We only slice by index to simulate streaming chunks.
  const chunkSizes = [14, 9, 22, 7, 18, 11, 16];
  final chunks = <String>[];
  var cursor = 0;
  var sizeIndex = 0;

  while (cursor < text.length) {
    final size = chunkSizes[sizeIndex % chunkSizes.length];
    final end = math.min(cursor + size, text.length);
    chunks.add(text.substring(cursor, end));
    cursor = end;
    sizeIndex += 1;
  }

  return chunks;
}

String _buildMockAssistantText(Map<String, dynamic> payload) {
  final prompt = _extractLatestUserPrompt(payload);
  if (prompt.isEmpty) {
    return '''
# Mock Gemini Stream

Hello. This is a **mocked streaming response**.

## What You Can Test
- **Incremental tokens** as text appears chunk by chunk
- *Markdown-like formatting* in UI
- Retry, cancel, and error states in your chat flow

## Sample Snippet
```dart
final state = ref.watch(chatProvider);
```

> This output is generated locally to simulate Gemini SSE behavior.
''';
  }

  final normalized = prompt.toLowerCase();
  if (normalized.contains('hello') || normalized.contains('hi')) {
    return '''
## Hey there

Hi. This is a **mocked Gemini stream**, and I can help with your next task.

### Quick Actions
- Ask for a **feature plan**
- Ask for a *UI polish checklist*
- Ask for a step-by-step implementation breakdown

### Example Ask
`Help me build a streaming chat UI with Riverpod and go_router.`

I will respond with a structured answer so your stream rendering feels realistic.
''';
  }
  if (normalized.contains('flutter')) {
    return '''
# Flutter Implementation Outline

Great prompt. Here is a **long-form mock response** to simulate realistic streaming.

## Architecture
- **Presentation Layer**: screens + reusable widgets
- **State Layer**: Riverpod `Notifier` for chat/session state
- **Data Layer**: API service with SSE parsing

## Suggested Milestones
1. Build chat message model and role enum.
2. Wire `ChatNotifier` for send/cancel/retry.
3. Integrate streaming parser and append deltas.
4. Add markdown rendering and code block styling.
5. Handle errors gracefully with inline retry UI.

## Styling Notes
- Use **bold** for key actions.
- Use *italics* for secondary context.
- Keep message spacing consistent for readability.

### Example
```dart
await ref.read(chatProvider.notifier).sendCurrentInput(model);
```

This response is intentionally verbose so your UI can test longer streamed content.
''';
  }
  if (normalized.contains('plan')) {
    return '''
# Project Plan

Here is a **structured plan** you can test with streaming output:

## Phase 1: Scope
- Define goals and constraints.
- Decide MVP features and non-goals.
- Finalize routes and app state shape.

## Phase 2: Build
1. Create providers and models.
2. Implement screens with navigation.
3. Add service layer and stream parser.
4. Connect send/retry/cancel actions.

## Phase 3: Validate
- Manual UX pass on both light and dark themes
- Verify loading, success, error, and cancellation paths
- Confirm markdown text displays correctly

## Deliverables
- **Clean architecture**
- *Predictable state updates*
- Reusable chat components and streaming-ready flow
''';
  }

  return '''
# Mock Gemini Response

You said: **"$prompt"**

This is a longer mocked answer designed for streaming behavior tests.

## Highlights
- Uses **bold text**
- Uses *italic text*
- Includes lists and sections
- Can be rendered progressively with chunked SSE data

## Next Steps
1. Send another prompt with keywords like `flutter` or `plan`.
2. Validate how your UI handles long multi-paragraph messages.
3. Test cancellation in the middle of this type of response.

Thanks for testing the mock stream pipeline.
''';
}

String _extractLatestUserPrompt(Map<String, dynamic> payload) {
  final contents = payload['contents'];
  if (contents is! List) return '';

  for (var i = contents.length - 1; i >= 0; i--) {
    final item = contents[i];
    if (item is! Map<String, dynamic>) continue;
    final role = item['role'];
    if (role is! String || role != 'user') continue;
    final parts = item['parts'];
    if (parts is! List) continue;
    for (final part in parts) {
      if (part is! Map<String, dynamic>) continue;
      final text = part['text'];
      if (text is String && text.trim().isNotEmpty) {
        return text.trim();
      }
    }
  }

  return '';
}
