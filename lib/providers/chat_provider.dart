import 'package:flutter/material.dart';
import '../models/message.dart';

class ChatProvider with ChangeNotifier {
  List<ChatMessage> _messages = [];
  bool _isTyping = false;

  List<ChatMessage> get messages => _messages;
  bool get isTyping => _isTyping;

  ChatProvider() {
    // Initial AI greeting
    _messages.add(ChatMessage(
      text:
          "Hi! I'm your local AI guide. Ask me anything about hidden gems, local favorites, or where to go in Paris!",
      isAI: true,
    ));
  }

  Future<void> sendMessage(String text) async {
    // Add user message
    _messages.add(ChatMessage(text: text, isAI: false));
    notifyListeners();

    // Simulate AI typing
    _isTyping = true;
    notifyListeners();

    await Future.delayed(Duration(milliseconds: 1200));

    // Generate AI response based on keywords
    String response = _generateResponse(text.toLowerCase());
    _messages.add(ChatMessage(text: response, isAI: true));
    _isTyping = false;
    notifyListeners();
  }

  String _generateResponse(String input) {
    if (input.contains('cafe') ||
        input.contains('café') ||
        input.contains('coffee') ||
        input.contains('work')) {
      return "I recommend Le Petit Cafe in the 5th arrondissement! It has great WiFi, amazing croissants, and is loved by local students and freelancers. It's open from 8am-8pm and has a cozy atmosphere. Would you like more options?";
    } else if (input.contains('hidden') ||
        input.contains('gem') ||
        input.contains('montmartre')) {
      return "Montmartre has some incredible hidden gems! Check out the Secret Market on Rue des Abbesses (weekends only), and don't miss the tiny bookstore 'Old Town Books' tucked away on a side street. Both are local favorites with 9+ hidden gem scores!";
    } else if (input.contains('restaurant') ||
        input.contains('food') ||
        input.contains('eat')) {
      return "For authentic French cuisine, try Bistro Authentique - it's family-run and locals swear by their coq au vin. Another great spot is Le Petit Zinc for traditional bistro fare. Both are reasonably priced (\$\$) and accept walk-ins!";
    } else if (input.contains('museum') ||
        input.contains('free') ||
        input.contains('art')) {
      return "Great news! Many Paris museums are free on the first Sunday of each month. The Louvre, Musee d'Orsay, and Centre Pompidou all participate. For a hidden gem, try the Musee de la Vie Romantique - it's always free and barely known to tourists!";
    } else if (input.contains('night') ||
        input.contains('bar') ||
        input.contains('drink')) {
      return "For nightlife, check out Jazz Underground - live jazz every night in a cozy basement venue. If you want something more lively, Le Marais has great cocktail bars. My favorite is a tiny speakeasy on Rue des Archives - ask a local to point it out!";
    } else if (input.contains('market') || input.contains('shop')) {
      return "The Secret Market is a must-visit! It's only open on weekends and has the freshest produce and artisan goods. For unique souvenirs, head to Old Town Books or the artisan shops along Rue Mouffetard.";
    } else {
      return "That's a great question! I can help you find the best local spots, hidden gems, authentic restaurants, and unique experiences. What specifically interests you? Try asking about cafes, restaurants, hidden gems, or nightlife!";
    }
  }

  void clearMessages() {
    _messages.clear();
    _messages.add(ChatMessage(
      text:
          "Hi! I'm your local AI guide. Ask me anything about hidden gems, local favorites, or where to go in Paris!",
      isAI: true,
    ));
    notifyListeners();
  }
}
