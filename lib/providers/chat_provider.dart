import 'package:flutter/material.dart';

import '../models/message.dart';
import '../models/place.dart';
import '../services/cache_service.dart';
import '../services/gemini_service.dart';

enum ChatMode { assistant, guide }

class ChatProvider with ChangeNotifier {
  final GeminiService _gemini = GeminiService();
  final CacheService _cache = CacheService.instance;

  List<ChatMessage> _messages = [];
  bool _isTyping = false;
  ChatMode _mode = ChatMode.assistant;
  String _cityName = '';
  String? _guideName;
  String? _guideBio;

  // Personalization context
  List<String> _preferredCategories = [];
  int _budgetLevel = 2;
  List<Place> _pinnedPlaces = [];
  List<Place> _savedPlaces = [];

  // Database context — real places from the app
  List<Place> _databasePlaces = [];

  List<ChatMessage> get messages => _messages;
  bool get isTyping => _isTyping;
  bool get isConfigured => _gemini.isConfigured;
  String get cityName => _cityName;

  ChatProvider() {
    _resetAssistantGreeting();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    _preferredCategories = await _cache.getPreferredCategories();
    _budgetLevel = await _cache.getBudgetLevel();
  }

  void setPersonalizationContext({
    List<String>? categories,
    int? budget,
    List<Place>? pinned,
    List<Place>? saved,
    String? userCity,
  }) {
    if (categories != null) _preferredCategories = categories;
    if (budget != null) _budgetLevel = budget;
    if (pinned != null) _pinnedPlaces = pinned;
    if (saved != null) _savedPlaces = saved;
    if (userCity != null && userCity.isNotEmpty) _cityName = userCity;
  }

  /// Inject the full list of places from the app database so the AI can
  /// reference real locations when making recommendations.
  void setDatabasePlaces(List<Place> places) {
    _databasePlaces = places;
  }

  void useAssistant({String? cityName}) {
    _mode = ChatMode.assistant;
    if (cityName != null && cityName.isNotEmpty) {
      _cityName = cityName;
    }
    _guideName = null;
    _guideBio = null;
    _resetAssistantGreeting();
  }

  void useGuide({
    required String guideName,
    required String guideBio,
    required String cityName,
  }) {
    _mode = ChatMode.guide;
    _guideName = guideName;
    _guideBio = guideBio;
    _cityName = cityName;
    _messages = [
      ChatMessage(
        text:
            "Salut! I'm $guideName, your local in $cityName. $guideBio — what would you like to discover?",
        isAI: true,
      ),
    ];
    notifyListeners();
  }

  void _resetAssistantGreeting() {
    final locationText = _cityName.isNotEmpty ? _cityName : 'your area';
    _messages = [
      ChatMessage(
        text:
            "Hi! I'm your LikeALocal AI guide. I know all the hidden gems in $locationText and can give personalized recommendations based on your preferences. What would you like to discover?",
        isAI: true,
      ),
    ];
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    _messages.add(ChatMessage(text: text.trim(), isAI: false));
    _isTyping = true;
    notifyListeners();

    try {
      final reply = await _gemini.chat(
        userMessage: text.trim(),
        systemPrompt: _systemPrompt(),
        history: _messages
            .take(_messages.length - 1)
            .map((m) => (
                  role: m.isAI ? 'assistant' : 'user',
                  text: m.text,
                ))
            .toList(),
      );
      _messages.add(ChatMessage(text: reply, isAI: true));
    } on GeminiNotConfiguredException {
      _messages.add(ChatMessage(
        text:
            'AI chat needs a Gemini API key. Run:\nflutter run --dart-define=GEMINI_API_KEY=your_key',
        isAI: true,
      ));
    } catch (e) {
      _messages.add(ChatMessage(
        text: 'Sorry, I could not respond right now. (${e.toString()})',
        isAI: true,
      ));
    } finally {
      _isTyping = false;
      notifyListeners();
    }
  }

  String _systemPrompt() {
    final personalContext = _buildPersonalContext();
    final databaseContext = _buildDatabaseContext();
    final locationContext = _cityName.isNotEmpty
        ? 'The user is currently in or interested in: $_cityName.'
        : 'The user has not specified a city yet. Ask them where they are or what city they want to explore.';

    if (_mode == ChatMode.guide && _guideName != null) {
      return '''You are $_guideName, a friendly local guide in $_cityName.
Bio: $_guideBio
Give short, personal recommendations like a real local. Mention specific neighborhoods when helpful.
$locationContext
$databaseContext
$personalContext''';
    }
    return '''You are LikeALocal AI, a travel assistant that helps users discover authentic hidden gems, cafes, restaurants, and experiences.
$locationContext
Keep answers concise, warm, and practical (2-4 sentences unless listing options).
IMPORTANT: When recommending places, prioritize places from the app database listed below. Reference them by name and mention their category and any tips. If the user asks about a place not in the database, you may answer generally but let them know it's not yet in the LikeALocal collection.
$databaseContext
$personalContext''';
  }

  String _buildDatabaseContext() {
    if (_databasePlaces.isEmpty) return '';

    // Filter to relevant places (same city if known, otherwise all)
    List<Place> relevant;
    if (_cityName.isNotEmpty) {
      relevant = _databasePlaces
          .where((p) => p.cityName.toLowerCase() == _cityName.toLowerCase())
          .toList();
      // If no places in that city, show all
      if (relevant.isEmpty) relevant = _databasePlaces;
    } else {
      relevant = _databasePlaces;
    }

    // Limit to avoid overflowing context
    final placesToShow = relevant.take(30).toList();

    final placeDescriptions = placesToShow.map((p) {
      final parts = <String>[p.title];
      if (p.category.isNotEmpty) parts.add('(${p.category})');
      if (p.cityName.isNotEmpty) parts.add('in ${p.cityName}');
      if (p.rating > 0) parts.add('★${p.rating.toStringAsFixed(1)}');
      if (p.price > 0) parts.add('\$' * p.price);
      if (p.tips.isNotEmpty) parts.add('— Tip: ${p.tips}');
      if (p.description.isNotEmpty && p.description.length <= 60) {
        parts.add('— ${p.description}');
      }
      return parts.join(' ');
    }).join('\n');

    return '''
\nAPP DATABASE — These are real places stored in LikeALocal that you should recommend:
$placeDescriptions
\nAlways prefer recommending these places over making up suggestions. If a user asks about a category or area, check if any of these places match before giving a generic answer.''';
  }

  String _buildPersonalContext() {
    final parts = <String>[];

    if (_preferredCategories.isNotEmpty) {
      parts.add('User prefers: ${_preferredCategories.join(", ")}.');
    }

    final budgetDesc = _budgetLevel == 1
        ? 'budget-friendly'
        : _budgetLevel == 2
            ? 'moderate'
            : 'high-end';
    parts.add('Budget preference: $budgetDesc.');

    if (_pinnedPlaces.isNotEmpty) {
      final pinNames = _pinnedPlaces.take(5).map((p) => p.title).join(', ');
      parts.add('User has pinned these places: $pinNames.');
    }

    if (_savedPlaces.isNotEmpty) {
      final savedNames = _savedPlaces.take(5).map((p) => '${p.title} (${p.category})').join(', ');
      parts.add('User has saved: $savedNames.');
    }

    if (parts.isEmpty) return '';
    return '\nUser personalization:\n${parts.join("\n")}';
  }

  void clearMessages() {
    if (_mode == ChatMode.guide && _guideName != null) {
      useGuide(
        guideName: _guideName!,
        guideBio: _guideBio ?? '',
        cityName: _cityName,
      );
    } else {
      useAssistant(cityName: _cityName);
    }
  }
}
