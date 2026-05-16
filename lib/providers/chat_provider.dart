import 'package:flutter/material.dart';

import '../models/message.dart';
import '../services/gemini_service.dart';

enum ChatMode { assistant, guide }

class ChatProvider with ChangeNotifier {
  final GeminiService _gemini = GeminiService();

  List<ChatMessage> _messages = [];
  bool _isTyping = false;
  ChatMode _mode = ChatMode.assistant;
  String _cityName = 'Paris';
  String? _guideName;
  String? _guideBio;

  List<ChatMessage> get messages => _messages;
  bool get isTyping => _isTyping;
  bool get isConfigured => _gemini.isConfigured;

  ChatProvider() {
    _resetAssistantGreeting();
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
            "Hi! I'm your LikeALocal AI guide for $_cityName. Ask about hidden gems, food, or where to go!",
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
    if (_mode == ChatMode.guide && _guideName != null) {
      return '''You are $_guideName, a friendly local guide in $_cityName.
Bio: $_guideBio
Give short, personal recommendations like a real local. Mention specific neighborhoods when helpful.''';
    }
    return '''You are LikeALocal AI, a travel assistant for $_cityName.
Help tourists find authentic hidden gems, cafes, restaurants, and experiences.
Keep answers concise, warm, and practical (2-4 sentences unless listing options).''';
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
