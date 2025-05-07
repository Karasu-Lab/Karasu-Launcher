import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/auth/xbox_live_response.dart';
import '../../models/auth/xsts_response.dart';
import '../../models/auth/xbox_profile.dart';
import 'base_auth_service.dart';
import 'auth_events.dart';

/// Xbox Liveの認証に関連する機能を提供するサービスクラス
class XboxAuthService extends BaseAuthService {
  static final XboxAuthService _instance = XboxAuthService._internal();

  factory XboxAuthService() {
    return _instance;
  }

  XboxAuthService._internal();

  @override
  AuthCategory get category => AuthCategory.xbox;

  /// Xbox Live認証を行う
  Future<XboxLiveResponse> authenticateWithXboxLive(
    String microsoftAccessToken,
  ) async {
    log(
      'Authenticating with Xbox Live...',
      eventType: AuthEventType.xboxLiveAuthentication,
    );

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
      logError('Xbox Live authentication failed: ${response.body}');
      throw Exception('Xbox Live authentication failed: ${response.body}');
    }
  }

  /// Xboxプロフィール情報を取得する
  Future<XboxProfile> getXboxProfile(String xstsToken, String xboxToken) async {
    log('Getting Xbox profile...', eventType: AuthEventType.gettingXboxProfile);

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
      logError('No Xbox profile was returned for that Microsoft account');
      throw Exception(
        'No Xbox profile was returned for that Microsoft account',
      );
    } else {
      logError('Failed to get Xbox profile: ${response.body}');
      throw Exception('Failed to get Xbox profile: ${response.body}');
    }
  }

  /// XSTSトークンを取得する
  Future<XstsResponse> getXstsToken(String xblToken) async {
    log('Getting XSTS token...', eventType: AuthEventType.gettingXstsToken);

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
      logError('XSTS token retrieval failed: ${response.body}');
      throw Exception('XSTS token retrieval failed: ${response.body}');
    }
  }

  /// XSTSトークンからXuid（Xboxユーザーの一意識別子）を取得する
  Future<String> getXuidFromToken(String uhs, String xstsToken) async {
    try {
      log('UHS: $uhs', eventType: AuthEventType.uhsInfo);
      log('XSTS Token: $xstsToken', eventType: AuthEventType.xstsTokenInfo);

      final xuid = uhs;
      if (xuid.isNotEmpty) {
        log('Extracted Xuid: $xuid', eventType: AuthEventType.extractedXuid);
        return xuid;
      } else {
        logError(
          'Failed to extract Xuid from UHS',
          eventType: AuthEventType.failedToExtractXuid,
        );
        throw Exception('Failed to extract Xuid from UHS');
      }
    } catch (e) {
      logError(
        'Error in getXuidFromToken: $e',
        eventType: AuthEventType.failedToExtractXuid,
      );
      throw Exception('Failed to extract Xuid: $e');
    }
  }

  /// Xboxトークンをキャッシュする
  void cacheXboxToken(String token, int expiresIn) {
    cacheToken(token, expiresIn);
    log(
      'Xbox token cached, expires in $expiresIn seconds',
      eventType: AuthEventType.xboxTokenCached,
    );
  }

  /// Xboxトークンを取得する
  String? getXboxToken() {
    final token = getToken();
    if (token != null) {
      log(
        'Using cached Xbox token',
        eventType: AuthEventType.usingCachedXboxToken,
      );
    } else {
      log(
        'Cached Xbox token is invalid or expired',
        eventType: AuthEventType.cachedXboxTokenInvalid,
      );
    }
    return token;
  }
}
