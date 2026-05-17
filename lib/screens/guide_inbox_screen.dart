import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/local_guide.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';
import 'guide_chat_screen.dart';

/// Shows all active conversations for the current user (especially for guides).
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
      appBar: AppBar(title: const Text('Messages')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('guideChats')
            .where(FieldPath.documentId, isGreaterThanOrEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot1) {
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('guideChats')
                .where(FieldPath.documentId, isLessThanOrEqualTo: '${userId}')
                .snapshots(),
            builder: (context, snapshot2) {
              // Combine both queries to find chats containing this user's ID
              return FutureBuilder<List<_ChatPreview>>(
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
                          Icon(Icons.chat_bubble_outline, size: 48, color: AppColors.muted),
                          const SizedBox(height: 16),
                          const Text('No conversations yet'),
                          Text(
                            'Messages with guides will appear here',
                            style: TextStyle(color: AppColors.muted, fontSize: 13),
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
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primaryLight,
                          child: Text(
                            conv.otherName.isNotEmpty ? conv.otherName[0].toUpperCase() : '?',
                            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                          ),
                        ),
                        title: Text(conv.otherName, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(conv.lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
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
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<List<_ChatPreview>> _loadConversations(String userId) async {
    final firestore = FirestoreService();
    final chats = await FirebaseFirestore.instance.collection('guideChats').get();

    final conversations = <_ChatPreview>[];
    for (final doc in chats.docs) {
      final chatId = doc.id;
      if (!chatId.contains(userId)) continue;

      // Get the other user's ID
      final ids = chatId.split('_');
      final otherId = ids.firstWhere((id) => id != userId, orElse: () => '');
      if (otherId.isEmpty) continue;

      // Get last message
      final messagesSnap = await doc.reference
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (messagesSnap.docs.isEmpty) continue;

      final lastMsg = messagesSnap.docs.first.data();

      // Get other user's name
      final otherDoc = await FirebaseFirestore.instance.collection('users').doc(otherId).get();
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
