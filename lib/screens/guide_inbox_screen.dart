import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/local_guide.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import 'guide_chat_screen.dart';

/// Shows all active conversations for the current user (guides and other users).
class GuideInboxScreen extends StatelessWidget {
  const GuideInboxScreen({super.key});

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
      body: FutureBuilder<List<_ChatPreview>>(
        future: _loadConversations(userId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final conversations = snap.data ?? [];
          if (conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline,
                      size: 48, color: AppColors.muted),
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
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conv = conversations[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
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
        },
      ),
    );
  }

  void _showNewChatDialog(BuildContext context, String currentUserId) async {
    final users = await FirebaseFirestore.instance
        .collection('users')
        .limit(20)
        .get();

    if (!context.mounted) return;

    final otherUsers = users.docs
        .where((doc) => doc.id != currentUserId)
        .map((doc) => (id: doc.id, name: (doc.data()['name'] ?? 'User') as String))
        .toList();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Start a conversation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            if (otherUsers.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No other users found'),
              )
            else
              ...otherUsers.take(10).map((user) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primaryLight,
                      child: Text(
                        user.name[0].toUpperCase(),
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
                  )),
          ],
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
