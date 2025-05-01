// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'launcher_profiles.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LauncherProfiles _$LauncherProfilesFromJson(Map<String, dynamic> json) =>
    LauncherProfiles(
      profiles: (json['profiles'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, Profile.fromJson(e as Map<String, dynamic>)),
      ),
      settings: Settings.fromJson(json['settings'] as Map<String, dynamic>),
      version: (json['version'] as num).toInt(),
    );

Map<String, dynamic> _$LauncherProfilesToJson(LauncherProfiles instance) =>
    <String, dynamic>{
      'profiles': instance.profiles,
      'settings': instance.settings,
      'version': instance.version,
    };

Profile _$ProfileFromJson(Map<String, dynamic> json) => Profile(
  created: json['created'] as String?,
  gameDir: json['gameDir'] as String?,
  icon: json['icon'] as String?,
  javaArgs: json['javaArgs'] as String?,
  javaDir: json['javaDir'] as String?,
  lastUsed: json['lastUsed'] as String?,
  lastVersionId: json['lastVersionId'] as String?,
  name: json['name'] as String?,
  type: json['type'] as String?,
  skipJreVersionCheck: json['skipJreVersionCheck'] as bool?,
  order: (json['order'] as num?)?.toInt(),
);

Map<String, dynamic> _$ProfileToJson(Profile instance) => <String, dynamic>{
  'created': instance.created,
  'gameDir': instance.gameDir,
  'icon': instance.icon,
  'javaArgs': instance.javaArgs,
  'javaDir': instance.javaDir,
  'lastUsed': instance.lastUsed,
  'lastVersionId': instance.lastVersionId,
  'name': instance.name,
  'type': instance.type,
  'skipJreVersionCheck': instance.skipJreVersionCheck,
  'order': instance.order,
};

Settings _$SettingsFromJson(Map<String, dynamic> json) => Settings(
  crashAssistance: json['crashAssistance'] as bool?,
  enableAdvanced: json['enableAdvanced'] as bool?,
  enableAnalytics: json['enableAnalytics'] as bool?,
  enableHistorical: json['enableHistorical'] as bool?,
  enableReleases: json['enableReleases'] as bool?,
  enableSnapshots: json['enableSnapshots'] as bool?,
  keepLauncherOpen: json['keepLauncherOpen'] as bool?,
  profileSorting: json['profileSorting'] as String?,
  showGameLog: json['showGameLog'] as bool?,
  showMenu: json['showMenu'] as bool?,
  soundOn: json['soundOn'] as bool?,
);

Map<String, dynamic> _$SettingsToJson(Settings instance) => <String, dynamic>{
  'crashAssistance': instance.crashAssistance,
  'enableAdvanced': instance.enableAdvanced,
  'enableAnalytics': instance.enableAnalytics,
  'enableHistorical': instance.enableHistorical,
  'enableReleases': instance.enableReleases,
  'enableSnapshots': instance.enableSnapshots,
  'keepLauncherOpen': instance.keepLauncherOpen,
  'profileSorting': instance.profileSorting,
  'showGameLog': instance.showGameLog,
  'showMenu': instance.showMenu,
  'soundOn': instance.soundOn,
};
