import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/services/user_service.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/chat_service.dart';
import '../../../../shared/models/chat_model.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/services/remote_config_service.dart';

class ChatListPage extends ConsumerStatefulWidget {
  const ChatListPage({super.key});

  @override
  ConsumerState<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends ConsumerState<ChatListPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chats',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.alternate_email),
            tooltip: 'Copy my @username',
            onPressed: () async {
              final me = FirebaseAuth.instance.currentUser?.uid;
              if (me == null) return;
              try {
                final user = await ref.read(userServiceProvider).getUserById(me);
                final uname = user?.toJson()['username'] as String?;
                if (!context.mounted) return;
                final messenger = ScaffoldMessenger.of(context);
                if (uname == null || uname.isEmpty) {
                  messenger.showSnackBar(const SnackBar(content: Text('Set your username first')));
                  return;
                }
                await Clipboard.setData(ClipboardData(text: '@$uname'));
                if (!context.mounted) return;
                messenger.showSnackBar(SnackBar(content: Text('Copied @$uname')));
              } catch (_) {}
            },
          ),
          IconButton(
            icon: const Icon(Icons.content_copy),
            tooltip: 'Copy my UID',
            onPressed: () async {
              final uid = FirebaseAuth.instance.currentUser?.uid;
              if (uid == null) return;
              await Clipboard.setData(ClipboardData(text: uid));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Your UID copied to clipboard')),
                );
              }
            },
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _promptStartChat,
        icon: const Icon(Icons.chat),
        label: const Text('Start chat'),
      ),
    );
  }

  Widget _buildBody() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Center(child: Text('Please sign in'));
  final chats = ref.watch(userChatsProvider(uid));
    return chats.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Failed to load chats'),
              const SizedBox(height: 8),
              Text(
                e.toString(),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      data: (list) {
        if (list.isEmpty) return _empty();
        return FutureBuilder(
          future: ref.read(userServiceProvider).getUserById(uid),
          builder: (context, snapshot) {
            final needsUsername = (snapshot.data?.toJson()['username'] as String?) == null;
            return ListView.builder(
              itemCount: list.length + (needsUsername ? 1 : 0),
              itemBuilder: (context, index) {
                if (needsUsername && index == 0) {
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: const Icon(Icons.alternate_email),
                      title: const Text('Set your @username'),
                      subtitle: const Text('Pick a unique handle so friends can find you'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.go(AppRoutes.chooseUsername),
                    ),
                  );
                }
                final chat = list[index - (needsUsername ? 1 : 0)];
                return _tile(chat, index);
              },
            );
          },
        );
      },
    );
  }

  Widget _tile(ChatModel chat, int index) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final other = chat.participants.firstWhere(
      (p) => p != currentUid,
      orElse: () => 'Chat',
    );
    return Dismissible(
      key: Key(chat.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      ),
      onDismissed: (_) {},
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
          child: const Icon(Icons.person, color: AppTheme.primaryColor),
        ),
        title: Text(other, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              chat.lastMessage ?? 'Say hi!',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Text(
              timeago.format(chat.lastMessageTimestamp ?? chat.updatedAt),
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
        onTap: () => context.go('${AppRoutes.chat}/${chat.id}'),
      ),
    ).animate(delay: (index * 100).ms).slideX(
          begin: 0.3,
          duration: 400.ms,
          curve: Curves.easeOut,
        ).fadeIn();
  }

  Widget _empty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.chat_bubble_outline, size: 60, color: AppTheme.primaryColor),
          ).animate().scale(duration: 600.ms),
          const SizedBox(height: 24),
          Text(
            'No conversations yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ).animate(delay: 200.ms).fadeIn(),
          const SizedBox(height: 8),
          Text(
            'Start matching with people to begin chatting!',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ).animate(delay: 400.ms).fadeIn(),
        ],
      ),
    );
  }

  Future<void> _promptStartChat() async {
    final me = FirebaseAuth.instance.currentUser?.uid;
    if (me == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please sign in first')));
      }
      return;
    }
    String input = '';
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Start chat by username'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Username',
            hintText: 'Enter @username',
            suffixIcon: IconButton(
              icon: const Icon(Icons.paste),
              tooltip: 'Paste from clipboard',
              onPressed: () async {
                final data = await Clipboard.getData('text/plain');
                final text = data?.text?.trim() ?? '';
                if (text.isNotEmpty) controller.text = text.replaceAll('@', '');
              },
            ),
          ),
          onChanged: (v) => input = v.trim(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              input = controller.text.trim();
              Navigator.pop(ctx);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
    final username = input.replaceAll('@', '').toLowerCase();
    if (username.isEmpty) return;
    try {
  final userSvc = ref.read(userServiceProvider);
  final otherUid = await userSvc.resolveUsernameToUid(username);
  if (otherUid == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username not found')),
        );
        return;
      }
  if (otherUid == me) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You cannot chat with yourself')),
        );
        return;
      }
  // Gate: require current user to have MBTI and at least 3 interests before starting chat (best-effort; don't read other user's profile)
  final meUser = await userSvc.getUserById(me);
  final minInterests = RemoteConfigService.instance.getInt('require_min_interests');
  final needsSetup = (meUser?.personalityType == null || (meUser?.interests.length ?? 0) < (minInterests <= 0 ? 3 : minInterests));
      if (needsSetup) {
        if (!mounted) return;
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Complete your profile'),
    content: const Text('Please complete the MBTI test and add at least 3 hobbies before starting chats.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Later')),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.go(AppRoutes.personalityTest);
                },
                child: const Text('Do it now'),
              ),
            ],
          ),
        );
        return;
      }
  final chat = await ref.read(chatServiceProvider).createOrGetDirectChat(me, otherUid);
  await analyticsService.logStartChat(targetUid: otherUid);
      if (!mounted) return;
  context.go('${AppRoutes.chat}/${chat.id}?otherUserId=$otherUid');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start chat: $e')),
      );
    }
  }
}
