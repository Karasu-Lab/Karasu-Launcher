import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/auth/account.dart';
import '../models/auth/device_code_response.dart';
import '../models/auth/minecraft_profile.dart';
import '../services/authentication_service.dart';

// 認証状態を管理するプロバイダー
final authenticationProvider =
    StateNotifierProvider<AuthenticationNotifier, AuthenticationState>((ref) {
      return AuthenticationNotifier();
    });

// 認証状態を表すクラス
class AuthenticationState {
  final List<Account> accounts;
  final String? activeAccountId;
  final bool isInitialized;

  const AuthenticationState({
    this.accounts = const [],
    this.activeAccountId,
    this.isInitialized = false,
  });

  // アクティブなアカウントを取得
  Account? get activeAccount {
    try {
      return accounts.firstWhere((account) => account.id == activeAccountId);
    } catch (_) {
      return accounts.isNotEmpty ? accounts.first : null;
    }
  }

  // 有効なMinecraftトークンがあるか
  bool get isAuthenticated => activeAccount?.hasValidMinecraftToken ?? false;

  // 状態をコピーして新しいインスタンスを作成
  AuthenticationState copyWith({
    List<Account>? accounts,
    String? activeAccountId,
    bool? isInitialized,
  }) {
    return AuthenticationState(
      accounts: accounts ?? this.accounts,
      activeAccountId: activeAccountId ?? this.activeAccountId,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

class AuthenticationNotifier extends StateNotifier<AuthenticationState> {
  static const String _accountsKey = 'minecraft_accounts';
  static const String _activeAccountIdKey = 'active_account_id';

  final AuthenticationService _authService = AuthenticationService();

  AuthenticationNotifier() : super(const AuthenticationState()) {
    _init();
  }

  // 初期化処理
  Future<void> _init() async {
    await _loadAccounts();
    state = state.copyWith(isInitialized: true);
  }

  // アカウントリストを読み込む
  Future<void> _loadAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accountsJson = prefs.getString(_accountsKey);
      final activeId = prefs.getString(_activeAccountIdKey);

      List<Account> accounts = [];
      if (accountsJson != null) {
        final List<dynamic> decoded = jsonDecode(accountsJson);
        accounts = decoded.map((json) => Account.fromJson(json)).toList();
      }

      String? activeAccountId = activeId;

      // アクティブなアカウントの設定
      if (activeAccountId == null && accounts.isNotEmpty) {
        // アクティブなアカウントが設定されていない場合、最初のアカウントをアクティブにする
        activeAccountId = accounts.first.id;
        await _saveActiveAccountId(activeAccountId);
      }

      state = state.copyWith(
        accounts: accounts,
        activeAccountId: activeAccountId,
      );
    } catch (e) {
      debugPrint('アカウント読み込みエラー: $e');
      state = state.copyWith(accounts: [], activeAccountId: null);
    }
  }

  // アカウントリストを保存
  Future<void> _saveAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accountsJson = jsonEncode(
        state.accounts.map((acc) => acc.toJson()).toList(),
      );
      await prefs.setString(_accountsKey, accountsJson);
    } catch (e) {
      debugPrint('アカウント保存エラー: $e');
    }
  }

  // アクティブなアカウントIDを保存
  Future<void> _saveActiveAccountId(String? activeId) async {
    try {
      if (activeId != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_activeAccountIdKey, activeId);
      }
    } catch (e) {
      debugPrint('アクティブアカウントID保存エラー: $e');
    }
  }

  // アカウントを更新
  Future<void> _updateAccount(Account account) async {
    final index = state.accounts.indexWhere((a) => a.id == account.id);
    if (index >= 0) {
      final updatedAccounts = [...state.accounts];
      updatedAccounts[index] = account;
      state = state.copyWith(accounts: updatedAccounts);
      await _saveAccounts();
    }
  }

  // アカウントを追加
  Future<void> _addAccount(Account account) async {
    final updatedAccounts = [...state.accounts, account];
    state = state.copyWith(accounts: updatedAccounts);
    await _saveAccounts();
  }

  // アカウントを削除
  Future<void> removeAccount(String accountId) async {
    final updatedAccounts =
        state.accounts.where((account) => account.id != accountId).toList();

    // 削除したアカウントがアクティブだった場合、新しいアクティブアカウントを設定
    String? newActiveId = state.activeAccountId;
    if (state.activeAccountId == accountId) {
      newActiveId =
          updatedAccounts.isNotEmpty ? updatedAccounts.first.id : null;
      await _saveActiveAccountId(newActiveId);
    }

    state = state.copyWith(
      accounts: updatedAccounts,
      activeAccountId: newActiveId,
    );

    await _saveAccounts();
  }

  // アカウント切り替え
  Future<void> setActiveAccount(String accountId) async {
    if (state.accounts.any((account) => account.id == accountId)) {
      state = state.copyWith(activeAccountId: accountId);
      await _saveActiveAccountId(accountId);
    }
  }

  // 新しい認証フローを開始
  Future<DeviceCodeResponse> startAuthFlow() async {
    return await _authService.getMicrosoftDeviceCode();
  }

  // Microsoft認証からMinecraftプロファイル取得までの共通処理
  Future<_AuthenticationData> _processAuthentication({
    String? deviceCode,
    String? refreshToken,
  }) async {
    try {
      // Microsoft認証トークン取得
      final msTokenResponse =
          deviceCode != null
              ? await _authService.pollForMicrosoftToken(deviceCode)
              : await _authService.refreshMicrosoftToken(refreshToken!);

      // Xbox Live認証
      final xboxLiveResponse = await _authService.authenticateWithXboxLive(
        msTokenResponse.accessToken,
      );

      // XSTSトークン取得
      final xstsResponse = await _authService.getXstsToken(
        xboxLiveResponse.token,
      );

      // Minecraftデータ取得
      final minecraftData = await _getMinecraftData(
        xstsResponse.displayClaims.xui[0].uhs,
        xstsResponse.token,
      );

      return _AuthenticationData(
        microsoftRefreshToken: msTokenResponse.refreshToken,
        xboxToken: xboxLiveResponse.token,
        xboxTokenExpiry: DateTime.now().add(const Duration(hours: 24)),
        minecraftData: minecraftData,
      );
    } catch (e) {
      debugPrint('認証処理エラー: $e');
      rethrow;
    }
  }

  // 認証フローをポーリングして完了
  Future<MinecraftProfile?> completeAuthFlow(String deviceCode) async {
    try {
      // 認証処理
      final authData = await _processAuthentication(deviceCode: deviceCode);

      // 新しいアカウント作成
      final newAccount = Account(
        id: const Uuid().v4(),
        profile: authData.minecraftData.profile,
        microsoftRefreshToken: authData.microsoftRefreshToken,
        xboxToken: authData.xboxToken,
        xboxTokenExpiry: authData.xboxTokenExpiry,
        minecraftAccessToken: authData.minecraftData.accessToken,
        minecraftTokenExpiry: authData.minecraftData.expiresAt,
        isActive: true,
      );

      await _handleAccountUpdate(newAccount, authData.minecraftData.profile);

      return authData.minecraftData.profile;
    } catch (e) {
      debugPrint('認証フロー完了エラー: $e');
      rethrow;
    }
  }

  // Minecraftデータ(トークン, プロファイル)を取得する共通メソッド
  Future<_MinecraftData> _getMinecraftData(String uhs, String xstsToken) async {
    String? accessToken;
    DateTime? expiresAt;
    MinecraftProfile? profile;

    try {
      // Minecraftアクセストークン取得
      final minecraftToken = await _authService.getMinecraftAccessToken(
        uhs,
        xstsToken,
      );

      accessToken = minecraftToken.accessToken;
      expiresAt = DateTime.now().add(
        Duration(seconds: minecraftToken.expiresIn),
      );

      try {
        // 所有権チェック
        final hasGame = await _authService.checkMinecraftOwnership(
          minecraftToken.accessToken,
        );

        if (hasGame) {
          // プロファイル取得
          profile = await _authService.getMinecraftProfile(
            minecraftToken.accessToken,
          );
        } else {
          debugPrint('Minecraft: Java Editionの所有権がありません');
        }
      } catch (e) {
        debugPrint('Minecraft所有権/プロファイル取得エラー: $e');
      }
    } catch (e) {
      debugPrint('Minecraftトークン取得エラー: $e');
    }

    return _MinecraftData(
      accessToken: accessToken,
      expiresAt: expiresAt,
      profile: profile,
    );
  }

  // アカウント更新と保存を処理する共通メソッド
  Future<void> _handleAccountUpdate(
    Account newAccount,
    MinecraftProfile? profile,
  ) async {
    int existingAccountIndex = -1;
    if (profile != null) {
      existingAccountIndex = state.accounts.indexWhere(
        (acc) => acc.profile?.id == profile.id,
      );
    }

    if (existingAccountIndex >= 0) {
      // 既存アカウント更新
      final updatedAccounts = [...state.accounts];
      updatedAccounts[existingAccountIndex] = newAccount;
      state = state.copyWith(
        accounts: updatedAccounts,
        activeAccountId: newAccount.id,
      );
    } else {
      // 新規アカウント追加
      state = state.copyWith(
        accounts: [...state.accounts, newAccount],
        activeAccountId: newAccount.id,
      );
    }

    await _saveActiveAccountId(newAccount.id);
    await _saveAccounts();
  }

  // アクティブアカウントの認証状態を更新
  Future<MinecraftProfile?> refreshActiveAccount() async {
    if (state.activeAccount == null) return null;

    try {
      final account = state.activeAccount!;

      // リフレッシュトークンがない場合は更新不可
      if (account.microsoftRefreshToken == null) {
        return null;
      }

      // 認証処理
      final authData = await _processAuthentication(
        refreshToken: account.microsoftRefreshToken!,
      );

      // アカウント更新
      final updatedAccount = account.copyWith(
        profile: authData.minecraftData.profile ?? account.profile,
        microsoftRefreshToken: authData.microsoftRefreshToken,
        xboxToken: authData.xboxToken,
        xboxTokenExpiry: authData.xboxTokenExpiry,
        minecraftAccessToken: authData.minecraftData.accessToken,
        minecraftTokenExpiry: authData.minecraftData.expiresAt,
      );

      await _updateAccount(updatedAccount);

      return authData.minecraftData.profile;
    } catch (e) {
      debugPrint('アカウント更新エラー: $e');
      return null;
    }
  }

  // アクティブアカウントのMinecraftアクセストークンを取得
  Future<String?> getMinecraftToken() async {
    if (state.activeAccount == null) return null;

    try {
      final account = state.activeAccount!;

      // 有効なトークンがあればそれを返す
      if (account.hasValidMinecraftToken) {
        return account.minecraftAccessToken;
      }

      // トークンが無効な場合は更新を試みる
      if (account.hasRefreshToken) {
        final profile = await refreshActiveAccount();
        if (profile != null) {
          return state.activeAccount?.minecraftAccessToken;
        }
      }
    } catch (e) {
      debugPrint('Minecraft トークン取得エラー: $e');
    }

    return null;
  }

  // アクティブアカウントのXboxトークンを取得
  Future<String?> getXboxToken() async {
    if (state.activeAccount == null) return null;

    try {
      final account = state.activeAccount!;

      // 有効なトークンがあればそれを返す
      if (account.hasValidXboxToken) {
        return account.xboxToken;
      }

      // トークンが無効な場合は更新を試みる
      if (account.hasRefreshToken) {
        final profile = await refreshActiveAccount();
        if (profile != null) {
          return state.activeAccount?.xboxToken;
        }
      }
    } catch (e) {
      debugPrint('Xbox トークン取得エラー: $e');
    }

    return null;
  }

  // ログアウト処理（アクティブアカウントを削除）
  Future<void> logout() async {
    if (state.activeAccountId != null) {
      await removeAccount(state.activeAccountId!);
    }
  }
}

// Minecraftデータを保持する内部クラス
class _MinecraftData {
  final String? accessToken;
  final DateTime? expiresAt;
  final MinecraftProfile? profile;

  _MinecraftData({this.accessToken, this.expiresAt, this.profile});
}

// 認証データを保持する内部クラス
class _AuthenticationData {
  final String microsoftRefreshToken;
  final String xboxToken;
  final DateTime xboxTokenExpiry;
  final _MinecraftData minecraftData;

  _AuthenticationData({
    required this.microsoftRefreshToken,
    required this.xboxToken,
    required this.xboxTokenExpiry,
    required this.minecraftData,
  });
}
