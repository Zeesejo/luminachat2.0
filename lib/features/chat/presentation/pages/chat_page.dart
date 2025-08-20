import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/chat_service.dart';
import '../../../../shared/models/chat_model.dart';
import '../../../../core/services/storage_service.dart';
import '../../../calls/presentation/pages/call_page.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/services/remote_config_service.dart';
import '../widgets/ai_insights_widgets.dart';
import '../widgets/virtual_date_planner_widget.dart';

class ChatPage extends ConsumerStatefulWidget {
  final String chatId;
  final String? otherUserId;

  const ChatPage({
    super.key,
    required this.chatId,
    this.otherUserId,
  });

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();
  bool _showEmojiPicker = false;
  bool _isRecording = false;
  // This field reflects live typing status and is intentionally mutable
  // ignore: prefer_final_fields
  // local typing state removed; derive from controller when needed
  final AudioRecorder _recorder = AudioRecorder();
  final ImagePicker _picker = ImagePicker();
  String? _currentUserId;
  // simple audio player state
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _playingMessageId;
  bool _isPlayingAudio = false;
  Duration _audioPosition = Duration.zero;
  Duration _audioDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer.onDurationChanged.listen((d) => setState(() => _audioDuration = d));
    _audioPlayer.onPositionChanged.listen((p) => setState(() => _audioPosition = p));
    _audioPlayer.onPlayerComplete.listen((_) {
      setState(() {
        _isPlayingAudio = false;
        _playingMessageId = null;
        _audioPosition = Duration.zero;
      });
    });
  // Log open chat
  analyticsService.logOpenChat(widget.chatId);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
  _inputFocusNode.dispose();
    _recorder.dispose();
  _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final svc = ref.read(chatServiceProvider);
    final text = _messageController.text.trim();
    final replyToId = _replyingToMessageId;
    
    _messageController.clear();
    setState(() {
      _replyingToMessageId = null;
      _replyingToContent = '';
    });
    
  // no-op: typing state derived from controller
    try {
      await svc.sendMessage(
        chatId: widget.chatId,
        senderId: uid,
        content: text,
        type: MessageType.text,
        replyToMessageId: replyToId,
      );
  await analyticsService.logSendMessage(chatId: widget.chatId, type: 'text');
    } catch (e) {
      debugPrint('Send text failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send message')),
        );
      }
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
  final uid = FirebaseAuth.instance.currentUser?.uid;
    _currentUserId = uid;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAIFeatures(context),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
  icon: const Icon(Icons.psychology),
  label: const Text('AI Insights'),
      ).animate(delay: 1.seconds).slideY(begin: 1, end: 0).fadeIn(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: GestureDetector(
          onTap: () {
            // Navigate to user profile
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('View profile functionality coming soon')),
            );
          },
          child: Row(
            children: [
              // Profile Avatar with online indicator
              Stack(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                    backgroundImage: NetworkImage(
                      'https://via.placeholder.com/150/4CAF50/FFFFFF?text=U'
                    ),
                    child: const Icon(Icons.person, color: Colors.transparent),
                  ),
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppTheme.successColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chat Partner',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Consumer(builder: (context, ref, _) {
                      final uid = _currentUserId;
                      final typing = uid == null
                          ? const AsyncValue<List<String>>.data(<String>[])
                          : ref.watch(typingIndicatorsProvider((chatId: widget.chatId, userId: uid)));
                      final isPeerTyping = typing.maybeWhen(
                        data: (l) => l.isNotEmpty,
                        orElse: () => false,
                      );
                      return Row(
                        children: [
                          // Typing indicator dots
                          if (isPeerTyping) ...[
                            ...List.generate(3, (i) => 
                              Container(
                                width: 4,
                                height: 4,
                                margin: const EdgeInsets.symmetric(horizontal: 1),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  shape: BoxShape.circle,
                                ),
                              ).animate(
                                onPlay: (controller) => controller.repeat(reverse: true),
                              ).scale(
                                delay: (i * 200).ms,
                                duration: 600.ms,
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            isPeerTyping ? 'typing...' : 'online',
                            style: TextStyle(
                              fontSize: 12,
                              color: isPeerTyping ? AppTheme.primaryColor : AppTheme.successColor,
                              fontWeight: isPeerTyping ? FontWeight.w500 : FontWeight.normal,
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          // Video call button
          if (RemoteConfigService.instance.getBool('enable_video_calls'))
            IconButton(
              icon: const Icon(Icons.videocam_outlined),
              tooltip: 'Video call',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CallPage(chatId: widget.chatId, video: true),
                  ),
                );
              },
            ),
          // Audio call button
          if (RemoteConfigService.instance.getBool('enable_calls'))
            IconButton(
              icon: const Icon(Icons.call_outlined),
              tooltip: 'Voice call',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CallPage(chatId: widget.chatId, video: false),
                  ),
                );
              },
            ),
          // More options menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'view_profile':
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('View profile functionality coming soon')),
                  );
                  break;
                case 'media':
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('View media functionality coming soon')),
                  );
                  break;
                case 'search':
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Search in chat functionality coming soon')),
                  );
                  break;
                case 'mute':
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mute notifications functionality coming soon')),
                  );
                  break;
                case 'block':
                  _showBlockDialog();
                  break;
                case 'report':
                  _showReportDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'view_profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline),
                    SizedBox(width: 12),
                    Text('View Profile'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'media',
                child: Row(
                  children: [
                    Icon(Icons.photo_outlined),
                    SizedBox(width: 12),
                    Text('View Media'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'search',
                child: Row(
                  children: [
                    Icon(Icons.search_outlined),
                    SizedBox(width: 12),
                    Text('Search'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'mute',
                child: Row(
                  children: [
                    Icon(Icons.notifications_off_outlined),
                    SizedBox(width: 12),
                    Text('Mute Notifications'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'block',
                child: Row(
                  children: [
                    Icon(Icons.block, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Block User', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.report_outlined, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Report', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Messages List
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.deferToChild,
                  onTap: () {
                    if (_showEmojiPicker) setState(() => _showEmojiPicker = false);
                    _inputFocusNode.unfocus();
                  },
                  child: Consumer(
                    builder: (context, ref, _) {
                      final stream = ref.watch(chatMessagesProvider(widget.chatId));
                      return stream.when(
                        data: (messages) {
                          return ListView.builder(
                            controller: _scrollController,
                            reverse: true,
                            padding: const EdgeInsets.all(16),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final message = messages[index];
                              // reverse:true shows newest at top; animate index from end for nicer effect
                              final animIndex = (messages.length - 1) - index;
                              return _buildMessageBubble(message, animIndex, currentUserId: uid);
                            },
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, st) {
                          final err = e.toString();
                          debugPrint('Messages stream error: $err');
                          final linkMatch = RegExp(r'https://console\.firebase\.google\.com\S*').firstMatch(err);
                          final indexUrl = linkMatch?.group(0);
                          final isPermission = err.contains('permission-denied');
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Failed to load messages. Please check your connection and permissions.',
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),
                                  if (isPermission)
                                    const Text(
                                      'Firestore rules may be blocking message reads for this chat.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  if (indexUrl != null) ...[
                                    const SizedBox(height: 8),
                                    ElevatedButton(
                                      onPressed: () {
                                        final uri = Uri.parse(indexUrl);
                                        launchUrl(uri, mode: LaunchMode.externalApplication);
                                      },
                                      child: const Text('Open Firestore index link'),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
              
              // Message Input
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Reply preview
                      if (_replyingToMessageId != null)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border(left: BorderSide(color: AppTheme.primaryColor, width: 3)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Replying to',
                                      style: TextStyle(
                                        color: AppTheme.primaryColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _replyingToContent,
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 14,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    _replyingToMessageId = null;
                                    _replyingToContent = '';
                                  });
                                },
                                icon: const Icon(Icons.close, size: 20),
                                color: Colors.grey.shade600,
                              ),
                            ],
                          ),
                        ),
                      
                      _buildMessageInput(),
                    ],
                  ),
                ),
              ),
              
              // Emoji Picker
              if (_showEmojiPicker)
                SafeArea(
                  top: false,
                  child: SizedBox(
                    height: 250,
                    child: EmojiPicker(
                      onEmojiSelected: (category, emoji) {
                        setState(() {
                          _messageController.text += emoji.emoji;
                        });
                      },
                      config: const Config(
                        columns: 7,
                        emojiSizeMax: 32,
                        verticalSpacing: 0,
                        horizontalSpacing: 0,
                        gridPadding: EdgeInsets.zero,
                        initCategory: Category.RECENT,
                        bgColor: Color(0xFFF2F2F2),
                        indicatorColor: AppTheme.primaryColor,
                        iconColor: Colors.grey,
                        iconColorSelected: AppTheme.primaryColor,
                        backspaceColor: AppTheme.primaryColor,
                        skinToneDialogBgColor: Colors.white,
                        skinToneIndicatorColor: Colors.grey,
                        enableSkinTones: true,
                        recentsLimit: 28,
                        replaceEmojiOnLimitExceed: false,
                        noRecents: Text(
                          'No Recents',
                          style: TextStyle(fontSize: 20, color: Colors.black26),
                          textAlign: TextAlign.center,
                        ),
                        loadingIndicator: SizedBox.shrink(),
                        tabIndicatorAnimDuration: kTabScrollDuration,
                        categoryIcons: CategoryIcons(),
                        buttonMode: ButtonMode.MATERIAL,
                        checkPlatformCompatibility: true,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          
          // Recording overlay
          if (_isRecording)
            Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.mic,
                          color: Colors.white,
                          size: 40,
                        ),
                      ).animate(onPlay: (controller) => controller.repeat())
                        .scale(duration: 1.seconds, begin: Offset(1, 1), end: Offset(1.1, 1.1))
                        .then()
                        .scale(duration: 1.seconds, begin: Offset(1.1, 1.1), end: Offset(1, 1)),
                      
                      const SizedBox(height: 16),
                      const Text(
                        'Recording...',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Release to send, slide up to cancel',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message, int index, {String? currentUserId}) {
    final isMe = message.senderId == currentUserId;
    // In reversed list, we don't have neighbor reference; show time every ~5 items for now
    final showTime = index % 5 == 0;

    Widget contentWidget;
    if (message.type == MessageType.image && (message.attachment?.url.isNotEmpty ?? false)) {
      final url = message.attachment!.url;
      contentWidget = GestureDetector(
        onTap: () => _openImageViewer(url),
        child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CachedNetworkImage(
          imageUrl: url,
          width: 220,
          height: 240,
          fit: BoxFit.cover,
          placeholder: (c, _) => Container(
            width: 220,
            height: 240,
            color: Colors.black12,
            alignment: Alignment.center,
            child: const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          errorWidget: (c, _, __) => Container(
            width: 220,
            height: 240,
            color: Colors.black12,
            alignment: Alignment.center,
            child: const Icon(Icons.broken_image),
          ),
        ),
        ),
      );
    } else if (message.type == MessageType.audio && (message.attachment?.url.isNotEmpty ?? false)) {
      final url = message.attachment!.url;
      contentWidget = _buildEnhancedAudioBubble(url, message.id, isMe);
    } else if (message.type == MessageType.file && (message.attachment?.url.isNotEmpty ?? false)) {
      final url = message.attachment!.url;
      final name = message.attachment!.fileName ?? 'File';
      contentWidget = InkWell(
        onTap: () => _openUrl(url),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insert_drive_file, color: isMe ? Colors.white : Colors.black54),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 180),
              child: Text(
                name,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black87,
                  fontSize: 16,
                  decoration: TextDecoration.underline,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    } else {
      // default to text
      contentWidget = Text(
        message.content,
        style: TextStyle(
          color: isMe ? Colors.white : Colors.black87,
          fontSize: 16,
        ),
      );
    }

    return Column(
      children: [
        if (showTime)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
              ),
            ),
          ),
        
        Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: GestureDetector(
            onLongPress: () => _showMessageActions(context, message),
            child: Dismissible(
              key: Key('message-${message.id}'),
              direction: isMe ? DismissDirection.endToStart : DismissDirection.startToEnd,
              onDismissed: (_) {
                // Reset dismissible immediately after swipe
                setState(() {});
              },
              confirmDismiss: (_) async {
                // Show reply preview and don't actually dismiss
                _showReplyPreview(message);
                return false;
              },
              background: Container(
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                padding: EdgeInsets.symmetric(horizontal: isMe ? 20 : 20),
                child: Icon(
                  Icons.reply,
                  color: AppTheme.primaryColor,
                  size: 28,
                ),
              ),
              child: Container(
                margin: EdgeInsets.only(
                  bottom: 8,
                  left: isMe ? 50 : 0,
                  right: isMe ? 0 : 50,
                ),
                child: Column(
                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    // Reply preview if this message is a reply
                    if (message.replyToMessageId != null) 
                      _buildReplyPreview(message.replyToMessageId!),
                    
                    // Main message bubble
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isMe ? AppTheme.primaryColor : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20).copyWith(
                          bottomLeft: isMe ? null : const Radius.circular(4),
                          bottomRight: isMe ? const Radius.circular(4) : null,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          contentWidget,
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _formatMessageTime(message.timestamp),
                                style: TextStyle(
                                  color: isMe ? Colors.white70 : Colors.grey.shade600,
                                  fontSize: 11,
                                ),
                              ),
                              if (isMe) ...[
                                const SizedBox(width: 4),
            if (currentUserId != null && currentUserId.isNotEmpty)
                                  Builder(
                                    builder: (_) {
              final uid = currentUserId;
                                      final read = message.isReadBy(uid);
                                      return Icon(
                                        read ? Icons.done_all : Icons.done,
                                        size: 16,
                                        color: read ? AppTheme.successColor : Colors.white70,
                                      );
                                    },
                                  ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Message reactions
                    if (message.reactions.isNotEmpty)
                      _buildReactionsRow(message),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ).animate(delay: (index * 50).ms).slideX(
      begin: isMe ? 0.3 : -0.3,
      duration: 300.ms,
      curve: Curves.easeOut,
    ).fadeIn();
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildEnhancedAudioBubble(String url, String messageId, bool isMe) {
    final isActive = _playingMessageId == messageId && _isPlayingAudio;
    final pos = isActive ? _audioPosition : Duration.zero;
    final dur = isActive ? _audioDuration : Duration.zero;
    
    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => _togglePlay(url, messageId),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isMe ? Colors.white.withValues(alpha: 0.2) : AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isActive ? Icons.pause : Icons.play_arrow,
                color: isMe ? Colors.white : AppTheme.primaryColor,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Animated waveform placeholder
                SizedBox(
                  height: 40,
                  child: Row(
                    children: List.generate(30, (i) {
                      final height = (20 + (i % 3) * 8).toDouble();
                      final isPlaying = isActive && (pos.inMilliseconds / 100) > i;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        width: 3,
                        height: height,
                        decoration: BoxDecoration(
                          color: isPlaying 
                            ? (isMe ? Colors.white : AppTheme.primaryColor)
                            : (isMe ? Colors.white54 : Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dur > Duration.zero
                    ? '${_formatDuration(pos)} / ${_formatDuration(dur)}'
                    : '0:00',
                  style: TextStyle(
                    color: isMe ? Colors.white70 : Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _togglePlay(String url, String messageId) async {
    try {
      if (_playingMessageId == messageId && _isPlayingAudio) {
        await _audioPlayer.pause();
        setState(() => _isPlayingAudio = false);
        return;
      }
      // stop any existing
      await _audioPlayer.stop();
      _audioPosition = Duration.zero;
      _audioDuration = Duration.zero;
      _playingMessageId = messageId;
      await _audioPlayer.play(UrlSource(url));
      setState(() => _isPlayingAudio = true);
    } catch (_) {}
  }

  Future<void> _seekAudio(Duration position) async { // ignore: unused_element
    try {
      await _audioPlayer.seek(position);
    } catch (_) {}
  }

  Widget _buildMessageInput() {
    return Row(
      children: [
        // Emoji/Keyboard toggle
        IconButton(
          icon: Icon(
            _showEmojiPicker ? Icons.keyboard : Icons.emoji_emotions_outlined,
            color: AppTheme.primaryColor,
          ),
          onPressed: () {
            setState(() {
              _showEmojiPicker = !_showEmojiPicker;
              if (_showEmojiPicker) {
                _inputFocusNode.unfocus();
              } else {
                _inputFocusNode.requestFocus();
              }
            });
          },
        ),
        
        // Message input field
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: _inputFocusNode.hasFocus 
                  ? AppTheme.primaryColor.withValues(alpha: 0.3)
                  : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    focusNode: _inputFocusNode,
                    decoration: const InputDecoration(
                      hintText: 'Message...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 5,
                    minLines: 1,
                    onTap: () {
                      if (_showEmojiPicker) {
                        setState(() => _showEmojiPicker = false);
                      }
                    },
                    onChanged: (text) {
                      setState(() {}); // Rebuild to show/hide send button
                      // Update typing indicator
                      final me = _currentUserId;
                      if (me != null) {
                        ref.read(chatServiceProvider).setTypingIndicator(
                              widget.chatId,
                              me,
                              text.trim().isNotEmpty,
                            );
                      }
                    },
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                
                // Attachment button (only show when not typing)
                if (_messageController.text.trim().isEmpty) ...[
                  IconButton(
                    icon: Icon(Icons.attach_file, color: Colors.grey.shade600),
                    onPressed: _showAttachmentSheet,
                  ),
                  IconButton(
                    icon: Icon(Icons.camera_alt, color: Colors.grey.shade600),
                    onPressed: _capturePhoto,
                  ),
                ],
              ],
            ),
          ),
        ),
        
        const SizedBox(width: 8),
        
        // Send/Voice Button with enhanced UI
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: GestureDetector(
            onTap: _messageController.text.trim().isNotEmpty ? _sendMessage : null,
            onLongPressStart: (_) => _startRecording(),
            onLongPressEnd: (_) => _stopRecording(),
            onLongPressCancel: () => _stopRecording(),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _isRecording 
                  ? Colors.red 
                  : _messageController.text.trim().isNotEmpty
                    ? AppTheme.primaryColor
                    : AppTheme.primaryColor,
                shape: BoxShape.circle,
                boxShadow: _isRecording ? [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  )
                ] : null,
              ),
              child: Icon(
                _messageController.text.trim().isNotEmpty
                    ? Icons.send_rounded
                    : _isRecording
                        ? Icons.stop
                        : Icons.mic,
                color: Colors.white,
                size: _isRecording ? 24 : 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  String _formatMessageTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<bool> _ensurePermission(Permission permission) async {
    final status = await permission.request();
    return status.isGranted;
  }

  Future<void> _showAttachmentSheet() async {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('Choose from gallery'),
              onTap: () async {
                Navigator.pop(ctx);
                bool ok = await _ensurePermission(Permission.photos);
                if (!ok) {
                  ok = await _ensurePermission(Permission.storage);
                }
                if (!ok) return;
                final xfile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                if (xfile == null) return;
                await _sendImage(File(xfile.path));
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file),
              title: const Text('Document'),
              onTap: () async {
                Navigator.pop(ctx);
                final res = await FilePicker.platform.pickFiles(type: FileType.any, allowMultiple: false);
                if (res == null || res.files.isEmpty) return;
                final picked = res.files.single;
                final path = picked.path;
                if (path == null) return;
                await _sendFile(File(path), fileName: picked.name, mimeType: picked.extension);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _capturePhoto() async {
    final cameraOk = await _ensurePermission(Permission.camera);
    if (!cameraOk) return;
    final xfile = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (xfile == null) return;
    await _sendImage(File(xfile.path));
  }

  Future<void> _sendImage(File file) async {
    final uid = _currentUserId;
    if (uid == null) return;
    try {
      // Basic validation to reduce Storage errors
      final storage = ref.read(storageServiceProvider);
      if (!storage.isValidImageType(file)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unsupported image type')),
          );
        }
        return;
      }
      if (!storage.isFileSizeValid(file, maxSizeInMB: 10)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image too large (max 10MB)')),
          );
        }
        return;
      }
  final url = await storage.uploadChatImage(widget.chatId, file);
      await ref.read(chatServiceProvider).sendMessage(
            chatId: widget.chatId,
            senderId: uid,
            content: '',
            type: MessageType.image,
            attachment: MessageAttachment(url: url, type: AttachmentType.image),
          );
  await analyticsService.logSendMessage(chatId: widget.chatId, type: 'image');
    } catch (e) {
      debugPrint('Send image failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send image')),
        );
      }
    }
  }

  Future<void> _sendFile(File file, {String? fileName, String? mimeType}) async {
    final uid = _currentUserId;
    if (uid == null) return;
    try {
      final url = await ref.read(storageServiceProvider).uploadChatFile(widget.chatId, file, fileName: fileName, mimeType: mimeType);
      await ref.read(chatServiceProvider).sendMessage(
            chatId: widget.chatId,
            senderId: uid,
            content: fileName ?? '',
            type: MessageType.file,
            attachment: MessageAttachment(url: url, type: AttachmentType.file, fileName: fileName),
          );
  await analyticsService.logSendMessage(chatId: widget.chatId, type: 'file');
    } catch (e) {
      debugPrint('Send file failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send file')),
        );
      }
    }
  }

  void _openImageViewer(String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            PhotoView(
              imageProvider: CachedNetworkImageProvider(url),
              heroAttributes: PhotoViewHeroAttributes(tag: url),
              backgroundDecoration: const BoxDecoration(color: Colors.black),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessageActions(BuildContext context, MessageModel message) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            // Quick reactions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ['👍', '❤️', '😂', '😮', '😢', '😡'].map((emoji) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _addReaction(message.id, emoji);
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(emoji, style: const TextStyle(fontSize: 20)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Action buttons
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Reply'),
              onTap: () {
                Navigator.pop(ctx);
                _showReplyPreview(message);
              },
            ),
            ListTile(
              leading: const Icon(Icons.forward),
              title: const Text('Forward'),
              onTap: () {
                Navigator.pop(ctx);
                _forwardMessage(message);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy'),
              onTap: () {
                Navigator.pop(ctx);
                _copyMessage(message);
              },
            ),
            if (message.senderId == _currentUserId)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  _deleteMessage(message);
                },
              ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _addReaction(String messageId, String emoji) {
    final uid = _currentUserId;
    if (uid == null) return;
    
    // This would call a chat service method to add reaction
    // For now, just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added reaction $emoji'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Widget _buildReactionsRow(MessageModel message) {
    // This would show actual reactions from the message
    // For demo purposes, showing placeholder
    return Container(
      margin: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 4,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('👍', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 2),
                Text('2', style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _replyingToMessageId;
  String _replyingToContent = '';

  void _showReplyPreview(MessageModel message) {
    setState(() {
      _replyingToMessageId = message.id;
      _replyingToContent = message.content.isNotEmpty 
        ? message.content 
        : message.type == MessageType.image 
          ? 'Photo' 
          : message.type == MessageType.audio 
            ? 'Voice message'
            : 'File';
    });
    _inputFocusNode.requestFocus();
  }

  Widget _buildReplyPreview(String replyToId) {
    // This would fetch the actual message being replied to
    // For demo purposes, showing placeholder
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: AppTheme.primaryColor, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Replying to',
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Original message content...',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 14,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _forwardMessage(MessageModel message) {
    // Show list of chats to forward to
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Forward functionality coming soon')),
    );
  }

  void _copyMessage(MessageModel message) {
    if (message.content.isNotEmpty) {
      // Copy to clipboard
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message copied to clipboard')),
      );
    }
  }

  void _deleteMessage(MessageModel message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Call delete method
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Message deleted')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAIFeatures(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: DefaultTabController(
          length: 3,
          child: Column(
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Tab bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TabBar(
                  labelColor: AppTheme.primaryColor,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: AppTheme.primaryColor,
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.psychology),
                      text: 'Compatibility',
                    ),
                    Tab(
                      icon: Icon(Icons.chat_bubble_outline),
                      text: 'Starters',
                    ),
                    Tab(
                      icon: Icon(Icons.favorite),
                      text: 'Date Ideas',
                    ),
                  ],
                ),
              ),
              
              // Tab views
              Expanded(
                child: TabBarView(
                  children: [
                    // Compatibility Insights
                    SingleChildScrollView(
                      child: CompatibilityInsightsWidget(
                        userPersonality: 'Extrovert, Intuitive, Feeling, Perceiving',
                        userInterests: ['Travel', 'Music', 'Fitness', 'Food'],
                        partnerPersonality: 'Introvert, Sensing, Thinking, Judging',
                        partnerInterests: ['Books', 'Music', 'Art', 'Food'],
                      ),
                    ),
                    
                    // Conversation Starters
                    ConversationStartersWidget(
                      userPersonality: 'Extrovert, Intuitive, Feeling, Perceiving',
                      userInterests: ['Travel', 'Music', 'Fitness', 'Food'],
                      partnerPersonality: 'Introvert, Sensing, Thinking, Judging',
                      partnerInterests: ['Books', 'Music', 'Art', 'Food'],
                      onStarterSelected: (starter) {
                        Navigator.pop(ctx);
                        _messageController.text = starter;
                        _inputFocusNode.requestFocus();
                      },
                    ),
                    
                    // Virtual Date Ideas
                    VirtualDatePlannerWidget(
                      commonInterests: ['Music', 'Food'],
                      currentMood: 'fun',
                      onDateSelected: (dateIdea) {
                        Navigator.pop(ctx);
                        _showDatePlanConfirmation(dateIdea);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDatePlanConfirmation(Map<String, dynamic> dateIdea) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Text(dateIdea['icon'] ?? '💕'),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                dateIdea['title'] ?? 'Virtual Date',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dateIdea['description'] ?? ''),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  dateIdea['duration'] ?? '1 hour',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _sendMessage(); // You might want to customize this
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Suggested: ${dateIdea['title']}!'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Suggest This Date'),
          ),
        ],
      ),
    );
  }

  void _showBlockDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Block User'),
        content: const Text(
          'Are you sure you want to block this user? You won\'t receive messages from them anymore.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('User blocked')),
              );
            },
            child: const Text('Block', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Report User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Why are you reporting this user?'),
            const SizedBox(height: 16),
            ...['Spam', 'Harassment', 'Inappropriate content', 'Fake profile', 'Other'].map((reason) => 
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Radio<String>(
                  value: reason,
                  groupValue: null,
                  onChanged: (value) {},
                ),
                title: Text(reason),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Reported user for: $reason')),
                  );
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _startRecording() async {
    final micOk = await _ensurePermission(Permission.microphone);
    if (!micOk) return;
    final storageOk = await _ensurePermission(Permission.storage);
    if (!storageOk) return;
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    try {
      await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
      setState(() => _isRecording = true);
    } catch (_) {}
  }

  void _stopRecording() async {
    try {
      final filePath = await _recorder.stop();
      setState(() => _isRecording = false);
      if (filePath == null) return;
      final uid = _currentUserId;
      if (uid == null) return;
      final url = await ref.read(storageServiceProvider).uploadVoiceMessage(widget.chatId, File(filePath));
      await ref.read(chatServiceProvider).sendMessage(
            chatId: widget.chatId,
            senderId: uid,
            content: '',
            type: MessageType.audio,
            attachment: MessageAttachment(url: url, type: AttachmentType.audio),
          );
  await analyticsService.logSendMessage(chatId: widget.chatId, type: 'audio');
    } catch (e) {
      debugPrint('Send audio failed: $e');
      setState(() => _isRecording = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send audio')),
        );
      }
    }
  }
}

