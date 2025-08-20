import 'package:flutter/material.dart';

class CallPage extends StatelessWidget {
  final String chatId;
  final bool video;
  const CallPage({super.key, required this.chatId, required this.video});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(video ? 'Video Call' : 'Voice Call'),
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(video ? Icons.videocam : Icons.call, size: 80, color: Colors.white70),
            const SizedBox(height: 24),
            const Text('Call UI coming soon', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.call_end),
              label: const Text('End'),
            )
          ],
        ),
      ),
    );
  }
}
