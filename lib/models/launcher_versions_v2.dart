import 'package:json_annotation/json_annotation.dart';

part 'launcher_versions_v2.g.dart';

@JsonSerializable()
class LauncherVersionsV2 {
  final LatestVersions latest;
  final List<MinecraftVersion> versions;

  LauncherVersionsV2({required this.latest, required this.versions});

  factory LauncherVersionsV2.fromJson(Map<String, dynamic> json) =>
      _$LauncherVersionsV2FromJson(json);

  Map<String, dynamic> toJson() => _$LauncherVersionsV2ToJson(this);
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

  MinecraftVersion({
    required this.id,
    required this.type,
    required this.url,
    required this.time,
    required this.releaseTime,
    required this.sha1,
    required this.complianceLevel,
  });

  factory MinecraftVersion.fromJson(Map<String, dynamic> json) =>
      _$MinecraftVersionFromJson(json);

  Map<String, dynamic> toJson() => _$MinecraftVersionToJson(this);
}
