import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/local_guide.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';
import 'auth_screen.dart';

/// Real-time 1:1 chat between the current user and a local guide,
/// backed by Firestore (guideChats/{chatId}/messages).
class GuideChatScreen extends StatefulWidget {
  final LocalGuide guide;

  const GuideChatScreen({super.key, required this.guide});

  @override
  State<GuideChatScreen> createState() => _GuideChatScreenState();
}

class _GuideChatScreenState extends State<GuideChatScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _firestore = FirestoreService();

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

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => AuthScreen()));
      return;
    }

    _inputController.clear();
    await _firestore.sendGuideChatMessage(
      userId: auth.currentUser!.id,
      guideId: widget.guide.id,
      senderName: auth.currentUser!.name,
      text: text,
    );

    // Notify the recipient (guide or user) about the new message
    final recipientId = auth.currentUser!.id == widget.guide.id
        ? auth.currentUser!.id // This shouldn't happen but safety check
        : widget.guide.id;
    await _firestore.createMessageNotification(
      recipientId: recipientId,
      senderName: auth.currentUser!.name,
      messagePreview: text.length > 50 ? '${text.substring(0, 50)}...' : text,
    );

    _scrollToEnd();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final currentUserId = auth.currentUser?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primaryLight,
              child: Text(
                widget.guide.name.isNotEmpty
                    ? widget.guide.name.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
                    : '?',
                style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.guide.name,
                      style: const TextStyle(fontSize: 16)),
                  Text(
                    'Local guide · ${widget.guide.cityName}',
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages list via StreamBuilder
          Expanded(
            child: currentUserId.isEmpty
                ? Center(
                    child: Text('Sign in to chat',
                        style: TextStyle(color: AppColors.muted)))
                : StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _firestore.watchGuideChat(
                        currentUserId, widget.guide.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator(strokeWidth: 2));
                      }

                      final messages = snapshot.data ?? [];

                      if (messages.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(
                              'Say hi to ${widget.guide.name}! Start a conversation.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: AppColors.muted, fontSize: 14),
                            ),
                          ),
                        );
                      }

                      WidgetsBinding.instance
                          .addPostFrameCallback((_) => _scrollToEnd());

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          final isMe = msg['senderId'] == currentUserId;
                          return _MessageBubble(
                            text: msg['text'] ?? '',
                            senderName: msg['senderName'] ?? '',
                            isMe: isMe,
                          );
                        },
                      );
                    },
                  ),
          ),
          // Input bar
          Container(
            padding: EdgeInsets.fromLTRB(16, 16, 16, kIsWeb ? 16 : 32),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle:
                          TextStyle(fontSize: 14, color: AppColors.muted),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    maxLines: 4,
                    minLines: 1,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send, color: Colors.white, size: 18),
                  style:
                      IconButton.styleFrom(backgroundColor: AppColors.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final String senderName;
  final bool isMe;

  const _MessageBubble({
    required this.text,
    required this.senderName,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Text(
                senderName,
                style: TextStyle(fontSize: 11, color: AppColors.muted),
              ),
            ),
          Container(
            padding: const EdgeInsets.all(12),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72,
            ),
            decoration: BoxDecoration(
              color: isMe ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                if (!isMe)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
              ],
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: isMe ? Colors.white : AppColors.foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
