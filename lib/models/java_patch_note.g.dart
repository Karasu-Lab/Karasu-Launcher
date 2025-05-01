// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'java_patch_note.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

JavaPatchNote _$JavaPatchNoteFromJson(Map<String, dynamic> json) =>
    JavaPatchNote(
      version: (json['version'] as num).toInt(),
      entries:
          (json['entries'] as List<dynamic>)
              .map(
                (e) => JavaPatchNoteEntry.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
    );

Map<String, dynamic> _$JavaPatchNoteToJson(JavaPatchNote instance) =>
    <String, dynamic>{'version': instance.version, 'entries': instance.entries};

JavaPatchNoteEntry _$JavaPatchNoteEntryFromJson(Map<String, dynamic> json) =>
    JavaPatchNoteEntry(
      title: json['title'] as String,
      version: json['version'] as String,
      body: json['body'] as String,
      type: json['type'] as String?,
      id: json['id'] as String?,
      contentPath: json['contentPath'] as String?,
      image:
          json['image'] == null
              ? null
              : JavaPatchNoteImage.fromJson(
                json['image'] as Map<String, dynamic>,
              ),
    );

Map<String, dynamic> _$JavaPatchNoteEntryToJson(JavaPatchNoteEntry instance) =>
    <String, dynamic>{
      'title': instance.title,
      'version': instance.version,
      'body': instance.body,
      'type': instance.type,
      'id': instance.id,
      'contentPath': instance.contentPath,
      'image': instance.image,
    };

JavaPatchNoteImage _$JavaPatchNoteImageFromJson(Map<String, dynamic> json) =>
    JavaPatchNoteImage(
      url: json['url'] as String,
      title: json['title'] as String,
    );

Map<String, dynamic> _$JavaPatchNoteImageToJson(JavaPatchNoteImage instance) =>
    <String, dynamic>{'url': instance.url, 'title': instance.title};
