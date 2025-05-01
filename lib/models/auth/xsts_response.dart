import 'package:json_annotation/json_annotation.dart';
import 'xbox_live_response.dart';

part 'xsts_response.g.dart';

@JsonSerializable()
class XstsResponse {
  @JsonKey(name: 'Token')
  final String token;

  @JsonKey(name: 'DisplayClaims')
  final DisplayClaims displayClaims;

  XstsResponse({required this.token, required this.displayClaims});

  factory XstsResponse.fromJson(Map<String, dynamic> json) =>
      _$XstsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$XstsResponseToJson(this);
}
