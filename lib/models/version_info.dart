import 'package:json_annotation/json_annotation.dart';

part 'version_info.g.dart';

enum Action {
  @JsonValue("allow")
  allow,
}

enum Name {
  @JsonValue("linux")
  linux,
  @JsonValue("osx")
  osx,
  @JsonValue("windows")
  windows,
}

@JsonSerializable()
class VersionInfo {
  Arguments? arguments;
  AssetIndex? assetIndex;
  String? assets;
  int? complianceLevel;
  Downloads? downloads;
  String? id;
  JavaVersion? javaVersion;
  List<Libraries>? libraries;
  Logging? logging;
  String? mainClass;
  int? minimumLauncherVersion;
  @JsonKey(fromJson: _dateTimeFromString, toJson: _dateTimeToString)
  DateTime? releaseTime;
  @JsonKey(fromJson: _dateTimeFromString, toJson: _dateTimeToString)
  DateTime? time;
  String? type;

  VersionInfo({
    this.arguments,
    this.assetIndex,
    this.assets,
    this.complianceLevel,
    this.downloads,
    this.id,
    this.javaVersion,
    this.libraries,
    this.logging,
    this.mainClass,
    this.minimumLauncherVersion,
    this.releaseTime,
    this.time,
    this.type,
  });

  factory VersionInfo.fromJson(Map<String, dynamic> json) =>
      _$VersionInfoFromJson(json);

  Map<String, dynamic> toJson() => _$VersionInfoToJson(this);

  static DateTime? _dateTimeFromString(String? date) =>
      date == null ? null : DateTime.parse(date);

  static String? _dateTimeToString(DateTime? date) => date?.toIso8601String();
}

@JsonSerializable()
class Arguments {
  @JsonKey(fromJson: _parseGameArguments)
  List<GameArgument>? game;
  
  @JsonKey(fromJson: _parseJvmArguments)
  List<JvmArgument>? jvm;

  Arguments({this.game, this.jvm});

  factory Arguments.fromJson(Map<String, dynamic> json) =>
      _$ArgumentsFromJson(json);

  Map<String, dynamic> toJson() => _$ArgumentsToJson(this);
  
  static List<GameArgument>? _parseGameArguments(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      return value.map((e) {
        if (e is String) {
          return GameArgument(value: e);
        } else if (e is Map<String, dynamic>) {
          return GameArgument.fromJson(e);
        }
        throw FormatException('予期しない引数の形式: $e');
      }).toList();
    }
    throw FormatException('予期しないgame引数の形式: $value');
  }
  
  static List<JvmArgument>? _parseJvmArguments(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      return value.map((e) {
        if (e is String) {
          return JvmArgument(value: e);
        } else if (e is Map<String, dynamic>) {
          return JvmArgument.fromJson(e);
        }
        throw FormatException('予期しない引数の形式: $e');
      }).toList();
    }
    throw FormatException('予期しないjvm引数の形式: $value');
  }
}

@JsonSerializable()
class GameArgument {
  List<GameRules>? rules;
  dynamic value; // 文字列または文字列のリストになり得る

  GameArgument({this.rules, this.value});

  factory GameArgument.fromJson(Map<String, dynamic> json) =>
      _$GameArgumentFromJson(json);

  Map<String, dynamic> toJson() => _$GameArgumentToJson(this);
}

@JsonSerializable()
class GameRules {
  String? action;
  Features? features;

  GameRules({this.action, this.features});

  factory GameRules.fromJson(Map<String, dynamic> json) =>
      _$GameRulesFromJson(json);

  Map<String, dynamic> toJson() => _$GameRulesToJson(this);
}

@JsonSerializable()
class Features {
  @JsonKey(name: 'is_demo_user')
  bool? isDemoUser;

  @JsonKey(name: 'has_custom_resolution')
  bool? hasCustomResolution;

  @JsonKey(name: 'has_quick_plays_support')
  bool? hasQuickPlaysSupport;

  @JsonKey(name: 'is_quick_play_singleplayer')
  bool? isQuickPlaySingleplayer;

  @JsonKey(name: 'is_quick_play_multiplayer')
  bool? isQuickPlayMultiplayer;

  @JsonKey(name: 'is_quick_play_realms')
  bool? isQuickPlayRealms;

  Features({
    this.isDemoUser,
    this.hasCustomResolution,
    this.hasQuickPlaysSupport,
    this.isQuickPlaySingleplayer,
    this.isQuickPlayMultiplayer,
    this.isQuickPlayRealms,
  });

  factory Features.fromJson(Map<String, dynamic> json) =>
      _$FeaturesFromJson(json);

  Map<String, dynamic> toJson() => _$FeaturesToJson(this);
}

@JsonSerializable()
class JvmArgument {
  List<Rules>? rules;
  dynamic value; // 文字列または文字列のリストになり得る

  JvmArgument({this.rules, this.value});

  factory JvmArgument.fromJson(Map<String, dynamic> json) =>
      _$JvmArgumentFromJson(json);

  Map<String, dynamic> toJson() => _$JvmArgumentToJson(this);
}

@JsonSerializable()
class Rules {
  Action? action;
  Os? os;

  Rules({this.action, this.os});

  factory Rules.fromJson(Map<String, dynamic> json) => _$RulesFromJson(json);

  Map<String, dynamic> toJson() => _$RulesToJson(this);
}

@JsonSerializable()
class Os {
  Name? name;
  String? arch;

  Os({this.name, this.arch});

  factory Os.fromJson(Map<String, dynamic> json) => _$OsFromJson(json);

  Map<String, dynamic> toJson() => _$OsToJson(this);
}

@JsonSerializable()
class AssetIndex {
  String? id;
  String? sha1;
  int? size;
  int? totalSize;
  String? url;

  AssetIndex({this.id, this.sha1, this.size, this.totalSize, this.url});

  factory AssetIndex.fromJson(Map<String, dynamic> json) =>
      _$AssetIndexFromJson(json);

  Map<String, dynamic> toJson() => _$AssetIndexToJson(this);
}

@JsonSerializable()
class Downloads {
  @JsonKey(name: 'client')
  DownloadItem? client;

  @JsonKey(name: 'client_mappings')
  DownloadItem? clientMappings;

  @JsonKey(name: 'server')
  DownloadItem? server;

  @JsonKey(name: 'server_mappings')
  DownloadItem? serverMappings;

  Downloads({
    this.client,
    this.clientMappings,
    this.server,
    this.serverMappings,
  });

  factory Downloads.fromJson(Map<String, dynamic> json) =>
      _$DownloadsFromJson(json);

  Map<String, dynamic> toJson() => _$DownloadsToJson(this);
}

@JsonSerializable()
class DownloadItem {
  String? sha1;
  int? size;
  String? url;

  DownloadItem({this.sha1, this.size, this.url});

  factory DownloadItem.fromJson(Map<String, dynamic> json) =>
      _$DownloadItemFromJson(json);

  Map<String, dynamic> toJson() => _$DownloadItemToJson(this);
}

@JsonSerializable()
class JavaVersion {
  String? component;
  int? majorVersion;

  JavaVersion({this.component, this.majorVersion});

  factory JavaVersion.fromJson(Map<String, dynamic> json) =>
      _$JavaVersionFromJson(json);

  Map<String, dynamic> toJson() => _$JavaVersionToJson(this);
}

@JsonSerializable()
class Libraries {
  LibraryDownloads? downloads;
  String? name;
  List<Rules>? rules;

  Libraries({this.downloads, this.name, this.rules});

  factory Libraries.fromJson(Map<String, dynamic> json) =>
      _$LibrariesFromJson(json);

  Map<String, dynamic> toJson() => _$LibrariesToJson(this);
}

@JsonSerializable()
class LibraryDownloads {
  Artifact? artifact;

  LibraryDownloads({this.artifact});

  factory LibraryDownloads.fromJson(Map<String, dynamic> json) =>
      _$LibraryDownloadsFromJson(json);

  Map<String, dynamic> toJson() => _$LibraryDownloadsToJson(this);
}

@JsonSerializable()
class Artifact {
  String? path;
  String? sha1;
  int? size;
  String? url;

  Artifact({this.path, this.sha1, this.size, this.url});

  factory Artifact.fromJson(Map<String, dynamic> json) =>
      _$ArtifactFromJson(json);

  Map<String, dynamic> toJson() => _$ArtifactToJson(this);
}

@JsonSerializable()
class Logging {
  LoggingClient? client;

  Logging({this.client});

  factory Logging.fromJson(Map<String, dynamic> json) =>
      _$LoggingFromJson(json);

  Map<String, dynamic> toJson() => _$LoggingToJson(this);
}

@JsonSerializable()
class LoggingClient {
  String? argument;
  LoggingFile? file;
  String? type;

  LoggingClient({this.argument, this.file, this.type});

  factory LoggingClient.fromJson(Map<String, dynamic> json) =>
      _$LoggingClientFromJson(json);

  Map<String, dynamic> toJson() => _$LoggingClientToJson(this);
}

@JsonSerializable()
class LoggingFile {
  String? id;
  String? sha1;
  int? size;
  String? url;

  LoggingFile({this.id, this.sha1, this.size, this.url});

  factory LoggingFile.fromJson(Map<String, dynamic> json) =>
      _$LoggingFileFromJson(json);

  Map<String, dynamic> toJson() => _$LoggingFileToJson(this);
}
