// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Account _$AccountFromJson(Map<String, dynamic> json) => Account(
  id: json['id'] as String,
  profile:
      json['profile'] == null
          ? null
          : MinecraftProfile.fromJson(json['profile'] as Map<String, dynamic>),
  xboxProfile:
      json['xboxProfile'] == null
          ? null
          : XboxProfile.fromJson(json['xboxProfile'] as Map<String, dynamic>),
  microsoftRefreshToken: json['microsoftRefreshToken'] as String?,
  xboxToken: json['xboxToken'] as String?,
  xboxTokenExpiry:
      json['xboxTokenExpiry'] == null
          ? null
          : DateTime.parse(json['xboxTokenExpiry'] as String),
  minecraftAccessToken: json['minecraftAccessToken'] as String?,
  minecraftTokenExpiry:
      json['minecraftTokenExpiry'] == null
          ? null
          : DateTime.parse(json['minecraftTokenExpiry'] as String),
  isActive: json['isActive'] as bool? ?? false,
  xuid: json['xuid'] as String?,
);

Map<String, dynamic> _$AccountToJson(Account instance) => <String, dynamic>{
  'id': instance.id,
  'profile': instance.profile,
  'xboxProfile': instance.xboxProfile,
  'microsoftRefreshToken': instance.microsoftRefreshToken,
  'xboxToken': instance.xboxToken,
  'xboxTokenExpiry': instance.xboxTokenExpiry?.toIso8601String(),
  'minecraftAccessToken': instance.minecraftAccessToken,
  'minecraftTokenExpiry': instance.minecraftTokenExpiry?.toIso8601String(),
  'isActive': instance.isActive,
  'xuid': instance.xuid,
};
