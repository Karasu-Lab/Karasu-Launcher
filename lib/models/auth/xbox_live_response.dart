import 'package:json_annotation/json_annotation.dart';

part 'xbox_live_response.g.dart';

@JsonSerializable()
class XboxLiveResponse {
  @JsonKey(name: 'Token')
  final String token;

  @JsonKey(name: 'DisplayClaims')
  final DisplayClaims displayClaims;

  XboxLiveResponse({required this.token, required this.displayClaims});

  factory XboxLiveResponse.fromJson(Map<String, dynamic> json) =>
      _$XboxLiveResponseFromJson(json);

  Map<String, dynamic> toJson() => _$XboxLiveResponseToJson(this);
}

@JsonSerializable()
class DisplayClaims {
  final List<XuiClaim> xui;

  DisplayClaims({required this.xui});

  factory DisplayClaims.fromJson(Map<String, dynamic> json) =>
      _$DisplayClaimsFromJson(json);

  Map<String, dynamic> toJson() => _$DisplayClaimsToJson(this);
}

@JsonSerializable()
class XuiClaim {
  final String uhs;

  XuiClaim({required this.uhs});

  factory XuiClaim.fromJson(Map<String, dynamic> json) =>
      _$XuiClaimFromJson(json);

  Map<String, dynamic> toJson() => _$XuiClaimToJson(this);
}
