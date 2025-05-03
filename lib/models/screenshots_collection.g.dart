// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'screenshots_collection.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ScreenshotsCollection _$ScreenshotsCollectionFromJson(
  Map<String, dynamic> json,
) => ScreenshotsCollection(
  screenshots: (json['screenshots'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, Screenshot.fromJson(e as Map<String, dynamic>)),
  ),
  lastUpdated:
      json['lastUpdated'] == null
          ? null
          : DateTime.parse(json['lastUpdated'] as String),
);

Map<String, dynamic> _$ScreenshotsCollectionToJson(
  ScreenshotsCollection instance,
) => <String, dynamic>{
  'screenshots': instance.screenshots,
  'lastUpdated': instance.lastUpdated.toIso8601String(),
};
