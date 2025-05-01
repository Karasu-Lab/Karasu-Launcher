// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'microsoft_token_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MicrosoftTokenResponse _$MicrosoftTokenResponseFromJson(
  Map<String, dynamic> json,
) => MicrosoftTokenResponse(
  accessToken: json['access_token'] as String,
  refreshToken: json['refresh_token'] as String,
  expiresIn: (json['expires_in'] as num).toInt(),
);

Map<String, dynamic> _$MicrosoftTokenResponseToJson(
  MicrosoftTokenResponse instance,
) => <String, dynamic>{
  'access_token': instance.accessToken,
  'refresh_token': instance.refreshToken,
  'expires_in': instance.expiresIn,
};
