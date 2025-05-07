// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'version_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VersionInfo _$VersionInfoFromJson(Map<String, dynamic> json) => VersionInfo(
  arguments:
      json['arguments'] == null
          ? null
          : Arguments.fromJson(json['arguments'] as Map<String, dynamic>),
  assetIndex:
      json['assetIndex'] == null
          ? null
          : AssetIndex.fromJson(json['assetIndex'] as Map<String, dynamic>),
  assets: json['assets'] as String?,
  complianceLevel: (json['complianceLevel'] as num?)?.toInt(),
  downloads:
      json['downloads'] == null
          ? null
          : Downloads.fromJson(json['downloads'] as Map<String, dynamic>),
  id: json['id'] as String?,
  javaVersion:
      json['javaVersion'] == null
          ? null
          : JavaVersion.fromJson(json['javaVersion'] as Map<String, dynamic>),
  libraries:
      (json['libraries'] as List<dynamic>?)
          ?.map((e) => Libraries.fromJson(e as Map<String, dynamic>))
          .toList(),
  logging:
      json['logging'] == null
          ? null
          : Logging.fromJson(json['logging'] as Map<String, dynamic>),
  mainClass: json['mainClass'] as String?,
  minimumLauncherVersion: (json['minimumLauncherVersion'] as num?)?.toInt(),
  releaseTime: VersionInfo._dateTimeFromString(json['releaseTime'] as String?),
  time: VersionInfo._dateTimeFromString(json['time'] as String?),
  type: json['type'] as String?,
  inheritsFrom: json['inheritsFrom'] as String?,
);

Map<String, dynamic> _$VersionInfoToJson(VersionInfo instance) =>
    <String, dynamic>{
      'arguments': instance.arguments,
      'assetIndex': instance.assetIndex,
      'assets': instance.assets,
      'complianceLevel': instance.complianceLevel,
      'downloads': instance.downloads,
      'id': instance.id,
      'javaVersion': instance.javaVersion,
      'libraries': instance.libraries,
      'logging': instance.logging,
      'mainClass': instance.mainClass,
      'minimumLauncherVersion': instance.minimumLauncherVersion,
      'releaseTime': VersionInfo._dateTimeToString(instance.releaseTime),
      'time': VersionInfo._dateTimeToString(instance.time),
      'type': instance.type,
      'inheritsFrom': instance.inheritsFrom,
    };

Arguments _$ArgumentsFromJson(Map<String, dynamic> json) => Arguments(
  game: Arguments._parseGameArguments(json['game']),
  jvm: Arguments._parseJvmArguments(json['jvm']),
);

Map<String, dynamic> _$ArgumentsToJson(Arguments instance) => <String, dynamic>{
  'game': instance.game,
  'jvm': instance.jvm,
};

GameArgument _$GameArgumentFromJson(Map<String, dynamic> json) => GameArgument(
  rules:
      (json['rules'] as List<dynamic>?)
          ?.map((e) => GameRules.fromJson(e as Map<String, dynamic>))
          .toList(),
  value: json['value'],
);

Map<String, dynamic> _$GameArgumentToJson(GameArgument instance) =>
    <String, dynamic>{'rules': instance.rules, 'value': instance.value};

GameRules _$GameRulesFromJson(Map<String, dynamic> json) => GameRules(
  action: json['action'] as String?,
  features:
      json['features'] == null
          ? null
          : Features.fromJson(json['features'] as Map<String, dynamic>),
);

Map<String, dynamic> _$GameRulesToJson(GameRules instance) => <String, dynamic>{
  'action': instance.action,
  'features': instance.features,
};

Features _$FeaturesFromJson(Map<String, dynamic> json) => Features(
  isDemoUser: json['is_demo_user'] as bool?,
  hasCustomResolution: json['has_custom_resolution'] as bool?,
  hasQuickPlaysSupport: json['has_quick_plays_support'] as bool?,
  isQuickPlaySingleplayer: json['is_quick_play_singleplayer'] as bool?,
  isQuickPlayMultiplayer: json['is_quick_play_multiplayer'] as bool?,
  isQuickPlayRealms: json['is_quick_play_realms'] as bool?,
);

Map<String, dynamic> _$FeaturesToJson(Features instance) => <String, dynamic>{
  'is_demo_user': instance.isDemoUser,
  'has_custom_resolution': instance.hasCustomResolution,
  'has_quick_plays_support': instance.hasQuickPlaysSupport,
  'is_quick_play_singleplayer': instance.isQuickPlaySingleplayer,
  'is_quick_play_multiplayer': instance.isQuickPlayMultiplayer,
  'is_quick_play_realms': instance.isQuickPlayRealms,
};

JvmArgument _$JvmArgumentFromJson(Map<String, dynamic> json) => JvmArgument(
  rules:
      (json['rules'] as List<dynamic>?)
          ?.map((e) => Rules.fromJson(e as Map<String, dynamic>))
          .toList(),
  value: json['value'],
);

Map<String, dynamic> _$JvmArgumentToJson(JvmArgument instance) =>
    <String, dynamic>{'rules': instance.rules, 'value': instance.value};

Rules _$RulesFromJson(Map<String, dynamic> json) => Rules(
  action: $enumDecodeNullable(_$ActionEnumMap, json['action']),
  os:
      json['os'] == null
          ? null
          : Os.fromJson(json['os'] as Map<String, dynamic>),
);

Map<String, dynamic> _$RulesToJson(Rules instance) => <String, dynamic>{
  'action': _$ActionEnumMap[instance.action],
  'os': instance.os,
};

const _$ActionEnumMap = {Action.allow: 'allow', Action.disallow: 'disallow'};

Os _$OsFromJson(Map<String, dynamic> json) => Os(
  name: $enumDecodeNullable(_$NameEnumMap, json['name']),
  arch: json['arch'] as String?,
);

Map<String, dynamic> _$OsToJson(Os instance) => <String, dynamic>{
  'name': _$NameEnumMap[instance.name],
  'arch': instance.arch,
};

const _$NameEnumMap = {
  Name.linux: 'linux',
  Name.osx: 'osx',
  Name.windows: 'windows',
};

AssetIndex _$AssetIndexFromJson(Map<String, dynamic> json) => AssetIndex(
  id: json['id'] as String?,
  sha1: json['sha1'] as String?,
  size: (json['size'] as num?)?.toInt(),
  totalSize: (json['totalSize'] as num?)?.toInt(),
  url: json['url'] as String?,
);

Map<String, dynamic> _$AssetIndexToJson(AssetIndex instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sha1': instance.sha1,
      'size': instance.size,
      'totalSize': instance.totalSize,
      'url': instance.url,
    };

Downloads _$DownloadsFromJson(Map<String, dynamic> json) => Downloads(
  client:
      json['client'] == null
          ? null
          : DownloadItem.fromJson(json['client'] as Map<String, dynamic>),
  clientMappings:
      json['client_mappings'] == null
          ? null
          : DownloadItem.fromJson(
            json['client_mappings'] as Map<String, dynamic>,
          ),
  server:
      json['server'] == null
          ? null
          : DownloadItem.fromJson(json['server'] as Map<String, dynamic>),
  serverMappings:
      json['server_mappings'] == null
          ? null
          : DownloadItem.fromJson(
            json['server_mappings'] as Map<String, dynamic>,
          ),
);

Map<String, dynamic> _$DownloadsToJson(Downloads instance) => <String, dynamic>{
  'client': instance.client,
  'client_mappings': instance.clientMappings,
  'server': instance.server,
  'server_mappings': instance.serverMappings,
};

DownloadItem _$DownloadItemFromJson(Map<String, dynamic> json) => DownloadItem(
  sha1: json['sha1'] as String?,
  size: (json['size'] as num?)?.toInt(),
  url: json['url'] as String?,
);

Map<String, dynamic> _$DownloadItemToJson(DownloadItem instance) =>
    <String, dynamic>{
      'sha1': instance.sha1,
      'size': instance.size,
      'url': instance.url,
    };

JavaVersion _$JavaVersionFromJson(Map<String, dynamic> json) => JavaVersion(
  component: json['component'] as String?,
  majorVersion: (json['majorVersion'] as num?)?.toInt(),
);

Map<String, dynamic> _$JavaVersionToJson(JavaVersion instance) =>
    <String, dynamic>{
      'component': instance.component,
      'majorVersion': instance.majorVersion,
    };

Libraries _$LibrariesFromJson(Map<String, dynamic> json) => Libraries(
  downloads:
      json['downloads'] == null
          ? null
          : LibraryDownloads.fromJson(
            json['downloads'] as Map<String, dynamic>,
          ),
  name: json['name'] as String?,
  rules:
      (json['rules'] as List<dynamic>?)
          ?.map((e) => Rules.fromJson(e as Map<String, dynamic>))
          .toList(),
  url: json['url'] as String?,
);

Map<String, dynamic> _$LibrariesToJson(Libraries instance) => <String, dynamic>{
  'downloads': instance.downloads,
  'name': instance.name,
  'rules': instance.rules,
  'url': instance.url,
};

LibraryDownloads _$LibraryDownloadsFromJson(Map<String, dynamic> json) =>
    LibraryDownloads(
      artifact:
          json['artifact'] == null
              ? null
              : Artifact.fromJson(json['artifact'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$LibraryDownloadsToJson(LibraryDownloads instance) =>
    <String, dynamic>{'artifact': instance.artifact};

Artifact _$ArtifactFromJson(Map<String, dynamic> json) => Artifact(
  path: json['path'] as String?,
  sha1: json['sha1'] as String?,
  size: (json['size'] as num?)?.toInt(),
  url: json['url'] as String?,
);

Map<String, dynamic> _$ArtifactToJson(Artifact instance) => <String, dynamic>{
  'path': instance.path,
  'sha1': instance.sha1,
  'size': instance.size,
  'url': instance.url,
};

Logging _$LoggingFromJson(Map<String, dynamic> json) => Logging(
  client:
      json['client'] == null
          ? null
          : LoggingClient.fromJson(json['client'] as Map<String, dynamic>),
);

Map<String, dynamic> _$LoggingToJson(Logging instance) => <String, dynamic>{
  'client': instance.client,
};

LoggingClient _$LoggingClientFromJson(Map<String, dynamic> json) =>
    LoggingClient(
      argument: json['argument'] as String?,
      file:
          json['file'] == null
              ? null
              : LoggingFile.fromJson(json['file'] as Map<String, dynamic>),
      type: json['type'] as String?,
    );

Map<String, dynamic> _$LoggingClientToJson(LoggingClient instance) =>
    <String, dynamic>{
      'argument': instance.argument,
      'file': instance.file,
      'type': instance.type,
    };

LoggingFile _$LoggingFileFromJson(Map<String, dynamic> json) => LoggingFile(
  id: json['id'] as String?,
  sha1: json['sha1'] as String?,
  size: (json['size'] as num?)?.toInt(),
  url: json['url'] as String?,
);

Map<String, dynamic> _$LoggingFileToJson(LoggingFile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sha1': instance.sha1,
      'size': instance.size,
      'url': instance.url,
    };
