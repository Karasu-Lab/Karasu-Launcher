import 'package:json_annotation/json_annotation.dart';

part 'xbox_profile.g.dart';

/// Xboxプロフィール情報を格納するモデルクラス
@JsonSerializable()
class XboxProfile {
  /// ゲーマータグ
  @JsonKey(name: 'gamertag')
  final String gamertag;

  /// Xuid（Xbox固有ID）
  @JsonKey(name: 'xuid')
  final String xuid;

  /// プロフィール画像URL
  @JsonKey(name: 'profileImageUrl')
  final String? profileImageUrl;

  /// モダンゲーマータグ
  @JsonKey(name: 'modernGamertag')
  final String? modernGamertag;

  /// モダンゲーマータグサフィックス
  @JsonKey(name: 'modernGamertagSuffix')
  final String? modernGamertagSuffix;

  /// ユニークモダンゲーマータグ
  @JsonKey(name: 'uniqueModernGamertag')
  final String? uniqueModernGamertag;

  /// コンストラクタ
  XboxProfile({
    required this.gamertag,
    required this.xuid,
    this.profileImageUrl,
    this.modernGamertag,
    this.modernGamertagSuffix,
    this.uniqueModernGamertag,
  });

  /// JSONからXboxProfileを作成
  factory XboxProfile.fromJson(Map<String, dynamic> json) =>
      _$XboxProfileFromJson(json);

  /// XboxProfileをJSONに変換
  Map<String, dynamic> toJson() => _$XboxProfileToJson(this);
}
