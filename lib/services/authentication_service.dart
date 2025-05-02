import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:karasu_launcher/providers/authentication_provider.dart';
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

  // Microsoftリフレッシュトークンのキャッシュ
  String? _msRefreshToken;

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

        // トークンをキャッシュに保存
        _cacheMinecraftToken(
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
  Future<bool> checkMinecraftOwnership(String accessToken) async {
    try {
      debugPrint('Minecraft所有権チェックを実行中...');
      final response = await http.get(
        Uri.parse('https://api.minecraftservices.com/entitlements/mcstore'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      debugPrint('所有権チェックレスポンス: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('所有権データ: $data');

        if (data['items'] != null) {
          final items = data['items'] as List;
          return items.isNotEmpty;
        } else {
          debugPrint('No items found in entitlement response.');
          return false;
        }
      } else {
        debugPrint('所有権チェックエラー: ${response.body}');
        throw Exception(
          'Failed to check Minecraft ownership: ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('所有権チェック例外: $e');
      throw Exception('Failed to check Minecraft ownership: $e');
    }
  }

  /// Minecraftプロファイルを取得する
  Future<MinecraftProfile> getMinecraftProfile(String accessToken) async {
    debugPrint('Minecraftプロファイル取得APIを呼び出し中...');
    try {
      final response = await http.get(
        Uri.parse('https://api.minecraftservices.com/minecraft/profile'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      debugPrint('プロファイルAPIレスポンス: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        debugPrint('プロファイルデータ: $jsonData');
        return MinecraftProfile.fromJson(jsonData);
      } else {
        debugPrint('プロファイル取得エラー: ${response.body}');
        throw Exception('Failed to get Minecraft profile: ${response.body}');
      }
    } catch (e) {
      debugPrint('プロファイル取得例外: $e');
      throw Exception('Exception getting Minecraft profile: $e');
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

    // Microsoftリフレッシュトークンをキャッシュ
    _cacheMicrosoftRefreshToken(msTokenResponse.refreshToken);

    // Xbox Live認証
    final xboxLiveResponse = await authenticateWithXboxLive(
      msTokenResponse.accessToken,
    );

    // Xboxトークンをメモリキャッシュに保存
    _cacheXboxToken(xboxLiveResponse.token, 86400); // 24時間（秒単位）

    // XSTSトークン取得
    final xstsResponse = await getXstsToken(xboxLiveResponse.token);

    // Minecraftアクセストークン取得
    final minecraftToken = await getMinecraftAccessToken(
      xstsResponse.displayClaims.xui[0].uhs,
      xstsResponse.token,
    );

    // Minecraftトークンをメモリキャッシュに保存
    _cacheMinecraftToken(
      minecraftToken.accessToken,
      minecraftToken.expiresIn,
    );

    // 所有権チェック
    final hasGame = await checkMinecraftOwnership(minecraftToken.accessToken);
    if (!hasGame) {
      throw Exception('Minecraft: Java Editionを所有していません');
    }

    // プロファイル情報を取得して返す
    return await getMinecraftProfile(minecraftToken.accessToken);
  }

  /// リフレッシュトークンを使ってMinecraftプロファイルを取得する
  Future<MinecraftProfile?> getProfileWithSavedToken() async {
    try {
      // getMinecraftTokenを使用して有効なトークンを取得
      final accessToken = await getMinecraftToken();

      if (accessToken != null) {
        debugPrint('既存のトークンを使用してプロファイル取得');
        // 所有権チェック
        final hasGame = await checkMinecraftOwnership(accessToken);
        if (!hasGame) {
          throw Exception('Minecraft: Java Editionを所有していません');
        }

        // プロファイル情報を取得して返す
        return await getMinecraftProfile(accessToken);
      }

      // Microsoftリフレッシュトークンを確認
      if (_msRefreshToken != null) {
        debugPrint('Microsoftリフレッシュトークンで認証フロー再実行');
        // 新しいアクセストークンを取得
        final newToken = await _refreshFullAuthFlow(_msRefreshToken!);

        if (newToken != null) {
          // 所有権チェック
          final hasGame = await checkMinecraftOwnership(newToken);
          if (!hasGame) {
            throw Exception('Minecraft: Java Editionを所有していません');
          }

          // プロファイル情報を取得して返す
          return await getMinecraftProfile(newToken);
        }
      }
    } catch (e) {
      debugPrint('Error getting profile with saved token: $e');
      // トークン無効化、再認証が必要
      _clearCache();
    }

    return null; // 認証が必要
  }

  /// Minecraftのアクセストークンを取得（アクティブなアカウント優先）
  Future<String?> getMinecraftToken() async {
    try {
      // 優先順位1: アクティブなアカウントからトークンを取得
      try {
        final container = ProviderContainer();
        final authNotifier = container.read(authenticationProvider.notifier);
        final token = await authNotifier.getAccessTokenForService();
        if (token != null) {
          debugPrint('アクティブなアカウントからトークンを取得しました');
          return token;
        }
      } catch (e) {
        debugPrint('アクティブアカウントからトークン取得中のエラー: $e');
        // エラーが発生しても続行し、他の方法でトークンを取得
      }

      // 優先順位2: キャッシュされたトークンを確認
      if (_minecraftAccessToken != null &&
          _minecraftTokenExpiry != null &&
          _minecraftTokenExpiry!.isAfter(DateTime.now())) {
        debugPrint('キャッシュされたMinecraftトークンを使用');
        return _minecraftAccessToken;
      }

      debugPrint('キャッシュされたMinecraftトークンが無効か期限切れです');
      
      // リフレッシュトークンがあればリフレッシュを試みる
      if (_msRefreshToken != null) {
        debugPrint('Microsoftリフレッシュトークンを使って再認証');
        return await _refreshFullAuthFlow(_msRefreshToken!);
      }
    } catch (e) {
      debugPrint('Error getting Minecraft token: $e');
    }

    debugPrint('有効なトークンがありません。ログインが必要です。');
    return null; // トークンが利用できないか期限切れ
  }

  /// 完全な認証フローを再実行してトークンを更新
  Future<String?> _refreshFullAuthFlow(String refreshToken) async {
    try {
      final msTokenResponse = await refreshMicrosoftToken(refreshToken);

      // 新しいリフレッシュトークンをキャッシュ
      _cacheMicrosoftRefreshToken(msTokenResponse.refreshToken);

      final xboxLiveResponse = await authenticateWithXboxLive(
        msTokenResponse.accessToken,
      );

      // Xboxトークンをキャッシュ（有効期限は近似値として1日を設定）
      _cacheXboxToken(xboxLiveResponse.token, 86400); // 24時間（秒単位）

      final xstsResponse = await getXstsToken(xboxLiveResponse.token);
      final minecraftToken = await getMinecraftAccessToken(
        xstsResponse.displayClaims.xui[0].uhs,
        xstsResponse.token,
      );
      // トークンをキャッシュに保存
      _cacheMinecraftToken(
        minecraftToken.accessToken,
        minecraftToken.expiresIn,
      );

      return minecraftToken.accessToken;
    } catch (e) {
      debugPrint('Refresh auth flow failed: $e');
      _clearCache();
      return null;
    }
  }

  /// サイレントログインを試みる
  /// キャッシュされたトークンを使用して自動的に認証を試みる
  Future<MinecraftProfile?> silentLogin() async {
    try {
      debugPrint('サイレントログインを試みています...');

      // まず既に有効なMinecraftトークンがあるか確認
      final minecraftToken = await getMinecraftToken();
      if (minecraftToken != null) {
        debugPrint('有効なMinecraftトークンでプロファイル取得');

        // 所有権チェック
        final hasGame = await checkMinecraftOwnership(minecraftToken);
        if (!hasGame) {
          throw Exception('Minecraft: Java Editionを所有していません');
        }

        // プロファイル情報を取得して返す
        return await getMinecraftProfile(minecraftToken);
      }

      // キャッシュされたMicrosoftリフレッシュトークンを確認
      if (_msRefreshToken == null) {
        debugPrint('キャッシュされたMicrosoftリフレッシュトークンがありません');
        return null;
      }

      debugPrint('Microsoftリフレッシュトークンを使用して認証フロー再実行');
      // 完全な認証フローを再実行
      final newToken = await _refreshFullAuthFlow(_msRefreshToken!);

      if (newToken != null) {
        // 所有権チェック
        final hasGame = await checkMinecraftOwnership(newToken);
        if (!hasGame) {
          throw Exception('Minecraft: Java Editionを所有していません');
        }

        // プロファイル情報を取得して返す
        return await getMinecraftProfile(newToken);
      }

      return null;
    } catch (e) {
      debugPrint('サイレントログイン失敗: $e');
      // エラーが発生した場合はキャッシュをクリア
      _clearCache();
      return null;
    }
  }

  /// Minecraftトークンをキャッシュする
  void _cacheMinecraftToken(String accessToken, int expiresIn) {
    _minecraftAccessToken = accessToken;
    _minecraftTokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));
  }

  /// Microsoftリフレッシュトークンをキャッシュする
  void _cacheMicrosoftRefreshToken(String refreshToken) {
    _msRefreshToken = refreshToken;
  }

  /// Xboxトークンをキャッシュする
  void _cacheXboxToken(String token, int expiresIn) {
    _xboxToken = token;
    _xboxTokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));
  }

  /// キャッシュをクリアする
  void _clearCache() {
    _minecraftAccessToken = null;
    _minecraftTokenExpiry = null;
    _msRefreshToken = null;
    _xboxToken = null;
    _xboxTokenExpiry = null;
  }

  /// Xboxトークンを取得する
  Future<String?> getXboxToken() async {
    try {
      // キャッシュされたトークンを確認
      if (_xboxToken != null &&
          _xboxTokenExpiry != null &&
          _xboxTokenExpiry!.isAfter(DateTime.now())) {
        return _xboxToken;
      }

      // トークンが期限切れなのでリフレッシュを試みる
      if (_msRefreshToken != null) {
        return await _refreshXboxToken(_msRefreshToken!);
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

      // リフレッシュトークンをキャッシュ（更新されている可能性があるため）
      _cacheMicrosoftRefreshToken(msTokenResponse.refreshToken);

      // Xbox Live認証
      final xboxLiveResponse = await authenticateWithXboxLive(
        msTokenResponse.accessToken,
      );

      // Xboxトークンをキャッシュ（有効期限は近似値として1日を設定）
      _cacheXboxToken(xboxLiveResponse.token, 86400); // 24時間（秒単位）

      return xboxLiveResponse.token;
    } catch (e) {
      debugPrint('Xbox token refresh failed: $e');
      return null;
    }
  }

  /// ログアウト処理
  Future<void> logout() async {
    _clearCache();
  }

  /// 認証済みかどうかを確認
  Future<bool> isAuthenticated() async {
    final token = await getMinecraftToken();
    return token != null;
  }

  /// アクティブなアカウントからMinecraftトークンを取得する
  /// AuthenticationNotifierと連携して使用する
  Future<String?> getActiveAccountToken() async {
    try {
      // Providerからアクティブなアカウント情報を取得（グローバルProviderコンテナを使用）
      final container = ProviderContainer();
      final authState = container.read(authenticationProvider);
      final activeAccount = authState.activeAccount;

      if (activeAccount == null) {
        debugPrint('アクティブなアカウントが存在しません');
        return null;
      }

      // アカウントが有効なトークンを持っているか確認
      if (activeAccount.hasValidMinecraftToken) {
        debugPrint(
          'アクティブなアカウントから有効なトークンを取得: ${activeAccount.profile?.name ?? "Unknown"}',
        );
        return activeAccount.minecraftAccessToken;
      }

      // リフレッシュを試みる
      if (activeAccount.hasRefreshToken) {
        debugPrint('アクティブなアカウントのトークンを更新します');
        // リフレッシュトークンを使ってトークンを更新
        final profile =
            await container
                .read(authenticationProvider.notifier)
                .refreshActiveAccount();
        if (profile != null) {
          // 更新後のアクティブアカウントからトークンを取得
          final updatedAuthState = container.read(authenticationProvider);
          final updatedAccount = updatedAuthState.activeAccount;
          if (updatedAccount?.hasValidMinecraftToken ?? false) {
            return updatedAccount?.minecraftAccessToken;
          }
        }
      }

      debugPrint('アクティブなアカウントから有効なトークンを取得できませんでした');
      return null;
    } catch (e) {
      debugPrint('アクティブアカウントからのトークン取得エラー: $e');
      return null;
    }
  }
}
