import 'package:json_annotation/json_annotation.dart';

part 'microsoft_token_response.g.dart';

@JsonSerializable()
class MicrosoftTokenResponse {
  @JsonKey(name: 'access_token')
  final String accessToken;

  @JsonKey(name: 'refresh_token')
  final String refreshToken;

  @JsonKey(name: 'expires_in')
  final int expiresIn;

  MicrosoftTokenResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  factory MicrosoftTokenResponse.fromJson(Map<String, dynamic> json) =>
      _$MicrosoftTokenResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MicrosoftTokenResponseToJson(this);
}
