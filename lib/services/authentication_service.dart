import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth/device_code_response.dart';
import '../models/auth/microsoft_token_response.dart';
import '../models/auth/xbox_live_response.dart';
import '../models/auth/xsts_response.dart';
import '../models/auth/minecraft_token_response.dart';
import '../models/auth/minecraft_profile.dart';
import '../models/auth/xbox_profile.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthenticationService {
  // クライアントID
  static final String _clientId = dotenv.get('MICROSOFT_CLIENT_ID');

  // トークン保存用のキー
  static const String _refreshTokenKey = 'minecraft_refresh_token';
  static const String _accessTokenKey = 'minecraft_access_token';
  static const String _tokenExpiryKey = 'minecraft_token_expiry';

  // Microsoftリフレッシュトークン用のキー
  static const String _msRefreshTokenKey = 'microsoft_refresh_token';

  // Xboxトークン用のキー
  static const String _xboxTokenKey = 'xbox_token';
  static const String _xboxTokenExpiryKey = 'xbox_token_expiry';

  // シングルトンインスタンス
  static final AuthenticationService _instance =
      AuthenticationService._internal();

  factory AuthenticationService() {
    return _instance;
  }

  AuthenticationService._internal();

  // アクセストークンのキャッシュ
  String? _minecraftAccessToken;
  DateTime? _minecraftTokenExpiry;

  // Xboxトークンのキャッシュ
  String? _xboxToken;
  DateTime? _xboxTokenExpiry;

  /// Microsoft Device Codeを取得する
  Future<DeviceCodeResponse> getMicrosoftDeviceCode() async {
    final response = await http.post(
      Uri.parse(
        'https://login.microsoftonline.com/consumers/oauth2/v2.0/devicecode',
      ),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'client_id': _clientId, 'scope': 'XboxLive.signin offline_access'},
    );

    if (response.statusCode == 200) {
      return DeviceCodeResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to get device code: ${response.body}');
    }
  }

  /// Device Codeを使用してMicrosoftトークンを取得する（ポーリング）
  Future<MicrosoftTokenResponse> pollForMicrosoftToken(
    String deviceCode, {
    Duration pollingInterval = const Duration(seconds: 5),
  }) async {
    bool authorized = false;
    MicrosoftTokenResponse? tokenResponse;

    while (!authorized) {
      final response = await http.post(
        Uri.parse(
          'https://login.microsoftonline.com/consumers/oauth2/v2.0/token',
        ),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'urn:ietf:params:oauth:grant-type:device_code',
          'client_id': _clientId,
          'device_code': deviceCode,
        },
      );

      if (response.statusCode == 200) {
        tokenResponse = MicrosoftTokenResponse.fromJson(
          jsonDecode(response.body),
        );
        authorized = true;
      } else {
        final error = jsonDecode(response.body);
        if (error['error'] == 'authorization_pending') {
          await Future.delayed(pollingInterval);
        } else if (error['error'] == 'expired_token') {
          throw Exception(
            'Device code expired. Please restart the authentication process.',
          );
        } else {
          throw Exception('Token polling failed: ${response.body}');
        }
      }
    }

    return tokenResponse!;
  }

  /// リフレッシュトークンを使用してMicrosoftトークンを更新する
  Future<MicrosoftTokenResponse> refreshMicrosoftToken(
    String refreshToken,
  ) async {
    final response = await http.post(
      Uri.parse(
        'https://login.microsoftonline.com/consumers/oauth2/v2.0/token',
      ),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'client_id': _clientId,
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
        'scope': 'XboxLive.signin offline_access',
      },
    );

    if (response.statusCode == 200) {
      return MicrosoftTokenResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to refresh token: ${response.body}');
    }
  }

  /// Xbox Live認証を行う
  Future<XboxLiveResponse> authenticateWithXboxLive(
    String microsoftAccessToken,
  ) async {
    final response = await http.post(
      Uri.parse('https://user.auth.xboxlive.com/user/authenticate'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        "Properties": {
          "AuthMethod": "RPS",
          "SiteName": "user.auth.xboxlive.com",
          "RpsTicket": "d=$microsoftAccessToken",
        },
        "RelyingParty": "http://auth.xboxlive.com",
        "TokenType": "JWT",
      }),
    );

    if (response.statusCode == 200) {
      return XboxLiveResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Xbox Live authentication failed: ${response.body}');
    }
  }

  /// Xboxプロフィール情報を取得する
  Future<XboxProfile> getXboxProfile(String xstsToken, String xboxToken) async {
    final response = await http.post(
      Uri.parse('https://xsts.auth.xboxlive.com/xsts/authorize'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        "Properties": {
          "SandboxId": "RETAIL",
          "UserTokens": [xstsToken],
          "OptionalDisplayClaims": ["mgt", "umg", "mgs"],
        },
        "RelyingParty": "http://xboxlive.com",
        "TokenType": "JWT",
      }),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final displayClaims = json['DisplayClaims'];
      if (displayClaims != null) {
        final xui = displayClaims['xui'];
        if (xui != null && xui.isNotEmpty) {
          final xboxProfile = xui[0];
          var xuid = xboxProfile['xid'];

          final profileResponse = await http.get(
            Uri.parse(
              'https://profile.xboxlive.com/users/xuid($xuid)/profile/settings',
            ),
            headers: {
              'Authorization': 'XBL3.0 x=$xstsToken',
              'x-xbl-contract-version': '2',
              'Accept': 'application/json',
            },
          );

          return XboxProfile.fromJson(jsonDecode(profileResponse.body));
        }
      }
      throw Exception(
        'No Xbox profile was returned for that Microsoft account',
      );
    } else {
      throw Exception('Failed to get Xbox profile: ${response.body}');
    }
  }

  /// XSTSトークンを取得する
  Future<XstsResponse> getXstsToken(String xblToken) async {
    final response = await http.post(
      Uri.parse('https://xsts.auth.xboxlive.com/xsts/authorize'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        "Properties": {
          "SandboxId": "RETAIL",
          "UserTokens": [xblToken],
        },
        "RelyingParty": "rp://api.minecraftservices.com/",
        "TokenType": "JWT",
      }),
    );

    if (response.statusCode == 200) {
      return XstsResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('XSTS token retrieval failed: ${response.body}');
    }
  }

  /// XSTSトークンからXuid（Xboxユーザーの一意識別子）を取得する
  Future<String> getXuidFromToken(String uhs, String xstsToken) async {
    try {
      debugPrint('UHS: $uhs');
      debugPrint('XSTS Token: $xstsToken');

      // XuidをDisplayClaimsから直接取得
      final xuid = uhs; // UHSはXuidとして利用可能
      if (xuid.isNotEmpty) {
        debugPrint('Extracted Xuid: $xuid');
        return xuid;
      } else {
        throw Exception('Failed to extract Xuid from UHS');
      }
    } catch (e) {
      debugPrint('Error in getXuidFromToken: $e');
      throw Exception('Failed to extract Xuid: $e');
    }
  }

  /// Minecraftアクセストークンを取得する
  /// Minecraftアクセストークンを取得する
  Future<MinecraftTokenResponse> getMinecraftAccessToken(
    String uhs,
    String xstsToken,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(
          'https://api.minecraftservices.com/authentication/login_with_xbox',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"identityToken": "XBL3.0 x=$uhs;$xstsToken"}),
      );

      if (response.statusCode == 200) {
        final tokenResponse = MinecraftTokenResponse.fromJson(
          jsonDecode(response.body),
        );

        // トークンをキャッシュと永続化に保存
        _minecraftAccessToken = tokenResponse.accessToken;
        _minecraftTokenExpiry = DateTime.now().add(
          Duration(seconds: tokenResponse.expiresIn),
        );
        await _saveMinecraftToken(
          tokenResponse.accessToken,
          tokenResponse.expiresIn,
        );

        return tokenResponse;
      } else {
        throw Exception('Minecraft token retrieval failed: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error in getMinecraftAccessToken: $e');
      throw Exception('Failed to retrieve Minecraft access token: $e');
    }
  }

  /// Minecraft所有権をチェックする
  /// Minecraft所有権をチェックする
  Future<bool> checkMinecraftOwnership(String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.minecraftservices.com/entitlements/mcstore'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['items'] != null) {
          final items = data['items'] as List;
          return items.isNotEmpty;
        } else {
          debugPrint('No items found in entitlement response.');
          return false;
        }
      } else {
        throw Exception(
          'Failed to check Minecraft ownership: ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('Error in checkMinecraftOwnership: $e');
      throw Exception('Failed to check Minecraft ownership: $e');
    }
  }

  /// Minecraftプロファイルを取得する
  Future<MinecraftProfile> getMinecraftProfile(String accessToken) async {
    final response = await http.get(
      Uri.parse('https://api.minecraftservices.com/minecraft/profile'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      return MinecraftProfile.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to get Minecraft profile: ${response.body}');
    }
  }

  /// 認証フローを完了する
  Future<MinecraftProfile> completeAuthFlow() async {
    // Device Codeを取得
    final deviceCodeResponse = await getMicrosoftDeviceCode();

    // ユーザーに表示するコード情報を返す
    debugPrint(
      'Please go to ${deviceCodeResponse.verificationUri} and enter code: ${deviceCodeResponse.userCode}',
    );

    // トークン取得をポーリング
    final msTokenResponse = await pollForMicrosoftToken(
      deviceCodeResponse.deviceCode,
    );

    // Microsoftリフレッシュトークンを保存
    await _saveMicrosoftRefreshToken(msTokenResponse.refreshToken);

    // Xbox Live認証
    final xboxLiveResponse = await authenticateWithXboxLive(
      msTokenResponse.accessToken,
    );

    // Xboxトークンを保存（有効期限は近似値として1日を設定）
    await _saveXboxToken(xboxLiveResponse.token, 86400); // 24時間（秒単位）

    // XSTSトークン取得
    final xstsResponse = await getXstsToken(xboxLiveResponse.token);

    // MinecraftアクセストークンでユーザーハッシュとXSTSトークンを使用
    final minecraftToken = await getMinecraftAccessToken(
      xstsResponse.displayClaims.xui[0].uhs,
      xstsResponse.token,
    );

    // 所有権チェック
    final hasGame = await checkMinecraftOwnership(minecraftToken.accessToken);
    if (!hasGame) {
      throw Exception('You do not own Minecraft: Java Edition');
    }

    // プロファイル情報を取得して返す
    return await getMinecraftProfile(minecraftToken.accessToken);
  }

  /// リフレッシュトークンを使ってMinecraftプロファイルを取得する
  Future<MinecraftProfile?> getProfileWithSavedToken() async {
    try {
      // キャッシュされたトークンを確認
      if (_minecraftAccessToken != null &&
          _minecraftTokenExpiry != null &&
          _minecraftTokenExpiry!.isAfter(DateTime.now())) {
        // キャッシュされたトークンが有効
        return await getMinecraftProfile(_minecraftAccessToken!);
      }

      // 保存されたトークンを確認
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString(_refreshTokenKey);

      if (refreshToken != null) {
        // リフレッシュトークンが存在する場合、新しいアクセストークンを取得
        final msTokenResponse = await refreshMicrosoftToken(refreshToken);

        // Xbox Live認証フローを再実行
        final xboxLiveResponse = await authenticateWithXboxLive(
          msTokenResponse.accessToken,
        );
        final xstsResponse = await getXstsToken(xboxLiveResponse.token);
        final minecraftToken = await getMinecraftAccessToken(
          xstsResponse.displayClaims.xui[0].uhs,
          xstsResponse.token,
        );

        // 所有権チェック
        final hasGame = await checkMinecraftOwnership(
          minecraftToken.accessToken,
        );
        if (!hasGame) {
          throw Exception('You do not own Minecraft: Java Edition');
        }

        // プロファイル情報を取得して返す
        return await getMinecraftProfile(minecraftToken.accessToken);
      }
    } catch (e) {
      debugPrint('Error getting profile with saved token: $e');
      // トークン無効化、再認証が必要
      await _clearSavedTokens();
    }

    return null; // 認証が必要
  }

  /// Minecraftのアクセストークンを取得（キャッシュまたは保存済み）
  Future<String?> getMinecraftToken() async {
    try {
      // キャッシュされたトークンを確認
      if (_minecraftAccessToken != null &&
          _minecraftTokenExpiry != null &&
          _minecraftTokenExpiry!.isAfter(DateTime.now())) {
        return _minecraftAccessToken;
      }

      // 保存されたトークンを確認
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString(_accessTokenKey);
      final expiryTimestamp = prefs.getInt(_tokenExpiryKey);

      if (accessToken != null && expiryTimestamp != null) {
        final expiry = DateTime.fromMillisecondsSinceEpoch(expiryTimestamp);

        if (expiry.isAfter(DateTime.now())) {
          // 保存されたトークンが有効
          _minecraftAccessToken = accessToken;
          _minecraftTokenExpiry = expiry;
          return accessToken;
        }

        // トークンが期限切れなのでリフレッシュを試みる
        final refreshToken = prefs.getString(_refreshTokenKey);
        if (refreshToken != null) {
          return await _refreshFullAuthFlow(refreshToken);
        }
      }
    } catch (e) {
      debugPrint('Error getting Minecraft token: $e');
    }

    return null; // トークンが利用できないか期限切れ
  }

  /// 完全な認証フローを再実行してトークンを更新
  /// 完全な認証フローを再実行してトークンを更新
  Future<String?> _refreshFullAuthFlow(String refreshToken) async {
    try {
      final msTokenResponse = await refreshMicrosoftToken(refreshToken);

      // 新しいリフレッシュトークンを保存
      await _saveMicrosoftRefreshToken(msTokenResponse.refreshToken);

      final xboxLiveResponse = await authenticateWithXboxLive(
        msTokenResponse.accessToken,
      );

      // Xboxトークンを保存（有効期限は近似値として1日を設定）
      await _saveXboxToken(xboxLiveResponse.token, 86400); // 24時間（秒単位）

      final xstsResponse = await getXstsToken(xboxLiveResponse.token);
      final minecraftToken = await getMinecraftAccessToken(
        xstsResponse.displayClaims.xui[0].uhs,
        xstsResponse.token,
      );
      return minecraftToken.accessToken;
    } catch (e) {
      debugPrint('Refresh auth flow failed: $e');
      await _clearSavedTokens();
      return null;
    }
  }

  /// Minecraftトークンを保存する
  Future<void> _saveMinecraftToken(String accessToken, int expiresIn) async {
    final prefs = await SharedPreferences.getInstance();
    final expiry =
        DateTime.now().add(Duration(seconds: expiresIn)).millisecondsSinceEpoch;

    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setInt(_tokenExpiryKey, expiry);
  }

  /// 保存されたトークンを消去する
  Future<void> _clearSavedTokens() async {
    _minecraftAccessToken = null;
    _minecraftTokenExpiry = null;
    _xboxToken = null;
    _xboxTokenExpiry = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_tokenExpiryKey);
    await prefs.remove(_msRefreshTokenKey);
    await prefs.remove(_xboxTokenKey);
    await prefs.remove(_xboxTokenExpiryKey);
  }

  /// Microsoftリフレッシュトークンを保存する
  Future<void> _saveMicrosoftRefreshToken(String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_msRefreshTokenKey, refreshToken);
  }

  /// Xboxトークンを保存する
  Future<void> _saveXboxToken(String token, int expiresIn) async {
    final prefs = await SharedPreferences.getInstance();
    final expiry =
        DateTime.now().add(Duration(seconds: expiresIn)).millisecondsSinceEpoch;

    _xboxToken = token;
    _xboxTokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));

    await prefs.setString(_xboxTokenKey, token);
    await prefs.setInt(_xboxTokenExpiryKey, expiry);
  }

  /// 保存されたXboxトークンを取得する
  Future<String?> getXboxToken() async {
    try {
      // キャッシュされたトークンを確認
      if (_xboxToken != null &&
          _xboxTokenExpiry != null &&
          _xboxTokenExpiry!.isAfter(DateTime.now())) {
        return _xboxToken;
      }

      // 保存されたトークンを確認
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_xboxTokenKey);
      final expiryTimestamp = prefs.getInt(_xboxTokenExpiryKey);

      if (token != null && expiryTimestamp != null) {
        final expiry = DateTime.fromMillisecondsSinceEpoch(expiryTimestamp);

        if (expiry.isAfter(DateTime.now())) {
          // 保存されたトークンが有効
          _xboxToken = token;
          _xboxTokenExpiry = expiry;
          return token;
        }

        // トークンが期限切れなのでリフレッシュを試みる
        final msRefreshToken = prefs.getString(_msRefreshTokenKey);
        if (msRefreshToken != null) {
          return await _refreshXboxToken(msRefreshToken);
        }
      }
    } catch (e) {
      debugPrint('Error getting Xbox token: $e');
    }

    return null; // トークンが利用できないか期限切れ
  }

  /// Xboxトークンをリフレッシュする
  Future<String?> _refreshXboxToken(String refreshToken) async {
    try {
      // Microsoftトークンをリフレッシュ
      final msTokenResponse = await refreshMicrosoftToken(refreshToken);

      // リフレッシュトークンを保存（更新されている可能性があるため）
      await _saveMicrosoftRefreshToken(msTokenResponse.refreshToken);

      // Xbox Live認証
      final xboxLiveResponse = await authenticateWithXboxLive(
        msTokenResponse.accessToken,
      );

      // Xboxトークンを保存（有効期限は近似値として1日を設定）
      await _saveXboxToken(xboxLiveResponse.token, 86400); // 24時間（秒単位）

      return xboxLiveResponse.token;
    } catch (e) {
      debugPrint('Xbox token refresh failed: $e');
      return null;
    }
  }

  /// ログアウト処理
  Future<void> logout() async {
    await _clearSavedTokens();
  }

  /// 認証済みかどうかを確認
  Future<bool> isAuthenticated() async {
    final token = await getMinecraftToken();
    return token != null;
  }
}
