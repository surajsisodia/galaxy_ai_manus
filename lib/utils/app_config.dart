class AppConfig {
  static const geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const useMockGemini = bool.fromEnvironment(
    'USE_MOCK_GEMINI',
    defaultValue: true,
  );

  static bool get hasGeminiApiKey => geminiApiKey.trim().isNotEmpty;
  static bool get shouldUseMockGemini => useMockGemini || !hasGeminiApiKey;
}
