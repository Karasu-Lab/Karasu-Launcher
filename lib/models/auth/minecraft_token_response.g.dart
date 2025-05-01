// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'minecraft_token_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MinecraftTokenResponse _$MinecraftTokenResponseFromJson(
  Map<String, dynamic> json,
) => MinecraftTokenResponse(
  accessToken: json['access_token'] as String,
  expiresIn: (json['expires_in'] as num).toInt(),
);

Map<String, dynamic> _$MinecraftTokenResponseToJson(
  MinecraftTokenResponse instance,
) => <String, dynamic>{
  'access_token': instance.accessToken,
  'expires_in': instance.expiresIn,
};
