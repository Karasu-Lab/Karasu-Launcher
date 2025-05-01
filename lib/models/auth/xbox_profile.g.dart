// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'xbox_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

XboxProfile _$XboxProfileFromJson(Map<String, dynamic> json) => XboxProfile(
  gamertag: json['gamertag'] as String,
  xuid: json['xuid'] as String,
  profileImageUrl: json['profileImageUrl'] as String?,
  modernGamertag: json['modernGamertag'] as String?,
  modernGamertagSuffix: json['modernGamertagSuffix'] as String?,
  uniqueModernGamertag: json['uniqueModernGamertag'] as String?,
);

Map<String, dynamic> _$XboxProfileToJson(XboxProfile instance) =>
    <String, dynamic>{
      'gamertag': instance.gamertag,
      'xuid': instance.xuid,
      'profileImageUrl': instance.profileImageUrl,
      'modernGamertag': instance.modernGamertag,
      'modernGamertagSuffix': instance.modernGamertagSuffix,
      'uniqueModernGamertag': instance.uniqueModernGamertag,
    };
