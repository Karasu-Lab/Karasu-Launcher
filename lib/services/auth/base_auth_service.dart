import 'package:flutter/foundation.dart';
import 'auth_events.dart';
import 'constants.dart';

/// 認証サービスのベースクラス
///
/// 各認証サービスで共通して使用される機能を提供します。
abstract class BaseAuthService {
  /// デバッグログのコールバック
  LogCallback? onLog;

  /// トークンの有効期限
  DateTime? _tokenExpiry;

  /// アクセストークン
  String? _accessToken;

  /// サービスカテゴリ
  AuthCategory get category;

  /// ログメッセージを出力する
  void log(String message, {AuthEventType? eventType, AuthErrorLevel level = AuthErrorLevel.info, Map<String, dynamic>? data}) {
    if (onLog != null) {
      onLog!(message, eventType: eventType);
    } else {
      debugPrint(message);
    }
  }

  /// 情報レベルのログを出力する
  void logInfo(String message, {AuthEventType? eventType, Map<String, dynamic>? data}) {
    log(message, eventType: eventType, level: AuthErrorLevel.info, data: data);
  }

  /// 警告レベルのログを出力する
  void logWarning(String message, {AuthEventType? eventType, Map<String, dynamic>? data}) {
    log(message, eventType: eventType, level: AuthErrorLevel.warning, data: data);
  }

  /// エラーレベルのログを出力する
  void logError(String message, {AuthEventType? eventType, Map<String, dynamic>? data}) {
    log(message, eventType: eventType, level: AuthErrorLevel.error, data: data);
  }

  /// クリティカルエラーレベルのログを出力する
  void logCritical(String message, {AuthEventType? eventType, Map<String, dynamic>? data}) {
    log(message, eventType: eventType, level: AuthErrorLevel.critical, data: data);
  }

  /// トークンをキャッシュする
  void cacheToken(String token, int expiresIn) {
    _accessToken = token;
    _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));
    log('Token cached, expires in $expiresIn seconds', 
        eventType: AuthEventType.tokenCached,
        data: {'expiresIn': expiresIn});
  }

  /// キャッシュされたトークンを取得する
  String? getToken() {
    if (_accessToken != null &&
        _tokenExpiry != null &&
        _tokenExpiry!.isAfter(DateTime.now())) {
      log('Using cached token', eventType: AuthEventType.usingCachedToken);
      return _accessToken;
    }

    log('Cached token is invalid or expired', eventType: AuthEventType.cachedTokenInvalid);
    return null;
  }

  /// キャッシュをクリアする
  void clearCache() {
    _accessToken = null;
    _tokenExpiry = null;
    log('Token cache cleared', eventType: AuthEventType.tokenCacheCleared);
  }

  /// トークンが有効かどうかを確認する
  bool isTokenValid() {
    return _accessToken != null &&
        _tokenExpiry != null &&
        _tokenExpiry!.isAfter(DateTime.now());
  }
}
