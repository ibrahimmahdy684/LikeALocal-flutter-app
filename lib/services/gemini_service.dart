import 'package:google_generative_ai/google_generative_ai.dart';

import '../config/app_config.dart';

class GeminiService {
  GenerativeModel? _model;

  GenerativeModel get _client {
    _model ??= GenerativeModel(
      model: AppConfig.geminiModel,
      apiKey: AppConfig.geminiApiKey,
    );
    return _model!;
  }

  bool get isConfigured => AppConfig.hasGeminiKey;

  Future<String> chat({
    required String userMessage,
    String? systemPrompt,
    List<({String role, String text})> history = const [],
  }) async {
    if (!isConfigured) {
      throw GeminiNotConfiguredException();
    }

    final promptParts = <String>[];
    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      promptParts.add(systemPrompt);
    }
    for (final entry in history) {
      final label = entry.role == 'user' ? 'User' : 'Assistant';
      promptParts.add('$label: ${entry.text}');
    }
    promptParts.add('User: $userMessage');
    promptParts.add('Assistant:');

    final response = await _client.generateContent([
      Content.text(promptParts.join('\n\n')),
    ]);

    final text = response.text?.trim();
    if (text == null || text.isEmpty) {
      throw Exception('Empty response from Gemini');
    }
    return text;
  }
}

class GeminiNotConfiguredException implements Exception {
  @override
  String toString() =>
      'Gemini API key missing. Run with --dart-define=GEMINI_API_KEY=your_key';
}
