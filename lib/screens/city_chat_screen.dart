import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/auth_provider.dart';
import '../providers/city_chat_provider.dart';
import '../theme/app_colors.dart';
import 'auth_screen.dart';

class CityChatScreen extends StatefulWidget {
  final String cityName;

  const CityChatScreen({super.key, required this.cityName});

  @override
  State<CityChatScreen> createState() => _CityChatScreenState();
}

class _CityChatScreenState extends State<CityChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CityChatProvider>().listen(widget.cityName);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AuthScreen()),
      );
      return;
    }
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    await context.read<CityChatProvider>().send(
          userId: auth.currentUser!.id,
          userName: auth.currentUser!.name,
          text: text,
        );
    _controller.clear();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.cityName} Community'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<CityChatProvider>(
              builder: (context, chat, _) {
                if (chat.messages.isEmpty) {
                  return Center(
                    child: Text(
                      'Public chat for ${widget.cityName}.\nSay hello!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted),
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: chat.messages.length,
                  itemBuilder: (context, index) {
                    final m = chat.messages[index];
                    final isMe = context.read<AuthProvider>().currentUser?.id ==
                        m.userId;
                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: isMe
                              ? AppColors.primary
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isMe)
                              Text(
                                m.userName,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isMe
                                      ? Colors.white70
                                      : AppColors.primary,
                                ),
                              ),
                            Text(
                              m.text,
                              style: TextStyle(
                                color: isMe
                                    ? Colors.white
                                    : AppColors.foreground,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat.Hm().format(m.createdAt),
                              style: TextStyle(
                                fontSize: 10,
                                color: isMe
                                    ? Colors.white70
                                    : AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Message ${widget.cityName}...',
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _send,
                    icon: const Icon(Icons.send, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
