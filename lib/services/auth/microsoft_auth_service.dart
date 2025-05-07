import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/auth/device_code_response.dart';
import '../../models/auth/microsoft_token_response.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'base_auth_service.dart';
import 'auth_events.dart';

/// Microsoftの認証に関連する機能を提供するサービスクラス
class MicrosoftAuthService extends BaseAuthService {
  static final String _clientId = dotenv.get('MICROSOFT_CLIENT_ID');

  static final MicrosoftAuthService _instance =
      MicrosoftAuthService._internal();

  factory MicrosoftAuthService() {
    return _instance;
  }

  MicrosoftAuthService._internal();

  String? _msRefreshToken;

  @override
  AuthCategory get category => AuthCategory.microsoft;

  /// Microsoft Device Codeを取得する
  Future<DeviceCodeResponse> getMicrosoftDeviceCode() async {
    log(
      'Requesting Microsoft device code...',
      eventType: AuthEventType.requestingMicrosoftDeviceCode,
    );

    final response = await http.post(
      Uri.parse(
        'https://login.microsoftonline.com/consumers/oauth2/v2.0/devicecode',
      ),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'client_id': _clientId, 'scope': 'XboxLive.signin offline_access'},
    );

    if (response.statusCode == 200) {
      log(
        'Device code obtained successfully',
        eventType: AuthEventType.deviceCodeObtained,
      );
      return DeviceCodeResponse.fromJson(jsonDecode(response.body));
    } else {
      logError('Failed to get device code: ${response.body}');
      throw Exception('Failed to get device code: ${response.body}');
    }
  }

  /// Device Codeを使用してMicrosoftトークンを取得する（ポーリング）
  Future<MicrosoftTokenResponse> pollForMicrosoftToken(
    String deviceCode, {
    Duration pollingInterval = const Duration(seconds: 5),
  }) async {
    log(
      'Starting polling for Microsoft token...',
      eventType: AuthEventType.startingMicrosoftTokenPolling,
    );

    bool authorized = false;
    MicrosoftTokenResponse? tokenResponse;

    while (!authorized) {
      log(
        'Polling for token authorization...',
        eventType: AuthEventType.pollingForTokenAuthorization,
      );

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
        log(
          'Microsoft token authorization successful',
          eventType: AuthEventType.microsoftAuthorizationSuccessful,
        );

        tokenResponse = MicrosoftTokenResponse.fromJson(
          jsonDecode(response.body),
        );
        authorized = true;
      } else {
        final error = jsonDecode(response.body);
        if (error['error'] == 'authorization_pending') {
          log(
            'Authorization pending, waiting before next poll...',
            eventType: AuthEventType.authorizationPending,
          );
          await Future.delayed(pollingInterval);
        } else if (error['error'] == 'expired_token') {
          logWarning(
            'Device code expired',
            eventType: AuthEventType.deviceCodeExpired,
          );
          throw Exception(
            'Device code expired. Please restart the authentication process.',
          );
        } else {
          logError('Token polling failed: ${response.body}');
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
    log(
      'Refreshing Microsoft token...',
      eventType: AuthEventType.refreshingMicrosoftToken,
    );

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
      log(
        'Microsoft token refreshed successfully',
        eventType: AuthEventType.microsoftTokenRefreshed,
      );
      return MicrosoftTokenResponse.fromJson(jsonDecode(response.body));
    } else {
      logError('Failed to refresh token: ${response.body}');
      throw Exception('Failed to refresh token: ${response.body}');
    }
  }

  /// Microsoftリフレッシュトークンをキャッシュする
  void cacheMicrosoftRefreshToken(String refreshToken) {
    _msRefreshToken = refreshToken;
    log(
      'Microsoft refresh token cached',
      eventType: AuthEventType.microsoftRefreshTokenCached,
    );
  }

  /// リフレッシュトークンを取得する
  String? getRefreshToken() {
    if (_msRefreshToken != null) {
      log(
        'Using cached Microsoft refresh token',
        eventType: AuthEventType.usingCachedMicrosoftRefreshToken,
      );
      return _msRefreshToken;
    }
    log(
      'No cached Microsoft refresh token available',
      eventType: AuthEventType.noCachedMicrosoftRefreshToken,
    );
    return null;
  }

  @override
  void clearCache() {
    super.clearCache();
    _msRefreshToken = null;
  }
}
