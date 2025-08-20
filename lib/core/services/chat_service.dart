import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:injectable/injectable.dart';

import '../utils/constants.dart';
import '../utils/exceptions.dart';
import '../../shared/models/chat_model.dart';

@singleton
class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user's chats
  Stream<List<ChatModel>> getUserChats(String userId) {
    // Fetch with a single array-contains filter to avoid composite index requirement,
    // then filter and sort client-side.
    return _firestore
        .collection(AppConstants.firestoreChatsCollection)
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          final chats = snapshot.docs
              .map((doc) => ChatModel.fromFirestore(doc))
              .where((c) => c.isActive)
              .toList();
          chats.sort((a, b) {
            final ta = a.lastMessageTimestamp ?? a.updatedAt;
            final tb = b.lastMessageTimestamp ?? b.updatedAt;
            return tb.compareTo(ta);
          });
          return chats;
        });
  }

  // Get specific chat
  Future<ChatModel?> getChat(String chatId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.firestoreChatsCollection)
          .doc(chatId)
          .get();

      if (!doc.exists) return null;
      return ChatModel.fromFirestore(doc);
    } catch (e) {
      throw AppException('Failed to get chat: $e');
    }
  }

  // Create or get existing chat between two users
  Future<ChatModel> createOrGetDirectChat(String userId1, String userId2) async {
    try {
      // Try to find pre-existing direct chat without needing multiple filters
      final existingChats = await _firestore
          .collection(AppConstants.firestoreChatsCollection)
          .where('participants', arrayContains: userId1)
          .limit(25)
          .get();

      for (final doc in existingChats.docs) {
        final chat = ChatModel.fromFirestore(doc);
        if (chat.type == ChatType.direct &&
            chat.participants.length == 2 &&
            chat.participants.contains(userId2)) {
          return chat;
        }
      }

      // Create new chat
      final newChat = ChatModel(
        id: '',
        participants: [userId1, userId2],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        type: ChatType.direct,
      );

  final docRef = await _firestore
          .collection(AppConstants.firestoreChatsCollection)
          .add(newChat.toFirestore());

      return newChat.copyWith(id: docRef.id);
    } catch (e) {
      throw AppException('Failed to create or get chat: $e');
    }
  }

  // Get messages for a chat
  Stream<List<MessageModel>> getChatMessages(String chatId) {
  return _firestore
        .collection(AppConstants.firestoreChatsCollection)
        .doc(chatId)
        .collection(AppConstants.firestoreMessagesCollection)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromFirestore(doc))
            .toList());
  }

  // Send message
  Future<MessageModel> sendMessage({
    required String chatId,
    required String senderId,
    required String content,
    required MessageType type,
    MessageAttachment? attachment,
    String? replyToMessageId,
  }) async {
    try {
      final message = MessageModel(
        id: '',
        chatId: chatId,
        senderId: senderId,
        content: content,
        type: type,
        timestamp: DateTime.now(),
        attachment: attachment,
        replyToMessageId: replyToMessageId,
      );

      // Add message to subcollection
      final docRef = await _firestore
          .collection(AppConstants.firestoreChatsCollection)
          .doc(chatId)
          .collection(AppConstants.firestoreMessagesCollection)
          .add(message.toFirestore());

      final savedMessage = message.copyWith(id: docRef.id);

      // Update chat with last message info
      await _updateChatLastMessage(chatId, savedMessage);

      return savedMessage;
    } catch (e) {
      throw AppException('Failed to send message: $e');
    }
  }

  // Update message status
  Future<void> updateMessageStatus(
    String chatId,
    String messageId,
    MessageStatus status,
  ) async {
    try {
      await _firestore
          .collection(AppConstants.firestoreChatsCollection)
          .doc(chatId)
          .collection(AppConstants.firestoreMessagesCollection)
          .doc(messageId)
          .update({'status': status.toString().split('.').last});
    } catch (e) {
      throw AppException('Failed to update message status: $e');
    }
  }

  // Mark message as read
  Future<void> markMessageAsRead(
    String chatId,
    String messageId,
    String userId,
  ) async {
    try {
      await _firestore
          .collection(AppConstants.firestoreChatsCollection)
          .doc(chatId)
          .collection(AppConstants.firestoreMessagesCollection)
          .doc(messageId)
          .update({
        'readBy.$userId': Timestamp.now(),
      });

      // Update unread count in chat
      await _updateUnreadCount(chatId, userId);
    } catch (e) {
      throw AppException('Failed to mark message as read: $e');
    }
  }

  // Mark all messages in chat as read
  Future<void> markChatAsRead(String chatId, String userId) async {
    try {
      // Update chat's lastRead timestamp
      await _firestore
          .collection(AppConstants.firestoreChatsCollection)
          .doc(chatId)
          .update({
        'lastRead.$userId': Timestamp.now(),
        'unreadCounts.$userId': 0,
      });
    } catch (e) {
      throw AppException('Failed to mark chat as read: $e');
    }
  }

  // Delete message
  Future<void> deleteMessage(String chatId, String messageId) async {
    try {
      await _firestore
          .collection(AppConstants.firestoreChatsCollection)
          .doc(chatId)
          .collection(AppConstants.firestoreMessagesCollection)
          .doc(messageId)
          .update({
        'isDeleted': true,
        'content': 'This message was deleted',
      });
    } catch (e) {
      throw AppException('Failed to delete message: $e');
    }
  }

  // Edit message
  Future<void> editMessage(
    String chatId,
    String messageId,
    String newContent,
  ) async {
    try {
      await _firestore
          .collection(AppConstants.firestoreChatsCollection)
          .doc(chatId)
          .collection(AppConstants.firestoreMessagesCollection)
          .doc(messageId)
          .update({
        'content': newContent,
        'isEdited': true,
        'editedAt': Timestamp.now(),
      });
    } catch (e) {
      throw AppException('Failed to edit message: $e');
    }
  }

  // Add reaction to message
  Future<void> addReaction(
    String chatId,
    String messageId,
    String userId,
    String emoji,
  ) async {
    try {
      await _firestore
          .collection(AppConstants.firestoreChatsCollection)
          .doc(chatId)
          .collection(AppConstants.firestoreMessagesCollection)
          .doc(messageId)
          .update({
        'reactions.$userId': emoji,
      });
    } catch (e) {
      throw AppException('Failed to add reaction: $e');
    }
  }

  // Remove reaction from message
  Future<void> removeReaction(
    String chatId,
    String messageId,
    String userId,
  ) async {
    try {
      await _firestore
          .collection(AppConstants.firestoreChatsCollection)
          .doc(chatId)
          .collection(AppConstants.firestoreMessagesCollection)
          .doc(messageId)
          .update({
        'reactions.$userId': FieldValue.delete(),
      });
    } catch (e) {
      throw AppException('Failed to remove reaction: $e');
    }
  }

  // Set typing indicator
  Future<void> setTypingIndicator(
    String chatId,
    String userId,
    bool isTyping,
  ) async {
    try {
      await _firestore
          .collection('typing_indicators')
          .doc('${chatId}_$userId')
          .set({
        'chatId': chatId,
        'userId': userId,
        'isTyping': isTyping,
        'timestamp': Timestamp.now(),
      });
    } catch (e) {
      // Swallow to avoid disrupting chat input on strict rules
      // debugPrint('Typing indicator write ignored: $e');
    }
  }

  // Get typing indicators for chat
  Stream<List<String>> getTypingIndicators(String chatId, String currentUserId) {
    return _firestore
        .collection('typing_indicators')
        .where('chatId', isEqualTo: chatId)
        .where('isTyping', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .where((doc) => doc.data()['userId'] != currentUserId)
            .where((doc) {
              final timestamp = doc.data()['timestamp'] as Timestamp;
              final now = DateTime.now();
              final diff = now.difference(timestamp.toDate());
              return diff.inSeconds < 10; // Consider typing if updated within 10 seconds
            })
            .map((doc) => doc.data()['userId'] as String)
            .toList());
  }

  // Delete chat
  Future<void> deleteChat(String chatId) async {
    try {
      await _firestore
          .collection(AppConstants.firestoreChatsCollection)
          .doc(chatId)
          .update({'isActive': false});
    } catch (e) {
      throw AppException('Failed to delete chat: $e');
    }
  }

  // Private helper methods
  Future<void> _updateChatLastMessage(String chatId, MessageModel message) async {
    await _firestore
        .collection(AppConstants.firestoreChatsCollection)
        .doc(chatId)
        .set({
      'participants': FieldValue.arrayUnion([message.senderId]),
      'lastMessage': message.content,
      'lastMessageSenderId': message.senderId,
      'lastMessageTimestamp': Timestamp.fromDate(message.timestamp),
      'updatedAt': Timestamp.now(),
      'isActive': true,
    }, SetOptions(merge: true));
  }

  Future<void> _updateUnreadCount(String chatId, String userId) async {
    // Reset unread count for the user who read the message
    await _firestore
        .collection(AppConstants.firestoreChatsCollection)
        .doc(chatId)
        .update({
      'unreadCounts.$userId': 0,
    });
  }
}

// Provider for ChatService
final chatServiceProvider = Provider<ChatService>((ref) => ChatService());

// Provider for user's chats
final userChatsProvider = StreamProvider.family<List<ChatModel>, String>((ref, userId) {
  final chatService = ref.read(chatServiceProvider);
  return chatService.getUserChats(userId);
});

// Provider for chat messages
final chatMessagesProvider = StreamProvider.family<List<MessageModel>, String>((ref, chatId) {
  final chatService = ref.read(chatServiceProvider);
  return chatService.getChatMessages(chatId);
});

// Provider for typing indicators
final typingIndicatorsProvider = StreamProvider.family<List<String>, ({String chatId, String userId})>((ref, params) {
  final chatService = ref.read(chatServiceProvider);
  return chatService.getTypingIndicators(params.chatId, params.userId);
});
