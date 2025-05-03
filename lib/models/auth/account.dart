import 'package:json_annotation/json_annotation.dart';
import 'minecraft_profile.dart';
import 'xbox_profile.dart';

part 'account.g.dart';

/// アカウント情報を格納するモデルクラス
@JsonSerializable()
class Account {
  /// アカウントID（内部管理用）
  @JsonKey(name: 'id')
  final String id;

  /// プロフィール情報
  @JsonKey(name: 'profile')
  MinecraftProfile? profile;

  /// Xboxプロフィール情報
  @JsonKey(name: 'xboxProfile')
  XboxProfile? xboxProfile;

  /// Microsoft リフレッシュトークン
  @JsonKey(name: 'microsoftRefreshToken')
  String? microsoftRefreshToken;

  /// Xbox トークン
  @JsonKey(name: 'xboxToken')
  String? xboxToken;

  /// Xbox トークン有効期限
  @JsonKey(name: 'xboxTokenExpiry')
  DateTime? xboxTokenExpiry;

  /// Minecraft アクセストークン
  @JsonKey(name: 'minecraftAccessToken')
  String? minecraftAccessToken;

  /// Minecraft トークン有効期限
  @JsonKey(name: 'minecraftTokenExpiry')
  DateTime? minecraftTokenExpiry;

  /// アカウントが有効かどうか
  @JsonKey(name: 'isActive')
  bool isActive;

  @JsonKey(name: 'xuid')
  String? xuid;

  /// コンストラクタ
  Account({
    required this.id,
    this.profile,
    this.xboxProfile,
    this.microsoftRefreshToken,
    this.xboxToken,
    this.xboxTokenExpiry,
    this.minecraftAccessToken,
    this.minecraftTokenExpiry,
    this.isActive = false,
    this.xuid,
  });

  /// JSONからAccountを作成
  factory Account.fromJson(Map<String, dynamic> json) => 
      _$AccountFromJson(json);

  /// AccountをJSONに変換
  Map<String, dynamic> toJson() => _$AccountToJson(this);

  /// アクセストークンが有効かどうか
  bool get hasValidMinecraftToken {
    return minecraftAccessToken != null &&
        minecraftTokenExpiry != null &&
        minecraftTokenExpiry!.isAfter(DateTime.now());
  }

  /// Xboxトークンが有効かどうか
  bool get hasValidXboxToken {
    return xboxToken != null &&
        xboxTokenExpiry != null &&
        xboxTokenExpiry!.isAfter(DateTime.now());
  }
  
  /// リフレッシュトークンを持っているかどうか
  bool get hasRefreshToken {
    return microsoftRefreshToken != null;
  }

  /// アカウントのコピーを作成（値の更新用）
  Account copyWith({
    String? id,
    MinecraftProfile? profile,
    XboxProfile? xboxProfile,
    String? microsoftRefreshToken,
    String? xboxToken,
    DateTime? xboxTokenExpiry,
    String? minecraftAccessToken,
    DateTime? minecraftTokenExpiry,
    bool? isActive,
    String? xuid,
  }) {
    return Account(
      id: id ?? this.id,
      profile: profile ?? this.profile,
      xboxProfile: xboxProfile ?? this.xboxProfile,
      microsoftRefreshToken: microsoftRefreshToken ?? this.microsoftRefreshToken,
      xboxToken: xboxToken ?? this.xboxToken,
      xboxTokenExpiry: xboxTokenExpiry ?? this.xboxTokenExpiry,
      minecraftAccessToken: minecraftAccessToken ?? this.minecraftAccessToken,
      minecraftTokenExpiry: minecraftTokenExpiry ?? this.minecraftTokenExpiry,
      isActive: isActive ?? this.isActive,
      xuid: xuid ?? this.xuid,
    );
  }
}
