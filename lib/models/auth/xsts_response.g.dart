// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'xsts_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

XstsResponse _$XstsResponseFromJson(Map<String, dynamic> json) => XstsResponse(
  token: json['Token'] as String,
  displayClaims: DisplayClaims.fromJson(
    json['DisplayClaims'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$XstsResponseToJson(XstsResponse instance) =>
    <String, dynamic>{
      'Token': instance.token,
      'DisplayClaims': instance.displayClaims,
    };
