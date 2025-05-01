// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'xbox_live_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

XboxLiveResponse _$XboxLiveResponseFromJson(Map<String, dynamic> json) =>
    XboxLiveResponse(
      token: json['Token'] as String,
      displayClaims: DisplayClaims.fromJson(
        json['DisplayClaims'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$XboxLiveResponseToJson(XboxLiveResponse instance) =>
    <String, dynamic>{
      'Token': instance.token,
      'DisplayClaims': instance.displayClaims,
    };

DisplayClaims _$DisplayClaimsFromJson(Map<String, dynamic> json) =>
    DisplayClaims(
      xui:
          (json['xui'] as List<dynamic>)
              .map((e) => XuiClaim.fromJson(e as Map<String, dynamic>))
              .toList(),
    );

Map<String, dynamic> _$DisplayClaimsToJson(DisplayClaims instance) =>
    <String, dynamic>{'xui': instance.xui};

XuiClaim _$XuiClaimFromJson(Map<String, dynamic> json) =>
    XuiClaim(uhs: json['uhs'] as String);

Map<String, dynamic> _$XuiClaimToJson(XuiClaim instance) => <String, dynamic>{
  'uhs': instance.uhs,
};
