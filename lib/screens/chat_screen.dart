import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../models/local_guide.dart';
import '../models/message.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/places_provider.dart';

class ChatScreen extends StatefulWidget {
  final LocalGuide? guide;
  final bool showHeader;

  const ChatScreen({super.key, this.guide, this.showHeader = true});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

/// Reusable chat body (messages + input) without scaffold header.
class ChatScreenBody extends StatefulWidget {
  const ChatScreenBody({super.key});

  @override
  State<ChatScreenBody> createState() => _ChatScreenBodyState();
}

class _ChatScreenBodyState extends State<ChatScreenBody> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    context.read<ChatProvider>().sendMessage(text.trim());
    _inputController.clear();
    _scrollToEnd();
  }

  void _scrollToEnd() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: _ChatMessagesList(scrollController: _scrollController)),
        _ChatInputBar(
          controller: _inputController,
          onSend: _sendMessage,
        ),
      ],
    );
  }
}

class _ChatScreenState extends State<ChatScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chat = context.read<ChatProvider>();
      final auth = context.read<AuthProvider>();
      final places = context.read<PlacesProvider>();

      // Inject full database of places so the AI can reference real data
      chat.setDatabasePlaces(places.getAllPlaces());

      // Determine user's city from their saved/nearby places or location
      String? userCity;
      if (places.savedPlaces.isNotEmpty) {
        userCity = places.savedPlaces.first.cityName;
      } else if (places.getAllPlaces().isNotEmpty) {
        userCity = places.getAllPlaces().first.cityName;
      }

      if (auth.isAuthenticated) {
        final pinnedIds = auth.currentUser!.pinnedPlaceIds;
        final pinnedPlaces = places.savedPlaces
            .where((p) => pinnedIds.contains(p.id))
            .toList();

        chat.setPersonalizationContext(
          categories: auth.currentUser!.preferredCategories,
          budget: auth.currentUser!.budgetLevel,
          saved: places.savedPlaces,
          pinned: pinnedPlaces,
          userCity: userCity,
        );
      }

      if (widget.guide != null) {
        chat.useGuide(
          guideName: widget.guide!.name,
          guideBio: widget.guide!.bio,
          cityName: widget.guide!.cityName,
        );
      } else {
        chat.useAssistant(cityName: userCity);
      }
    });
  }

  List<String> get _suggestions {
    final auth = context.read<AuthProvider>();
    final places = context.read<PlacesProvider>();
    final suggestions = <String>[];

    // Build personalized suggestions based on user data
    if (auth.isAuthenticated) {
      final user = auth.currentUser!;
      final categories = user.preferredCategories;
      final saved = places.savedPlaces;

      // Suggest based on preferred categories
      if (categories.isNotEmpty) {
        suggestions.add('Best ${categories.first.toLowerCase()} spots nearby');
      }

      // Suggest based on saved places
      if (saved.isNotEmpty) {
        final lastSaved = saved.last;
        suggestions.add('Places similar to ${lastSaved.title}');
      }

      // Budget-aware suggestion
      final budget = user.budgetLevel;
      if (budget == 1) {
        suggestions.add('Free things to do today');
      } else if (budget == 3) {
        suggestions.add('Upscale dining experiences');
      } else {
        suggestions.add('Affordable hidden gems');
      }

      // Category they haven't explored
      final allCats = ['Cafe', 'Restaurant', 'Market', 'Art & Culture', 'Outdoor', 'Nightlife'];
      final unexplored = allCats.where((c) => !categories.contains(c)).toList();
      if (unexplored.isNotEmpty) {
        suggestions.add('Discover ${unexplored.first.toLowerCase()} places');
      }
    }

    // Fallback defaults if no personalization available
    if (suggestions.isEmpty) {
      return [
        'Best local cafes nearby',
        'Hidden gems to explore',
        'Where do locals eat?',
        'Free activities today',
      ];
    }

    return suggestions.take(4).toList();
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.sendMessage(_inputController.text.trim());
    _inputController.clear();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          if (widget.showHeader) _buildHeader(),
          Expanded(
              child: _ChatMessagesList(scrollController: _scrollController)),
          Consumer<ChatProvider>(
            builder: (context, chatProvider, child) {
              if (chatProvider.messages.length == 1 && widget.guide == null) {
                return _buildSuggestions();
              }
              return const SizedBox.shrink();
            },
          ),
          _ChatInputBar(
            controller: _inputController,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(24, kIsWeb ? 16 : 48, 24, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.chat, color: AppColors.primary, size: 24),
          ),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Community Chat',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.foreground,
                ),
              ),
              Text(
                'Chat with locals and travelers',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
      color: AppColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Suggestions:',
            style: TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestions.map((suggestion) {
              return GestureDetector(
                onTap: () => _sendMessage(suggestion),
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    suggestion,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.foreground,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

}

class _ChatMessagesList extends StatelessWidget {
  final ScrollController scrollController;

  const _ChatMessagesList({required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        return ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          itemCount:
              chatProvider.messages.length + (chatProvider.isTyping ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == chatProvider.messages.length && chatProvider.isTyping) {
              return _TypingIndicator();
            }
            return _MessageBubble(message: chatProvider.messages[index]);
          },
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            message.isAI ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.isAI) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy,
                  color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: message.isAI ? AppColors.surface : AppColors.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: message.isAI ? AppColors.foreground : Colors.white,
                ),
              ),
            ),
          ),
          if (!message.isAI) const SizedBox(width: 12),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          CircularProgressIndicator(strokeWidth: 2),
          SizedBox(width: 12),
          Text('Thinking...'),
        ],
      ),
    );
  }
}

class _ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String) onSend;

  const _ChatInputBar({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, kIsWeb ? 16 : 32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Ask for local recommendations...',
                hintStyle: TextStyle(fontSize: 14, color: AppColors.muted),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              maxLines: 4,
              minLines: 1,
              onSubmitted: onSend,
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: () => onSend(controller.text),
            icon: const Icon(Icons.send, color: Colors.white, size: 18),
            style: IconButton.styleFrom(backgroundColor: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
