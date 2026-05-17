import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/local_guide.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import 'guide_chat_screen.dart';

/// Shows all active conversations for the current user (guides and other users).
class GuideInboxScreen extends StatefulWidget {
  const GuideInboxScreen({super.key});

  @override
  State<GuideInboxScreen> createState() => _GuideInboxScreenState();
}

class _GuideInboxScreenState extends State<GuideInboxScreen> {
  List<_ChatPreview>? _conversations;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) return;
    final convs = await _loadConversations(auth.currentUser!.id);
    if (mounted) {
      setState(() {
        _conversations = convs;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Messages')),
        body: const Center(child: Text('Sign in to view messages')),
      );
    }

    final userId = auth.currentUser!.id;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            tooltip: 'Start new chat',
            onPressed: () => _showNewChatDialog(context, userId),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(userId),
    );
  }

  Widget _buildBody(String userId) {
    final conversations = _conversations ?? [];
    if (conversations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat_bubble_outline, size: 48, color: AppColors.muted),
              const SizedBox(height: 16),
              const Text(
                'No conversations yet',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Messages with guides and travelers appear here',
                style: TextStyle(color: AppColors.muted, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _showNewChatDialog(context, userId),
                icon: const Icon(Icons.chat),
                label: const Text('Start a conversation'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: conversations.length,
      itemBuilder: (context, index) {
        final conv = conversations[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: AppColors.primaryLight,
              radius: 24,
              child: Text(
                conv.otherName.isNotEmpty
                    ? conv.otherName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ),
            title: Text(conv.otherName,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
              conv.lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            trailing: Icon(Icons.chevron_right, color: AppColors.muted),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GuideChatScreen(
                    guide: LocalGuide(
                      id: conv.otherId,
                      name: conv.otherName,
                      avatar: '',
                      cityName: '',
                      bio: '',
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showNewChatDialog(BuildContext context, String currentUserId) async {
    final auth = context.read<AuthProvider>();
    final userPrivacy = auth.currentUser!.chatPrivacy;

    if (userPrivacy == ChatPrivacy.nobody) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Chat is disabled. Change your privacy settings to message others.')),
      );
      return;
    }

    final users = await FirebaseFirestore.instance
        .collection('users')
        .limit(30)
        .get();

    if (!context.mounted) return;

    final otherUsers = users.docs
        .where((doc) => doc.id != currentUserId)
        .where((doc) {
      final privacy = doc.data()['chatPrivacy'] ?? 'everyone';
      return privacy != 'nobody';
    }).map((doc) =>
            (id: doc.id, name: (doc.data()['name'] ?? 'User') as String));

    final userList = otherUsers.take(15).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Start a conversation',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              if (userList.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No available users found'),
                )
              else
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: userList.length,
                    itemBuilder: (_, i) {
                      final user = userList[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primaryLight,
                          child: Text(
                            user.name.isNotEmpty
                                ? user.name[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                        title: Text(user.name),
                        onTap: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GuideChatScreen(
                                guide: LocalGuide(
                                  id: user.id,
                                  name: user.name,
                                  avatar: '',
                                  cityName: '',
                                  bio: '',
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<_ChatPreview>> _loadConversations(String userId) async {
    final chats =
        await FirebaseFirestore.instance.collection('guideChats').get();

    final conversations = <_ChatPreview>[];
    for (final doc in chats.docs) {
      final chatId = doc.id;
      if (!chatId.contains(userId)) continue;

      final ids = chatId.split('_');
      final otherId = ids.firstWhere((id) => id != userId, orElse: () => '');
      if (otherId.isEmpty) continue;

      final messagesSnap = await doc.reference
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (messagesSnap.docs.isEmpty) continue;

      final lastMsg = messagesSnap.docs.first.data();

      final otherDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(otherId)
          .get();
      final otherName = otherDoc.data()?['name'] ?? 'User';

      conversations.add(_ChatPreview(
        otherId: otherId,
        otherName: otherName,
        lastMessage: lastMsg['text'] ?? '',
      ));
    }

    return conversations;
  }
}

class _ChatPreview {
  final String otherId;
  final String otherName;
  final String lastMessage;

  _ChatPreview({
    required this.otherId,
    required this.otherName,
    required this.lastMessage,
  });
}
