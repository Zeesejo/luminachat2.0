// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatModel _$ChatModelFromJson(Map<String, dynamic> json) => ChatModel(
      id: json['id'] as String,
      participants: (json['participants'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      lastMessage: json['lastMessage'] as String?,
      lastMessageSenderId: json['lastMessageSenderId'] as String?,
      lastMessageTimestamp: json['lastMessageTimestamp'] == null
          ? null
          : DateTime.parse(json['lastMessageTimestamp'] as String),
      unreadCounts: (json['unreadCounts'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toInt()),
          ) ??
          const {},
      lastRead: (json['lastRead'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, DateTime.parse(e as String)),
          ) ??
          const {},
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
      type: $enumDecodeNullable(_$ChatTypeEnumMap, json['type']) ??
          ChatType.direct,
    );

Map<String, dynamic> _$ChatModelToJson(ChatModel instance) => <String, dynamic>{
      'id': instance.id,
      'participants': instance.participants,
      'lastMessage': instance.lastMessage,
      'lastMessageSenderId': instance.lastMessageSenderId,
      'lastMessageTimestamp': instance.lastMessageTimestamp?.toIso8601String(),
      'unreadCounts': instance.unreadCounts,
      'lastRead':
          instance.lastRead.map((k, e) => MapEntry(k, e.toIso8601String())),
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'isActive': instance.isActive,
      'type': _$ChatTypeEnumMap[instance.type]!,
    };

const _$ChatTypeEnumMap = {
  ChatType.direct: 'direct',
  ChatType.group: 'group',
};

MessageModel _$MessageModelFromJson(Map<String, dynamic> json) => MessageModel(
      id: json['id'] as String,
      chatId: json['chatId'] as String,
      senderId: json['senderId'] as String,
      content: json['content'] as String,
      type: $enumDecode(_$MessageTypeEnumMap, json['type']),
      timestamp: DateTime.parse(json['timestamp'] as String),
      status: $enumDecodeNullable(_$MessageStatusEnumMap, json['status']) ??
          MessageStatus.sent,
      readBy: (json['readBy'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, DateTime.parse(e as String)),
          ) ??
          const {},
      replyToMessageId: json['replyToMessageId'] as String?,
      reactions: (json['reactions'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
      attachment: json['attachment'] == null
          ? null
          : MessageAttachment.fromJson(
              json['attachment'] as Map<String, dynamic>),
      isEdited: json['isEdited'] as bool? ?? false,
      editedAt: json['editedAt'] == null
          ? null
          : DateTime.parse(json['editedAt'] as String),
      isDeleted: json['isDeleted'] as bool? ?? false,
    );

Map<String, dynamic> _$MessageModelToJson(MessageModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'chatId': instance.chatId,
      'senderId': instance.senderId,
      'content': instance.content,
      'type': _$MessageTypeEnumMap[instance.type]!,
      'timestamp': instance.timestamp.toIso8601String(),
      'status': _$MessageStatusEnumMap[instance.status]!,
      'readBy': instance.readBy.map((k, e) => MapEntry(k, e.toIso8601String())),
      'replyToMessageId': instance.replyToMessageId,
      'reactions': instance.reactions,
      'attachment': instance.attachment,
      'isEdited': instance.isEdited,
      'editedAt': instance.editedAt?.toIso8601String(),
      'isDeleted': instance.isDeleted,
    };

const _$MessageTypeEnumMap = {
  MessageType.text: 'text',
  MessageType.image: 'image',
  MessageType.audio: 'audio',
  MessageType.video: 'video',
  MessageType.file: 'file',
  MessageType.location: 'location',
  MessageType.system: 'system',
};

const _$MessageStatusEnumMap = {
  MessageStatus.sending: 'sending',
  MessageStatus.sent: 'sent',
  MessageStatus.delivered: 'delivered',
  MessageStatus.read: 'read',
  MessageStatus.failed: 'failed',
};

MessageAttachment _$MessageAttachmentFromJson(Map<String, dynamic> json) =>
    MessageAttachment(
      url: json['url'] as String,
      type: $enumDecode(_$AttachmentTypeEnumMap, json['type']),
      fileName: json['fileName'] as String?,
      fileSize: (json['fileSize'] as num?)?.toInt(),
      mimeType: json['mimeType'] as String?,
      imageMetadata: json['imageMetadata'] == null
          ? null
          : ImageMetadata.fromJson(
              json['imageMetadata'] as Map<String, dynamic>),
      audioMetadata: json['audioMetadata'] == null
          ? null
          : AudioMetadata.fromJson(
              json['audioMetadata'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MessageAttachmentToJson(MessageAttachment instance) =>
    <String, dynamic>{
      'url': instance.url,
      'type': _$AttachmentTypeEnumMap[instance.type]!,
      'fileName': instance.fileName,
      'fileSize': instance.fileSize,
      'mimeType': instance.mimeType,
      'imageMetadata': instance.imageMetadata,
      'audioMetadata': instance.audioMetadata,
    };

const _$AttachmentTypeEnumMap = {
  AttachmentType.image: 'image',
  AttachmentType.audio: 'audio',
  AttachmentType.video: 'video',
  AttachmentType.file: 'file',
};

ImageMetadata _$ImageMetadataFromJson(Map<String, dynamic> json) =>
    ImageMetadata(
      width: (json['width'] as num).toInt(),
      height: (json['height'] as num).toInt(),
      thumbnailUrl: json['thumbnailUrl'] as String?,
    );

Map<String, dynamic> _$ImageMetadataToJson(ImageMetadata instance) =>
    <String, dynamic>{
      'width': instance.width,
      'height': instance.height,
      'thumbnailUrl': instance.thumbnailUrl,
    };

AudioMetadata _$AudioMetadataFromJson(Map<String, dynamic> json) =>
    AudioMetadata(
      duration: (json['duration'] as num).toInt(),
      waveform: (json['waveform'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
    );

Map<String, dynamic> _$AudioMetadataToJson(AudioMetadata instance) =>
    <String, dynamic>{
      'duration': instance.duration,
      'waveform': instance.waveform,
    };
