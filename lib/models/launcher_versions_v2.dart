import 'package:json_annotation/json_annotation.dart';
import 'package:karasu_launcher/models/mod_loader.dart';

part 'launcher_versions_v2.g.dart';

@JsonSerializable()
class LauncherVersionsV2 {
  final LatestVersions latest;
  final List<MinecraftVersion> versions;

  LauncherVersionsV2({required this.latest, required this.versions});

  factory LauncherVersionsV2.fromJson(Map<String, dynamic> json) =>
      _$LauncherVersionsV2FromJson(json);

  Map<String, dynamic> toJson() => _$LauncherVersionsV2ToJson(this);
  
  /// オンラインとローカルのバージョンを結合する
  LauncherVersionsV2 mergeWithLocalVersions(List<MinecraftVersion> localVersions) {
    // ローカルバージョンとオンラインバージョンのIDが重複する場合はローカルを優先
    final Map<String, MinecraftVersion> versionMap = {};
    
    // オンラインバージョンを追加
    for (final version in versions) {
      versionMap[version.id] = version;
    }
    
    // ローカルバージョンを追加（上書き）
    for (final localVersion in localVersions) {
      versionMap[localVersion.id] = localVersion;
    }
    
    return LauncherVersionsV2(
      latest: latest,
      versions: versionMap.values.toList(),
    );
  }
}

@JsonSerializable()
class LatestVersions {
  final String release;
  final String snapshot;

  LatestVersions({required this.release, required this.snapshot});

  factory LatestVersions.fromJson(Map<String, dynamic> json) =>
      _$LatestVersionsFromJson(json);

  Map<String, dynamic> toJson() => _$LatestVersionsToJson(this);
}

@JsonSerializable()
class MinecraftVersion {
  final String id;
  final String type;
  final String url;
  final String time;
  final String releaseTime;
  final String sha1;
  final int complianceLevel;
  
  @JsonKey(includeIfNull: false)
  final ModLoader? modLoader;
  
  @JsonKey(includeIfNull: false)
  final bool? isLocal;
  
  @JsonKey(includeIfNull: false)
  final String? localPath;

  MinecraftVersion({
    required this.id,
    required this.type,
    required this.url,
    required this.time,
    required this.releaseTime,
    required this.sha1,
    required this.complianceLevel,
    this.modLoader,
    this.isLocal,
    this.localPath,
  });

  factory MinecraftVersion.fromJson(Map<String, dynamic> json) =>
      _$MinecraftVersionFromJson(json);

  Map<String, dynamic> toJson() => _$MinecraftVersionToJson(this);
  
  /// ローカルのバージョンを作成する（MOD情報含む）
  factory MinecraftVersion.fromLocalVersion({
    required String id,
    required String type,
    required String localPath,
    ModLoader? modLoader,
  }) {
    final now = DateTime.now().toIso8601String();
    
    return MinecraftVersion(
      id: id,
      type: modLoader != null ? '${modLoader.type.toDisplayString().toLowerCase()}-$type' : type,
      url: 'file://$localPath',
      time: now,
      releaseTime: now,
      sha1: '',  // ローカルバージョンはSHA1が不要
      complianceLevel: 0,
      modLoader: modLoader,
      isLocal: true,
      localPath: localPath,
    );
  }
  
  /// バージョン表示のための整形された名前を取得する
  String getDisplayName() {
    if (modLoader != null) {
      return '$id (${modLoader!.type.toDisplayString()} ${modLoader!.version})';
    }
    return id;
  }
}
