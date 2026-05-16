import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/local_guide.dart';
import '../providers/chat_provider.dart';
import '../theme/app_colors.dart';
import 'chat_screen.dart';

class GuideChatScreen extends StatefulWidget {
  final LocalGuide guide;

  const GuideChatScreen({super.key, required this.guide});

  @override
  State<GuideChatScreen> createState() => _GuideChatScreenState();
}

class _GuideChatScreenState extends State<GuideChatScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().useGuide(
            guideName: widget.guide.name,
            guideBio: widget.guide.bio,
            cityName: widget.guide.cityName,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(widget.guide.avatar),
              radius: 18,
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
      body: const ChatScreenBody(),
    );
  }
}
