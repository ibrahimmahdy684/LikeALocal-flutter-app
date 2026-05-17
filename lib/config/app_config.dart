/// Runtime configuration.
///
/// Pass your Gemini API key when running:
/// `flutter run --dart-define=GEMINI_API_KEY=your_key_here`
///
/// Get a free key: https://aistudio.google.com/apikey
class AppConfig {
  // ──────────────────────────────────────────────────────────────
  // GEMINI API KEY PLACEHOLDER
  // Pass your key at build time:
  //   flutter run --dart-define=GEMINI_API_KEY=your_key_here
  // Get a free key: https://aistudio.google.com/apikey
  // ──────────────────────────────────────────────────────────────
  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');

  static const String geminiModel = 'gemini-2.0-flash';

  // Freemium limits
  static const int freeMapPinLimit = 10;
  static const int freePinLimit = 10;
  static const int freeItineraryLimit = 0; // Premium only

  // Super User promotion threshold
  static const int superUserPointsThreshold = 500;
  static const int superUserMinSharedPlaces = 10;

  static bool get hasGeminiKey => geminiApiKey.isNotEmpty;
}
