/// Runtime configuration.
///
/// Pass your Gemini API key when running:
/// `flutter run --dart-define=GEMINI_API_KEY=your_key_here`
///
/// Get a free key: https://aistudio.google.com/apikey
class AppConfig {
  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');

  static const String geminiModel = 'gemini-2.0-flash';

  static const int freeMapPinLimit = 10;

  static bool get hasGeminiKey => geminiApiKey.isNotEmpty;
}
