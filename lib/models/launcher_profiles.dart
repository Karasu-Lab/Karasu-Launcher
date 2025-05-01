import 'package:json_annotation/json_annotation.dart';

part 'launcher_profiles.g.dart';

@JsonSerializable()
class LauncherProfiles {
  @JsonKey(name: 'profiles')
  final Map<String, Profile> profiles;

  @JsonKey(name: 'settings')
  final Settings settings;

  @JsonKey(name: 'version')
  final int version;

  LauncherProfiles({
    required this.profiles,
    required this.settings,
    required this.version,
  });

  factory LauncherProfiles.fromJson(Map<String, dynamic> json) =>
      _$LauncherProfilesFromJson(json);

  Map<String, dynamic> toJson() => _$LauncherProfilesToJson(this);
}

@JsonSerializable()
class Profile {
  @JsonKey(name: 'created')
  final String? created;

  @JsonKey(name: 'gameDir')
  final String? gameDir;

  @JsonKey(name: 'icon')
  final String? icon;

  @JsonKey(name: 'javaArgs')
  final String? javaArgs;

  @JsonKey(name: 'javaDir')
  final String? javaDir;

  @JsonKey(name: 'lastUsed')
  final String? lastUsed;

  @JsonKey(name: 'lastVersionId')
  final String? lastVersionId;

  @JsonKey(name: 'name')
  final String? name;

  @JsonKey(name: 'type')
  final String? type;

  @JsonKey(name: 'skipJreVersionCheck')
  final bool? skipJreVersionCheck;

  @JsonKey(name: 'order')
  final int? order; // 並び順を追加

  Profile({
    this.created,
    this.gameDir,
    this.icon,
    this.javaArgs,
    this.javaDir,
    this.lastUsed,
    this.lastVersionId,
    this.name,
    this.type,
    this.skipJreVersionCheck,
    this.order,
  });

  factory Profile.fromJson(Map<String, dynamic> json) =>
      _$ProfileFromJson(json);

  Map<String, dynamic> toJson() => _$ProfileToJson(this);
}

@JsonSerializable()
class Settings {
  @JsonKey(name: 'crashAssistance')
  final bool? crashAssistance;

  @JsonKey(name: 'enableAdvanced')
  final bool? enableAdvanced;

  @JsonKey(name: 'enableAnalytics')
  final bool? enableAnalytics;

  @JsonKey(name: 'enableHistorical')
  final bool? enableHistorical;

  @JsonKey(name: 'enableReleases')
  final bool? enableReleases;

  @JsonKey(name: 'enableSnapshots')
  final bool? enableSnapshots;

  @JsonKey(name: 'keepLauncherOpen')
  final bool? keepLauncherOpen;

  @JsonKey(name: 'profileSorting')
  final String? profileSorting;

  @JsonKey(name: 'showGameLog')
  final bool? showGameLog;

  @JsonKey(name: 'showMenu')
  final bool? showMenu;

  @JsonKey(name: 'soundOn')
  final bool? soundOn;

  Settings({
    this.crashAssistance,
    this.enableAdvanced,
    this.enableAnalytics,
    this.enableHistorical,
    this.enableReleases,
    this.enableSnapshots,
    this.keepLauncherOpen,
    this.profileSorting,
    this.showGameLog,
    this.showMenu,
    this.soundOn,
  });

  factory Settings.fromJson(Map<String, dynamic> json) =>
      _$SettingsFromJson(json);

  Map<String, dynamic> toJson() => _$SettingsToJson(this);
}
