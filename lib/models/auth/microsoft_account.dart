import 'package:json_annotation/json_annotation.dart';
import 'minecraft_profile.dart';

part 'microsoft_account.g.dart';

/// Microsoftアカウント情報を格納するモデルクラス
@JsonSerializable()
class MicrosoftAccount {
  /// ユーザー名
  @JsonKey(name: 'user_name')
  final String? userName;

  /// Microsoftリフレッシュトークン
  @JsonKey(name: 'refreshToken')
  final String refreshToken;

  /// Minecraftトークン
  @JsonKey(name: 'minecraftToken')
  final String? minecraftToken;

  /// Minecraftトークン有効期限
  @JsonKey(name: 'minecraftTokenExpiry')
  final DateTime? minecraftTokenExpiry;

  /// Xboxトークン
  @JsonKey(name: 'xboxToken')
  final String? xboxToken;

  /// Xboxトークン有効期限
  @JsonKey(name: 'xboxTokenExpiry')
  final DateTime? xboxTokenExpiry;

  /// Minecraftプロファイル
  @JsonKey(name: 'minecraftProfile')
  final MinecraftProfile? minecraftProfile;

  MicrosoftAccount({
    this.userName,
    required this.refreshToken,
    this.minecraftToken,
    this.minecraftTokenExpiry,
    this.xboxToken,
    this.xboxTokenExpiry,
    this.minecraftProfile,
  });

  /// JSONからMicrosoftAccountを作成
  factory MicrosoftAccount.fromJson(Map<String, dynamic> json) =>
      _$MicrosoftAccountFromJson(json);

  /// MicrosoftAccountをJSONに変換
  Map<String, dynamic> toJson() => _$MicrosoftAccountToJson(this);

  /// Minecraftトークンが有効かどうか
  bool get hasValidMinecraftToken {
    return minecraftToken != null &&
        minecraftTokenExpiry != null &&
        minecraftTokenExpiry!.isAfter(DateTime.now());
  }

  /// Xboxトークンが有効かどうか
  bool get hasValidXboxToken {
    return xboxToken != null &&
        xboxTokenExpiry != null &&
        xboxTokenExpiry!.isAfter(DateTime.now());
  }

  /// アカウントのコピーを作成（値の更新用）
  MicrosoftAccount copyWith({
    String? userName,
    String? refreshToken,
    String? minecraftToken,
    DateTime? minecraftTokenExpiry,
    String? xboxToken,
    DateTime? xboxTokenExpiry,
    MinecraftProfile? minecraftProfile,
  }) {
    return MicrosoftAccount(
      userName: userName ?? this.userName,
      refreshToken: refreshToken ?? this.refreshToken,
      minecraftToken: minecraftToken ?? this.minecraftToken,
      minecraftTokenExpiry: minecraftTokenExpiry ?? this.minecraftTokenExpiry,
      xboxToken: xboxToken ?? this.xboxToken,
      xboxTokenExpiry: xboxTokenExpiry ?? this.xboxTokenExpiry,
      minecraftProfile: minecraftProfile ?? this.minecraftProfile,
    );
  }
}
