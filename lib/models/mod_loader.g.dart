// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mod_loader.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ModLoader _$ModLoaderFromJson(Map<String, dynamic> json) => ModLoader(
  type: $enumDecode(_$ModLoaderTypeEnumMap, json['type']),
  version: json['version'] as String,
  baseGameVersion: json['baseGameVersion'] as String,
  inheritsFrom: json['inheritsFrom'] as String?,
  mainClass: json['mainClass'] as String?,
  releaseTime: json['releaseTime'] as String?,
  time: json['time'] as String?,
  id: json['id'] as String?,
  arguments: json['arguments'] as Map<String, dynamic>?,
  libraries:
      (json['libraries'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
);

Map<String, dynamic> _$ModLoaderToJson(ModLoader instance) => <String, dynamic>{
  'type': _$ModLoaderTypeEnumMap[instance.type]!,
  'version': instance.version,
  'baseGameVersion': instance.baseGameVersion,
  'inheritsFrom': instance.inheritsFrom,
  'mainClass': instance.mainClass,
  'releaseTime': instance.releaseTime,
  'time': instance.time,
  'id': instance.id,
  'arguments': instance.arguments,
  'libraries': instance.libraries,
};

const _$ModLoaderTypeEnumMap = {
  ModLoaderType.fabric: 'fabric',
  ModLoaderType.forge: 'forge',
  ModLoaderType.quilt: 'quilt',
  ModLoaderType.liteloader: 'liteloader',
  ModLoaderType.other: 'other',
};
