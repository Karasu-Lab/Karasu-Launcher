import 'dart:async';
import '../models/auth/device_code_response.dart';
import '../models/auth/microsoft_token_response.dart';
import '../models/auth/xbox_live_response.dart';
import '../models/auth/xsts_response.dart';
import '../models/auth/minecraft_token_response.dart';
import '../models/auth/minecraft_profile.dart';
import '../models/auth/xbox_profile.dart';
import 'auth/microsoft_auth_service.dart';
import 'auth/xbox_auth_service.dart';
import 'auth/minecraft_auth_service.dart';
import 'auth/constants.dart';
import 'auth/auth_events.dart';

/// 認証関連の機能を統合管理するサービスクラス
class AuthenticationService {
  static final AuthenticationService _instance =
      AuthenticationService._internal();

  factory AuthenticationService() {
    return _instance;
  }

  // 各認証サービスのインスタンス
  final MicrosoftAuthService _microsoftAuthService = MicrosoftAuthService();
  final XboxAuthService _xboxAuthService = XboxAuthService();
  final MinecraftAuthService _minecraftAuthService = MinecraftAuthService();

  LogCallback? _logCallback;

  AuthenticationService._internal();

  /// ログコールバックを設定する
  void setLogCallback(LogCallback callback) {
    _logCallback = callback;
    _microsoftAuthService.onLog = callback;
    _xboxAuthService.onLog = callback;
    _minecraftAuthService.onLog = callback;
  }

  /// Microsoft Device Codeを取得する
  Future<DeviceCodeResponse> getMicrosoftDeviceCode() async {
    return _microsoftAuthService.getMicrosoftDeviceCode();
  }

  /// Device Codeを使用してMicrosoftトークンを取得する（ポーリング）
  Future<MicrosoftTokenResponse> pollForMicrosoftToken(
    String deviceCode, {
    Duration pollingInterval = const Duration(seconds: 5),
  }) async {
    final tokenResponse = await _microsoftAuthService.pollForMicrosoftToken(
      deviceCode,
      pollingInterval: pollingInterval,
    );

    // リフレッシュトークンをキャッシュする
    _microsoftAuthService.cacheMicrosoftRefreshToken(
      tokenResponse.refreshToken,
    );

    return tokenResponse;
  }

  /// リフレッシュトークンを使用してMicrosoftトークンを更新する
  Future<MicrosoftTokenResponse> refreshMicrosoftToken(
    String refreshToken,
  ) async {
    return _microsoftAuthService.refreshMicrosoftToken(refreshToken);
  }

  /// Xbox Live認証を行う
  Future<XboxLiveResponse> authenticateWithXboxLive(
    String microsoftAccessToken,
  ) async {
    return _xboxAuthService.authenticateWithXboxLive(microsoftAccessToken);
  }

  /// Xboxプロフィール情報を取得する
  Future<XboxProfile> getXboxProfile(String xstsToken, String xboxToken) async {
    return _xboxAuthService.getXboxProfile(xstsToken, xboxToken);
  }

  /// XSTSトークンを取得する
  Future<XstsResponse> getXstsToken(String xblToken) async {
    return _xboxAuthService.getXstsToken(xblToken);
  }

  /// XSTSトークンからXuid（Xboxユーザーの一意識別子）を取得する
  Future<String> getXuidFromToken(String uhs, String xstsToken) async {
    return _xboxAuthService.getXuidFromToken(uhs, xstsToken);
  }

  /// Minecraftアクセストークンを取得する
  Future<MinecraftTokenResponse> getMinecraftAccessToken(
    String uhs,
    String xstsToken,
  ) async {
    return _minecraftAuthService.getMinecraftAccessToken(uhs, xstsToken);
  }

  /// Minecraftの所有権を確認する
  Future<bool> checkMinecraftOwnership(String accessToken) async {
    return _minecraftAuthService.checkMinecraftOwnership(accessToken);
  }

  /// Minecraftプロファイルを取得する
  Future<MinecraftProfile> getMinecraftProfile(String accessToken) async {
    return _minecraftAuthService.getMinecraftProfile(accessToken);
  }

  /// リフレッシュトークンをキャッシュから取得する
  String? getMicrosoftRefreshToken() {
    return _microsoftAuthService.getRefreshToken();
  }

  /// Xboxトークンをキャッシュから取得する
  String? getXboxToken() {
    return _xboxAuthService.getXboxToken();
  }

  /// Minecraftトークンをキャッシュから取得する
  String? getMinecraftToken() {
    return _minecraftAuthService.getMinecraftToken();
  }

  /// 全てのキャッシュをクリアする
  void clearAllCaches() {
    _microsoftAuthService.clearCache();
    _xboxAuthService.clearCache();
    _minecraftAuthService.clearCache();
  }

  /// 認証イベントを通知する
  void logAuthEvent(AuthEvent event) {
    if (_logCallback != null) {
      _logCallback!(event.toString());
    }
  }
}
