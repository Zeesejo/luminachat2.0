import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String? text;
  final String? imageUrl;
  final String? audioUrl;
  final DateTime createdAt;
  final bool isRead;

  ChatMessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.createdAt,
    this.text,
    this.imageUrl,
    this.audioUrl,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() => {
        'chatId': chatId,
        'senderId': senderId,
        'text': text,
        'imageUrl': imageUrl,
        'audioUrl': audioUrl,
        'createdAt': Timestamp.fromDate(createdAt),
        'isRead': isRead,
      };

  static ChatMessageModel fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return ChatMessageModel(
      id: doc.id,
      chatId: d['chatId'] as String,
      senderId: d['senderId'] as String,
      text: d['text'] as String?,
      imageUrl: d['imageUrl'] as String?,
      audioUrl: d['audioUrl'] as String?,
      createdAt: (d['createdAt'] as Timestamp).toDate(),
      isRead: (d['isRead'] as bool?) ?? false,
    );
  }
}
