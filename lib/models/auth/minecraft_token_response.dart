import 'package:json_annotation/json_annotation.dart';

part 'minecraft_token_response.g.dart';

@JsonSerializable()
class MinecraftTokenResponse {
  @JsonKey(name: 'access_token')
  final String accessToken;

  @JsonKey(name: 'expires_in')
  final int expiresIn;

  MinecraftTokenResponse({required this.accessToken, required this.expiresIn});

  factory MinecraftTokenResponse.fromJson(Map<String, dynamic> json) =>
      _$MinecraftTokenResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MinecraftTokenResponseToJson(this);
}
