import 'package:json_annotation/json_annotation.dart';

part 'device_code_response.g.dart';

@JsonSerializable()
class DeviceCodeResponse {
  @JsonKey(name: 'device_code')
  final String deviceCode;

  @JsonKey(name: 'user_code')
  final String userCode;

  @JsonKey(name: 'verification_uri')
  final String verificationUri;

  final int interval;

  @JsonKey(name: 'expires_in')
  final int expiresIn;

  DeviceCodeResponse({
    required this.deviceCode,
    required this.userCode,
    required this.verificationUri,
    required this.interval,
    required this.expiresIn,
  });

  factory DeviceCodeResponse.fromJson(Map<String, dynamic> json) =>
      _$DeviceCodeResponseFromJson(json);

  Map<String, dynamic> toJson() => _$DeviceCodeResponseToJson(this);
}
