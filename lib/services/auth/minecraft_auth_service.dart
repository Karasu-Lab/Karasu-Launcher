import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/auth/minecraft_token_response.dart';
import '../../models/auth/minecraft_profile.dart';
import 'base_auth_service.dart';
import 'auth_events.dart';

/// Minecraftの認証に関連する機能を提供するサービスクラス
class MinecraftAuthService extends BaseAuthService {
  static final MinecraftAuthService _instance =
      MinecraftAuthService._internal();

  factory MinecraftAuthService() {
    return _instance;
  }

  MinecraftAuthService._internal();

  @override
  AuthCategory get category => AuthCategory.minecraft;

  /// Minecraftアクセストークンを取得する
  Future<MinecraftTokenResponse> getMinecraftAccessToken(
    String uhs,
    String xstsToken,
  ) async {
    try {
      log('Retrieving Minecraft access token...');

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

        cacheMinecraftToken(tokenResponse.accessToken, tokenResponse.expiresIn);
        log('Minecraft access token retrieved successfully');

        return tokenResponse;
      } else {
        logError('Minecraft token retrieval failed: ${response.body}');
        throw Exception('Minecraft token retrieval failed: ${response.body}');
      }
    } catch (e) {
      logError('Error in getMinecraftAccessToken: $e');
      throw Exception('Failed to retrieve Minecraft access token: $e');
    }
  }

  /// Minecraftの所有権を確認する
  Future<bool> checkMinecraftOwnership(String accessToken) async {
    try {
      log(
        'Checking Minecraft ownership...',
        eventType: AuthEventType.checkingMinecraftOwnership,
      );

      final response = await http.get(
        Uri.parse('https://api.minecraftservices.com/entitlements/mcstore'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      log(
        'Ownership check response: ${response.statusCode}',
        eventType: AuthEventType.ownershipCheckResponse,
        data: {'statusCode': response.statusCode},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        log(
          'Ownership data received',
          eventType: AuthEventType.ownershipData,
          data: {'data': data},
        );

        if (data['items'] != null) {
          final items = data['items'] as List;
          return items.isNotEmpty;
        } else {
          log(
            'No items found in entitlement response',
            eventType: AuthEventType.noItemsInEntitlement,
          );
          return false;
        }
      } else {
        logError(
          'Ownership check error: ${response.body}',
          eventType: AuthEventType.ownershipCheckError,
          data: {'response': response.body},
        );
        throw Exception(
          'Failed to check Minecraft ownership: ${response.body}',
        );
      }
    } catch (e) {
      logError(
        'Ownership check exception: $e',
        eventType: AuthEventType.ownershipCheckException,
        data: {'error': e.toString()},
      );
      throw Exception('Failed to check Minecraft ownership: $e');
    }
  }

  /// Minecraftプロファイルを取得する
  Future<MinecraftProfile> getMinecraftProfile(String accessToken) async {
    log(
      'Calling Minecraft profile API...',
      eventType: AuthEventType.callingMinecraftProfileApi,
    );

    try {
      final response = await http.get(
        Uri.parse('https://api.minecraftservices.com/minecraft/profile'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      log(
        'Profile API response: ${response.statusCode}',
        eventType: AuthEventType.profileApiResponse,
        data: {'statusCode': response.statusCode},
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        log(
          'Profile data received',
          eventType: AuthEventType.profileData,
          data: {'profileData': jsonData},
        );

        return MinecraftProfile.fromJson(jsonData);
      } else {
        logError(
          'Profile retrieval error: ${response.body}',
          eventType: AuthEventType.profileRetrievalError,
          data: {'response': response.body},
        );
        throw Exception('Failed to get Minecraft profile: ${response.body}');
      }
    } catch (e) {
      logError(
        'Profile retrieval exception: $e',
        eventType: AuthEventType.profileRetrievalException,
        data: {'error': e.toString()},
      );
      throw Exception('Exception getting Minecraft profile: $e');
    }
  }

  /// Minecraftトークンをキャッシュする
  void cacheMinecraftToken(String accessToken, int expiresIn) {
    cacheToken(accessToken, expiresIn);
    log('Minecraft token cached, expires in $expiresIn seconds');
  }

  /// キャッシュされたMinecraftトークンを取得する
  String? getMinecraftToken() {
    final token = getToken();
    if (token != null) {
      log(
        'Using cached Minecraft token',
        eventType: AuthEventType.usingCachedMinecraftToken,
      );
    } else {
      log(
        'Cached Minecraft token is invalid or expired',
        eventType: AuthEventType.cachedTokenInvalid,
      );
    }
    return token;
  }
}
