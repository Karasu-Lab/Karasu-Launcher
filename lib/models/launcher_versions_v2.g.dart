// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'launcher_versions_v2.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LauncherVersionsV2 _$LauncherVersionsV2FromJson(Map<String, dynamic> json) =>
    LauncherVersionsV2(
      latest: LatestVersions.fromJson(json['latest'] as Map<String, dynamic>),
      versions:
          (json['versions'] as List<dynamic>)
              .map((e) => MinecraftVersion.fromJson(e as Map<String, dynamic>))
              .toList(),
    );

Map<String, dynamic> _$LauncherVersionsV2ToJson(LauncherVersionsV2 instance) =>
    <String, dynamic>{'latest': instance.latest, 'versions': instance.versions};

LatestVersions _$LatestVersionsFromJson(Map<String, dynamic> json) =>
    LatestVersions(
      release: json['release'] as String,
      snapshot: json['snapshot'] as String,
    );

Map<String, dynamic> _$LatestVersionsToJson(LatestVersions instance) =>
    <String, dynamic>{
      'release': instance.release,
      'snapshot': instance.snapshot,
    };

MinecraftVersion _$MinecraftVersionFromJson(Map<String, dynamic> json) =>
    MinecraftVersion(
      id: json['id'] as String,
      type: json['type'] as String,
      url: json['url'] as String,
      time: json['time'] as String,
      releaseTime: json['releaseTime'] as String,
      sha1: json['sha1'] as String,
      complianceLevel: (json['complianceLevel'] as num).toInt(),
      modLoader:
          json['modLoader'] == null
              ? null
              : ModLoader.fromJson(json['modLoader'] as Map<String, dynamic>),
      isLocal: json['isLocal'] as bool?,
      localPath: json['localPath'] as String?,
    );

Map<String, dynamic> _$MinecraftVersionToJson(MinecraftVersion instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'url': instance.url,
      'time': instance.time,
      'releaseTime': instance.releaseTime,
      'sha1': instance.sha1,
      'complianceLevel': instance.complianceLevel,
      if (instance.modLoader case final value?) 'modLoader': value,
      if (instance.isLocal case final value?) 'isLocal': value,
      if (instance.localPath case final value?) 'localPath': value,
    };
