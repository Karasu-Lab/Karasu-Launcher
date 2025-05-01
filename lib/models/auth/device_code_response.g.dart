// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_code_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceCodeResponse _$DeviceCodeResponseFromJson(Map<String, dynamic> json) =>
    DeviceCodeResponse(
      deviceCode: json['device_code'] as String,
      userCode: json['user_code'] as String,
      verificationUri: json['verification_uri'] as String,
      interval: (json['interval'] as num).toInt(),
      expiresIn: (json['expires_in'] as num).toInt(),
    );

Map<String, dynamic> _$DeviceCodeResponseToJson(DeviceCodeResponse instance) =>
    <String, dynamic>{
      'device_code': instance.deviceCode,
      'user_code': instance.userCode,
      'verification_uri': instance.verificationUri,
      'interval': instance.interval,
      'expires_in': instance.expiresIn,
    };
