// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'screenshot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Screenshot _$ScreenshotFromJson(Map<String, dynamic> json) => Screenshot(
  id: json['id'] as String?,
  filePath: json['filePath'] as String,
  profileId: json['profileId'] as String,
  comment: json['comment'] as String?,
  createdAt:
      json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
  metadata: json['metadata'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$ScreenshotToJson(Screenshot instance) =>
    <String, dynamic>{
      'id': instance.id,
      'filePath': instance.filePath,
      'profileId': instance.profileId,
      'comment': instance.comment,
      'createdAt': instance.createdAt.toIso8601String(),
      'metadata': instance.metadata,
    };
