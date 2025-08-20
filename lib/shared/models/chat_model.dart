import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'chat_model.g.dart';

@JsonSerializable()
class ChatModel {
  final String id;
  final List<String> participants;
  final String? lastMessage;
  final String? lastMessageSenderId;
  final DateTime? lastMessageTimestamp;
  final Map<String, int> unreadCounts;
  final Map<String, DateTime> lastRead;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final ChatType type;

  ChatModel({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.lastMessageSenderId,
    this.lastMessageTimestamp,
    this.unreadCounts = const {},
    this.lastRead = const {},
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.type = ChatType.direct,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) => _$ChatModelFromJson(json);
  Map<String, dynamic> toJson() => _$ChatModelToJson(this);

  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    final raw = (doc.data() ?? {}) as Map<String, dynamic>;
    final data = Map<String, dynamic>.from(raw);

    DateTime _tsOrNow(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) {
        try { return DateTime.parse(v); } catch (_) {}
      }
      return DateTime.now();
    }

    DateTime? _tsOrNull(dynamic v) {
      if (v == null) return null;
      if (v is Timestamp) return v.toDate();
      if (v is String) { try { return DateTime.parse(v); } catch (_) { return null; } }
      return null;
    }

    final createdAt = _tsOrNow(data['createdAt']);
    final updatedAt = _tsOrNow(data['updatedAt']);
    final lastMsgAt = _tsOrNull(data['lastMessageTimestamp']);

    final lastReadMap = <String, String>{};
    final lr = data['lastRead'];
    if (lr is Map) {
      lr.forEach((k, v) {
        final dt = _tsOrNull(v);
        if (dt != null) lastReadMap[k.toString()] = dt.toIso8601String();
      });
    }

    final participants = (data['participants'] as List?)?.map((e) => e.toString()).toList() ?? <String>[];

    return ChatModel.fromJson({
      ...data,
      'id': doc.id,
      'participants': participants,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastMessageTimestamp': lastMsgAt?.toIso8601String(),
      'lastRead': lastReadMap,
    });
  }

  Map<String, dynamic> toFirestore() {
    final json = toJson();
    return {
      ...json,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastMessageTimestamp': lastMessageTimestamp != null
          ? Timestamp.fromDate(lastMessageTimestamp!)
          : null,
      'lastRead': lastRead.map(
        (key, value) => MapEntry(key, Timestamp.fromDate(value)),
      ),
    }..remove('id');
  }

  int getUnreadCount(String userId) => unreadCounts[userId] ?? 0;

  String getOtherParticipant(String currentUserId) {
    return participants.firstWhere((id) => id != currentUserId);
  }

  ChatModel copyWith({
    String? id,
    List<String>? participants,
    String? lastMessage,
    String? lastMessageSenderId,
    DateTime? lastMessageTimestamp,
    Map<String, int>? unreadCounts,
    Map<String, DateTime>? lastRead,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    ChatType? type,
  }) {
    return ChatModel(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      lastMessageTimestamp: lastMessageTimestamp ?? this.lastMessageTimestamp,
      unreadCounts: unreadCounts ?? this.unreadCounts,
      lastRead: lastRead ?? this.lastRead,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      type: type ?? this.type,
    );
  }
}

@JsonSerializable()
class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final MessageStatus status;
  final Map<String, DateTime> readBy;
  final String? replyToMessageId;
  final Map<String, String> reactions;
  final MessageAttachment? attachment;
  final bool isEdited;
  final DateTime? editedAt;
  final bool isDeleted;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    required this.type,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.readBy = const {},
    this.replyToMessageId,
    this.reactions = const {},
    this.attachment,
    this.isEdited = false,
    this.editedAt,
    this.isDeleted = false,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) => _$MessageModelFromJson(json);
  Map<String, dynamic> toJson() => _$MessageModelToJson(this);

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel.fromJson({
      'id': doc.id,
      ...data,
      'timestamp': (data['timestamp'] as Timestamp).toDate().toIso8601String(),
      'editedAt': data['editedAt'] != null
          ? (data['editedAt'] as Timestamp).toDate().toIso8601String()
          : null,
      'readBy': (data['readBy'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, (value as Timestamp).toDate().toIso8601String()),
      ) ?? {},
    });
  }

  Map<String, dynamic> toFirestore() {
    final json = toJson();
    return {
      ...json,
  // Ensure nested attachment is serialized to a Map for Firestore
  'attachment': attachment?.toJson(),
      'timestamp': Timestamp.fromDate(timestamp),
      'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
      'readBy': readBy.map(
        (key, value) => MapEntry(key, Timestamp.fromDate(value)),
      ),
    }..remove('id');
  }

  bool isReadBy(String userId) => readBy.containsKey(userId);

  MessageModel copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    MessageStatus? status,
    Map<String, DateTime>? readBy,
    String? replyToMessageId,
    Map<String, String>? reactions,
    MessageAttachment? attachment,
    bool? isEdited,
    DateTime? editedAt,
    bool? isDeleted,
  }) {
    return MessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      readBy: readBy ?? this.readBy,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      reactions: reactions ?? this.reactions,
      attachment: attachment ?? this.attachment,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}

@JsonSerializable()
class MessageAttachment {
  final String url;
  final AttachmentType type;
  final String? fileName;
  final int? fileSize;
  final String? mimeType;
  final ImageMetadata? imageMetadata;
  final AudioMetadata? audioMetadata;

  MessageAttachment({
    required this.url,
    required this.type,
    this.fileName,
    this.fileSize,
    this.mimeType,
    this.imageMetadata,
    this.audioMetadata,
  });

  factory MessageAttachment.fromJson(Map<String, dynamic> json) => 
      _$MessageAttachmentFromJson(json);
  Map<String, dynamic> toJson() => _$MessageAttachmentToJson(this);
}

@JsonSerializable()
class ImageMetadata {
  final int width;
  final int height;
  final String? thumbnailUrl;

  ImageMetadata({
    required this.width,
    required this.height,
    this.thumbnailUrl,
  });

  factory ImageMetadata.fromJson(Map<String, dynamic> json) => 
      _$ImageMetadataFromJson(json);
  Map<String, dynamic> toJson() => _$ImageMetadataToJson(this);
}

@JsonSerializable()
class AudioMetadata {
  final int duration; // in milliseconds
  final List<double>? waveform;

  AudioMetadata({
    required this.duration,
    this.waveform,
  });

  factory AudioMetadata.fromJson(Map<String, dynamic> json) => 
      _$AudioMetadataFromJson(json);
  Map<String, dynamic> toJson() => _$AudioMetadataToJson(this);
}

enum ChatType {
  @JsonValue('direct')
  direct,
  @JsonValue('group')
  group,
}

enum MessageType {
  @JsonValue('text')
  text,
  @JsonValue('image')
  image,
  @JsonValue('audio')
  audio,
  @JsonValue('video')
  video,
  @JsonValue('file')
  file,
  @JsonValue('location')
  location,
  @JsonValue('system')
  system,
}

enum MessageStatus {
  @JsonValue('sending')
  sending,
  @JsonValue('sent')
  sent,
  @JsonValue('delivered')
  delivered,
  @JsonValue('read')
  read,
  @JsonValue('failed')
  failed,
}

enum AttachmentType {
  @JsonValue('image')
  image,
  @JsonValue('audio')
  audio,
  @JsonValue('video')
  video,
  @JsonValue('file')
  file,
}
