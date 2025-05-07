/// 認証プロセス中のイベントタイプを表すenum
enum AuthEventType {
  // Microsoft認証関連イベント
  /// Microsoft Device Code取得リクエスト
  requestingMicrosoftDeviceCode('log.auth.microsoft.requesting_device_code'),

  /// Device Code取得成功
  deviceCodeObtained('log.auth.microsoft.device_code_obtained'),

  /// Microsoft認証のポーリング開始
  startingMicrosoftTokenPolling('log.auth.microsoft.starting_token_polling'),

  /// トークン認証ポーリング
  pollingForTokenAuthorization('log.auth.microsoft.polling_for_authorization'),

  /// Microsoft認証成功
  microsoftAuthorizationSuccessful('log.auth.microsoft.authorization_successful'),

  /// 認証待ち
  authorizationPending('log.auth.microsoft.authorization_pending'),

  /// Device Codeの有効期限切れ
  deviceCodeExpired('log.auth.microsoft.device_code_expired'),

  /// Microsoftトークン更新
  refreshingMicrosoftToken('log.auth.microsoft.refreshing_token'),

  /// Microsoftトークン更新成功
  microsoftTokenRefreshed('log.auth.microsoft.token_refreshed'),

  /// Microsoftリフレッシュトークンをキャッシュ
  microsoftRefreshTokenCached('log.auth.microsoft.refresh_token_cached'),

  /// キャッシュされたMicrosoftリフレッシュトークン使用
  usingCachedMicrosoftRefreshToken('log.auth.microsoft.using_cached_refresh_token'),

  /// キャッシュされたMicrosoftリフレッシュトークンなし
  noCachedMicrosoftRefreshToken('log.auth.microsoft.no_cached_refresh_token'),

  // Xbox認証関連イベント
  /// Xbox Live認証
  xboxLiveAuthentication('log.auth.xbox.live_authentication'),

  /// Xbox Liveプロフィール取得
  gettingXboxProfile('log.auth.xbox.getting_profile'),

  /// XSTSトークン取得
  gettingXstsToken('log.auth.xbox.getting_xsts_token'),

  /// UHS情報
  uhsInfo('log.auth.xbox.uhs_info'),

  /// XSTSトークン情報
  xstsTokenInfo('log.auth.xbox.xsts_token_info'),

  /// Xuid取得
  extractedXuid('log.auth.xbox.extracted_xuid'),

  /// Xuidの取得失敗
  failedToExtractXuid('log.auth.xbox.failed_to_extract_xuid'),

  /// Xboxトークンをキャッシュ
  xboxTokenCached('log.auth.xbox.token_cached'),

  /// キャッシュされたXboxトークン使用
  usingCachedXboxToken('log.auth.xbox.using_cached_token'),

  /// キャッシュされたXboxトークン無効
  cachedXboxTokenInvalid('log.auth.xbox.cached_token_invalid'),

  /// Minecraftの所有権確認
  checkingMinecraftOwnership('log.auth.minecraft.checking_ownership'),

  /// 所有権確認のレスポンス
  ownershipCheckResponse('log.auth.minecraft.ownership_check_response'),

  /// 所有権データ
  ownershipData('log.auth.minecraft.ownership_data'),

  /// 所有権アイテムなし
  noItemsInEntitlement('log.auth.minecraft.no_items_in_entitlement'),

  /// 所有権チェックエラー
  ownershipCheckError('log.auth.minecraft.ownership_check_error'),

  /// 所有権チェック例外
  ownershipCheckException('log.auth.minecraft.ownership_check_exception'),

  /// Minecraftプロファイル取得
  callingMinecraftProfileApi('log.auth.minecraft.calling_profile_api'),

  /// プロファイルAPIレスポンス
  profileApiResponse('log.auth.minecraft.profile_api_response'),

  /// プロファイルデータ
  profileData('log.auth.minecraft.profile_data'),

  /// プロファイル取得エラー
  profileRetrievalError('log.auth.minecraft.profile_retrieval_error'),

  /// プロファイル取得例外
  profileRetrievalException('log.auth.minecraft.profile_retrieval_exception'),

  /// キャッシュされたトークン使用
  usingCachedMinecraftToken('log.auth.minecraft.using_cached_token'),

  /// キャッシュトークン無効
  cachedTokenInvalid('log.auth.minecraft.cached_token_invalid'),

  // 一般認証イベント
  /// トークンキャッシュ
  tokenCached('log.auth.common.token_cached'),

  /// キャッシュされたトークン使用
  usingCachedToken('log.auth.common.using_cached_token'),

  /// トークンキャッシュクリア
  tokenCacheCleared('log.auth.common.token_cache_cleared');

  /// 翻訳キー
  final String key;

  /// コンストラクタ
  const AuthEventType(this.key);
}

/// 認証イベントに関する情報を保持するクラス
class AuthEvent {
  /// イベントの種類
  final AuthEventType type;

  /// 追加情報（任意）
  final Map<String, dynamic>? data;

  /// コンストラクタ
  const AuthEvent(this.type, [this.data]);

  @override
  String toString() {
    if (data != null) {
      return '${type.name}: $data';
    }
    return type.name;
  }
}

/// 認証サービスのカテゴリ
enum AuthCategory {
  /// Microsoft認証
  microsoft,

  /// Xbox認証
  xbox,

  /// Minecraft認証
  minecraft,

  /// 共通認証
  common,
}

/// 認証エラーレベル
enum AuthErrorLevel {
  /// 情報
  info,

  /// 警告
  warning,

  /// エラー
  error,

  /// 深刻なエラー
  critical,
}
