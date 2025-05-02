// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'microsoft_account.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MicrosoftAccount _$MicrosoftAccountFromJson(Map<String, dynamic> json) =>
    MicrosoftAccount(
      userName: json['user_name'] as String?,
      refreshToken: json['refreshToken'] as String,
      minecraftToken: json['minecraftToken'] as String?,
      minecraftTokenExpiry:
          json['minecraftTokenExpiry'] == null
              ? null
              : DateTime.parse(json['minecraftTokenExpiry'] as String),
      xboxToken: json['xboxToken'] as String?,
      xboxTokenExpiry:
          json['xboxTokenExpiry'] == null
              ? null
              : DateTime.parse(json['xboxTokenExpiry'] as String),
      minecraftProfile:
          json['minecraftProfile'] == null
              ? null
              : MinecraftProfile.fromJson(
                json['minecraftProfile'] as Map<String, dynamic>,
              ),
    );

Map<String, dynamic> _$MicrosoftAccountToJson(MicrosoftAccount instance) =>
    <String, dynamic>{
      'user_name': instance.userName,
      'refreshToken': instance.refreshToken,
      'minecraftToken': instance.minecraftToken,
      'minecraftTokenExpiry': instance.minecraftTokenExpiry?.toIso8601String(),
      'xboxToken': instance.xboxToken,
      'xboxTokenExpiry': instance.xboxTokenExpiry?.toIso8601String(),
      'minecraftProfile': instance.minecraftProfile,
    };
