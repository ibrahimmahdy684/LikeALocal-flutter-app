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
  String _cityName = 'Paris';
  String? _guideName;
  String? _guideBio;

  // Personalization context
  List<String> _preferredCategories = [];
  int _budgetLevel = 2;
  List<Place> _pinnedPlaces = [];
  List<Place> _savedPlaces = [];

  List<ChatMessage> get messages => _messages;
  bool get isTyping => _isTyping;
  bool get isConfigured => _gemini.isConfigured;

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
  }) {
    if (categories != null) _preferredCategories = categories;
    if (budget != null) _budgetLevel = budget;
    if (pinned != null) _pinnedPlaces = pinned;
    if (saved != null) _savedPlaces = saved;
  }

  void useAssistant({String cityName = 'Paris'}) {
    _mode = ChatMode.assistant;
    _cityName = cityName;
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
    _messages = [
      ChatMessage(
        text:
            "Hi! I'm your LikeALocal AI guide for $_cityName. Ask about hidden gems, food, or where to go! I can personalize recommendations based on your preferences.",
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

    if (_mode == ChatMode.guide && _guideName != null) {
      return '''You are $_guideName, a friendly local guide in $_cityName.
Bio: $_guideBio
Give short, personal recommendations like a real local. Mention specific neighborhoods when helpful.
$personalContext''';
    }
    return '''You are LikeALocal AI, a travel assistant for $_cityName.
Help tourists find authentic hidden gems, cafes, restaurants, and experiences.
Keep answers concise, warm, and practical (2-4 sentences unless listing options).
$personalContext''';
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
