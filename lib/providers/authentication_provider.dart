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

final activeAccountProvider = Provider<Account?>((ref) {
  final authState = ref.watch(authenticationProvider);
  return authState.activeAccount;
});

final authenticationProvider =
    StateNotifierProvider<AuthenticationNotifier, AuthenticationState>((ref) {
      return AuthenticationNotifier();
    });

class AuthenticationState {
  final Map<String, Account> accounts;
  final String? activeMicrosoftAccountId;
  final bool isInitialized;
  final bool isRefreshing;

  const AuthenticationState({
    this.accounts = const {},
    this.activeMicrosoftAccountId,
    this.isInitialized = false,
    this.isRefreshing = false,
  });

  Account? get activeAccount {
    try {
      if (activeMicrosoftAccountId == null) {
        return null;
      }

      return accounts[activeMicrosoftAccountId];
    } catch (_) {
      return null;
    }
  }

  bool get isAuthenticated => activeAccount?.hasValidMinecraftToken ?? false;

  AuthenticationState copyWith({
    Map<String, Account>? accounts,
    String? activeMicrosoftAccountId,
    bool? isInitialized,
    bool? isRefreshing,
  }) {
    return AuthenticationState(
      accounts: accounts ?? this.accounts,
      activeMicrosoftAccountId:
          activeMicrosoftAccountId ?? this.activeMicrosoftAccountId,
      isInitialized: isInitialized ?? this.isInitialized,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

class AuthenticationNotifier extends StateNotifier<AuthenticationState> {
  static const String _accountsKey = 'minecraft_accounts';
  static const String _activeAccountKey = 'active_account';

  final AuthenticationService _authService = AuthenticationService();

  AuthenticationNotifier() : super(const AuthenticationState()) {
    _init();
  }

  Future<void> _init() async {
    await _loadAccounts();

    final activeMicrosoftAccountId = await _getActiveAccountId();
    if (activeMicrosoftAccountId != null) {
      final account = state.accounts[activeMicrosoftAccountId];
      if (account != null && account.hasRefreshToken) {
        debugPrint(
          'アクティブなMicrosoftアカウントIDからリフレッシュトークンを復元: $activeMicrosoftAccountId',
        );
        try {
          if (state.activeAccount == null) {
            await _loginWithMicrosoftAccountId(
              activeMicrosoftAccountId,
              account.microsoftRefreshToken!,
            );
          }
        } catch (e) {
          debugPrint('リフレッシュトークンを使用したサインイン中にエラー: $e');
        }
      }
    }

    state = state.copyWith(isInitialized: true);
  }

  Future<void> _loadAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accountsJson = prefs.getString(_accountsKey);
      final activeId = prefs.getString(_activeAccountKey);

      Map<String, Account> accounts = {};
      if (accountsJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(accountsJson);
        decoded.forEach((key, value) {
          accounts[key] = Account.fromJson(value);
        });
      }

      String? activeMicrosoftAccountId = activeId;

      if (activeMicrosoftAccountId == null && accounts.isNotEmpty) {
        activeMicrosoftAccountId = accounts.keys.first;
        await _saveActiveAccountId(activeMicrosoftAccountId);
      }

      state = state.copyWith(
        accounts: accounts,
        activeMicrosoftAccountId: activeMicrosoftAccountId,
      );
    } catch (e) {
      debugPrint('アカウント読み込みエラー: $e');
      state = state.copyWith(accounts: {}, activeMicrosoftAccountId: null);
    }
  }

  Future<void> _saveAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      Map<String, dynamic> accountsMap = {};
      state.accounts.forEach((key, account) {
        accountsMap[key] = account.toJson();
      });
      final accountsJson = jsonEncode(accountsMap);
      await prefs.setString(_accountsKey, accountsJson);
    } catch (e) {
      debugPrint('アカウント保存エラー: $e');
    }
  }

  Future<void> _saveActiveAccountId(String? microsoftAccountId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (microsoftAccountId != null) {
        await prefs.setString(_activeAccountKey, microsoftAccountId);
      } else {
        await prefs.remove(_activeAccountKey);
      }
    } catch (e) {
      debugPrint('アクティブアカウントID保存エラー: $e');
    }
  }

  Future<String?> _getActiveAccountId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_activeAccountKey);
    } catch (e) {
      debugPrint('アクティブアカウントID取得エラー: $e');
    }
    return null;
  }

  Future<void> _updateAccount(
    String microsoftAccountId,
    Account account,
  ) async {
    if (state.accounts.containsKey(microsoftAccountId)) {
      final updatedAccounts = Map<String, Account>.from(state.accounts);
      updatedAccounts[microsoftAccountId] = account;
      state = state.copyWith(accounts: updatedAccounts);
      await _saveAccounts();
    }
  }

  Future<void> _addAccount(String microsoftAccountId, Account account) async {
    final updatedAccounts = Map<String, Account>.from(state.accounts);
    updatedAccounts[microsoftAccountId] = account;
    state = state.copyWith(accounts: updatedAccounts);
    await _saveAccounts();
  }

  Future<void> removeAccount(String microsoftAccountId) async {
    final updatedAccounts = Map<String, Account>.from(state.accounts);
    updatedAccounts.remove(microsoftAccountId);

    String? newActiveId = state.activeMicrosoftAccountId;
    if (state.activeMicrosoftAccountId == microsoftAccountId) {
      newActiveId =
          updatedAccounts.isNotEmpty ? updatedAccounts.keys.first : null;
      await _saveActiveAccountId(newActiveId);
    }

    state = state.copyWith(
      accounts: updatedAccounts,
      activeMicrosoftAccountId: newActiveId,
    );

    await _saveAccounts();
  }

  Future<bool> setActiveAccount(String? microsoftAccountId) async {
    if (microsoftAccountId == null) {
      state = state.copyWith(activeMicrosoftAccountId: null);
      await _saveActiveAccountId(null);
      return false;
    }

    if (state.accounts.containsKey(microsoftAccountId)) {
      state = state.copyWith(activeMicrosoftAccountId: microsoftAccountId);
      await _saveActiveAccountId(microsoftAccountId);

      final account = state.accounts[microsoftAccountId];

      bool isTokenValid = account?.hasValidMinecraftToken ?? false;

      if (!isTokenValid && account?.hasRefreshToken == true) {
        debugPrint('新しくアクティブになったアカウントのトークンを更新します');
        final profile = await refreshActiveAccount();
        isTokenValid = profile != null;
      }

      return isTokenValid;
    }
    return false;
  }

  Future<void> clearActiveAccount() async {
    state = state.copyWith(activeMicrosoftAccountId: null);
    await _saveActiveAccountId(null);

    if (state.activeMicrosoftAccountId != null) {
      state = AuthenticationState(
        accounts: state.accounts,
        activeMicrosoftAccountId: null,
        isInitialized: state.isInitialized,
        isRefreshing: state.isRefreshing,
      );
    }

    debugPrint('アクティブアカウントがクリアされました（オフラインモード）');
  }

  Future<Account?> restoreLastActiveAccount() async {
    if (state.accounts.isEmpty) {
      debugPrint('復元するアカウントがありません');
      return null;
    }

    final lastUsedAccountId = await _getActiveAccountId();

    final accountId = lastUsedAccountId ?? state.accounts.keys.first;
    debugPrint('アカウント復元: $accountId');

    final isValid = await setActiveAccount(accountId);
    if (isValid) {
      debugPrint(
        '有効なトークンでアカウントを復元しました: ${state.activeAccount?.profile?.name ?? "Unknown"}',
      );
    } else {
      debugPrint(
        'トークンが無効なアカウントを復元しました: ${state.activeAccount?.profile?.name ?? "Unknown"}',
      );
    }

    return state.activeAccount;
  }

  Future<Account?> loginWithActiveAccount() async {
    if (state.activeAccount == null) return null;

    try {
      debugPrint(
        'アクティブアカウントでログイン中: ${state.activeAccount?.profile?.name ?? "Unknown"}',
      );
      final account = state.activeAccount!;

      if (account.hasValidMinecraftToken && account.hasValidXboxToken) {
        debugPrint('有効なトークンがあります、そのまま使用します');
        return account;
      }

      if (account.hasRefreshToken) {
        debugPrint('トークンを更新します');
        final profile = await refreshActiveAccount();
        if (profile != null) {
          debugPrint('トークン更新成功: ${profile.name}');
          return state.activeAccount;
        } else {
          debugPrint('トークン更新失敗');
        }
      }

      return null;
    } catch (e) {
      debugPrint('アクティブアカウントでのログイン中にエラー: $e');
      return null;
    }
  }

  Future<DeviceCodeResponse> startAuthFlow() async {
    return await _authService.getMicrosoftDeviceCode();
  }

  Future<_AuthenticationData> _processAuthentication({
    String? deviceCode,
    String? refreshToken,
  }) async {
    try {
      final msTokenResponse =
          deviceCode != null
              ? await _authService.pollForMicrosoftToken(deviceCode)
              : await _authService.refreshMicrosoftToken(refreshToken!);

      final xboxLiveResponse = await _authService.authenticateWithXboxLive(
        msTokenResponse.accessToken,
      );

      final xstsResponse = await _authService.getXstsToken(
        xboxLiveResponse.token,
      );

      final microsoftAccountId = xboxLiveResponse.displayClaims.xui[0].uhs;
      debugPrint('MicrosoftアカウントID (UHS) を取得: $microsoftAccountId');

      final minecraftData = await _getMinecraftData(
        xstsResponse.displayClaims.xui[0].uhs,
        xstsResponse.token,
      );

      return _AuthenticationData(
        microsoftRefreshToken: msTokenResponse.refreshToken,
        xboxToken: xboxLiveResponse.token,
        xboxTokenExpiry: DateTime.now().add(const Duration(hours: 24)),
        minecraftData: minecraftData,
        microsoftAccountId: microsoftAccountId,
      );
    } catch (e) {
      debugPrint('認証処理エラー: $e');
      rethrow;
    }
  }

  Future<MinecraftProfile?> completeAuthFlow(String deviceCode) async {
    try {
      final authData = await _processAuthentication(deviceCode: deviceCode);

      await _saveActiveAccountId(authData.microsoftAccountId);

      final newAccount = Account(
        id: authData.microsoftAccountId,
        profile: authData.minecraftData.profile,
        microsoftRefreshToken: authData.microsoftRefreshToken,
        xboxToken: authData.xboxToken,
        xboxTokenExpiry: authData.xboxTokenExpiry,
        minecraftAccessToken: authData.minecraftData.accessToken,
        minecraftTokenExpiry: authData.minecraftData.expiresAt,
        isActive: true,
      );

      await _handleAccountUpdate(
        authData.microsoftAccountId,
        newAccount,
        authData.minecraftData.profile,
      );

      return authData.minecraftData.profile;
    } catch (e) {
      debugPrint('認証フロー完了エラー: $e');
      rethrow;
    }
  }

  Future<_MinecraftData> _getMinecraftData(String uhs, String xstsToken) async {
    String? accessToken;
    DateTime? expiresAt;
    MinecraftProfile? profile;

    try {
      debugPrint('Minecraftアクセストークン取得中...');
      final minecraftToken = await _authService.getMinecraftAccessToken(
        uhs,
        xstsToken,
      );

      accessToken = minecraftToken.accessToken;
      expiresAt = DateTime.now().add(
        Duration(seconds: minecraftToken.expiresIn),
      );
      debugPrint('Minecraftアクセストークン取得成功');

      try {
        debugPrint('Minecraft所有権チェック中...');
        final hasGame = await _authService.checkMinecraftOwnership(
          minecraftToken.accessToken,
        );

        if (hasGame) {
          debugPrint('Minecraft所有権確認済み、プロファイル取得中...');
          profile = await _authService.getMinecraftProfile(
            minecraftToken.accessToken,
          );
          debugPrint('Minecraftプロファイル取得成功: ${profile.name}');
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

  Future<void> _handleAccountUpdate(
    String microsoftAccountId,
    Account newAccount,
    MinecraftProfile? profile,
  ) async {
    final updatedAccounts = Map<String, Account>.from(state.accounts);
    updatedAccounts[microsoftAccountId] = newAccount;

    state = state.copyWith(
      accounts: updatedAccounts,
      activeMicrosoftAccountId: microsoftAccountId,
    );

    await _saveActiveAccountId(microsoftAccountId);
    await _saveAccounts();
  }

  Future<bool> swapAccountIndexes(int fromIndex, int toIndex) async {
    try {
      if (fromIndex < 0 || fromIndex >= state.accounts.length) {
        debugPrint(
          'fromIndexが範囲外です: from=$fromIndex, length=${state.accounts.length}',
        );
        return false;
      }

      int adjustedToIndex = toIndex;
      if (adjustedToIndex < 0) {
        adjustedToIndex = 0;
        debugPrint('toIndexが負の値のため0に調整しました');
      } else if (adjustedToIndex > state.accounts.length) {
        adjustedToIndex = state.accounts.length;
        debugPrint('toIndexが範囲外のため、最後のアイテムの次(${state.accounts.length})に調整しました');
      }

      if (fromIndex == adjustedToIndex) {
        return true;
      }
      final accountEntries = state.accounts.entries.toList();

      final fromEntry = accountEntries[fromIndex];

      accountEntries.removeAt(fromIndex);

      accountEntries.insert(
        adjustedToIndex > fromIndex ? adjustedToIndex - 1 : adjustedToIndex,
        fromEntry,
      );

      final reorderedAccounts = Map<String, Account>.fromEntries(
        accountEntries,
      );

      state = state.copyWith(accounts: reorderedAccounts);
      await _saveAccounts();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<MinecraftProfile?> refreshActiveAccount() async {
    if (state.activeAccount == null || state.activeMicrosoftAccountId == null) {
      return null;
    }

    try {
      state = state.copyWith(isRefreshing: true);

      final account = state.activeAccount!;
      final existingProfile = account.profile;
      final microsoftAccountId = state.activeMicrosoftAccountId!;

      debugPrint('アカウント更新開始: ${existingProfile?.name ?? "Unknown"}');

      if (account.microsoftRefreshToken == null) {
        debugPrint('リフレッシュトークンがありません');
        state = state.copyWith(isRefreshing: false);
        return existingProfile;
      }

      debugPrint('認証プロセス開始...');
      final authData = await _processAuthentication(
        refreshToken: account.microsoftRefreshToken!,
      );

      if (authData.minecraftData.profile == null) {
        debugPrint('警告: 認証プロセスでMinecraftプロファイルが取得できませんでした');
        debugPrint('アクセストークン存在: ${authData.minecraftData.accessToken != null}');
        debugPrint('既存プロファイル存在: ${existingProfile != null}');

        if (authData.minecraftData.accessToken != null) {
          debugPrint('直接プロファイル取得を試みます...');
          try {
            final profile = await _authService.getMinecraftProfile(
              authData.minecraftData.accessToken!,
            );

            debugPrint('プロファイル直接取得成功: ${profile.name}');
            final updatedAccount = account.copyWith(
              profile: profile,
              microsoftRefreshToken: authData.microsoftRefreshToken,
              xboxToken: authData.xboxToken,
              xboxTokenExpiry: authData.xboxTokenExpiry,
              minecraftAccessToken: authData.minecraftData.accessToken,
              minecraftTokenExpiry: authData.minecraftData.expiresAt,
            );

            await _updateAccount(microsoftAccountId, updatedAccount);
            state = state.copyWith(isRefreshing: false);
            debugPrint('アカウント更新成功 (直接プロファイル取得): ${profile.name}');
            return profile;
          } catch (e) {
            debugPrint('直接プロファイル取得エラー: $e');
          }
        }
      }

      final profileToUse = authData.minecraftData.profile ?? existingProfile;
      debugPrint('アカウント情報更新中... 使用するプロファイル: ${profileToUse?.name ?? "不明"}');
      final updatedAccount = account.copyWith(
        profile: profileToUse,
        microsoftRefreshToken: authData.microsoftRefreshToken,
        xboxToken: authData.xboxToken,
        xboxTokenExpiry: authData.xboxTokenExpiry,
        minecraftAccessToken: authData.minecraftData.accessToken,
        minecraftTokenExpiry: authData.minecraftData.expiresAt,
      );

      await _updateAccount(microsoftAccountId, updatedAccount);
      state = state.copyWith(isRefreshing: false);

      if (authData.minecraftData.profile != null) {
        debugPrint('アカウント更新成功: ${authData.minecraftData.profile!.name}');
      } else if (profileToUse != null) {
        debugPrint('アカウント更新完了 (既存プロファイル使用: ${profileToUse.name})');
      } else {
        debugPrint('アカウント更新完了 (プロファイル情報なし)');
      }

      return profileToUse;
    } catch (e) {
      debugPrint('アカウント更新エラー: $e');
      state = state.copyWith(isRefreshing: false);

      return state.activeAccount?.profile;
    }
  }

  Future<Account?> silentLogin() async {
    try {
      debugPrint('サイレントログインを実行中...');
      final profile = await _authService.silentLogin();

      if (profile == null) {
        debugPrint('サイレントログイン失敗: プロファイルが取得できませんでした');
        return null;
      }

      final tempMicrosoftAccountId = const Uuid().v4();

      final account = Account(
        id: tempMicrosoftAccountId,
        profile: profile,
        minecraftAccessToken: await _authService.getMinecraftToken(),
        xboxToken: await _authService.getXboxToken(),
        minecraftTokenExpiry: DateTime.now().add(const Duration(hours: 24)),
        xboxTokenExpiry: DateTime.now().add(const Duration(hours: 24)),
        isActive: true,
      );

      await _addAccount(tempMicrosoftAccountId, account);
      await _saveActiveAccountId(tempMicrosoftAccountId);

      debugPrint('サイレントログイン成功: ${profile.name}');
      return account;
    } catch (e) {
      debugPrint('サイレントログイン処理中にエラー: $e');
      return null;
    }
  }

  Future<String?> getMinecraftToken() async {
    if (state.activeAccount == null) return null;

    try {
      final account = state.activeAccount!;

      if (account.hasValidMinecraftToken) {
        return account.minecraftAccessToken;
      }

      if (account.hasRefreshToken) {
        await refreshActiveAccount();

        if (state.activeAccount?.hasValidMinecraftToken ?? false) {
          return state.activeAccount?.minecraftAccessToken;
        }
      }
    } catch (e) {
      debugPrint('Minecraft トークン取得エラー: $e');
    }

    return null;
  }

  Future<String?> getXboxToken() async {
    if (state.activeAccount == null) return null;

    try {
      final account = state.activeAccount!;

      if (account.hasValidXboxToken) {
        return account.xboxToken;
      }

      if (account.hasRefreshToken) {
        await refreshActiveAccount();

        if (state.activeAccount?.hasValidXboxToken ?? false) {
          return state.activeAccount?.xboxToken;
        }
      }
    } catch (e) {
      debugPrint('Xbox トークン取得エラー: $e');
    }

    return null;
  }

  Future<void> logout() async {
    if (state.activeMicrosoftAccountId != null) {
      await removeAccount(state.activeMicrosoftAccountId!);
    }
  }

  Future<String?> getAccessTokenForService() async {
    if (state.activeAccount == null) return null;

    try {
      final account = state.activeAccount!;

      if (account.hasValidMinecraftToken) {
        debugPrint(
          'アクティブなアカウントの有効なトークンを返します: ${account.profile?.name ?? "Unknown"}',
        );
        return account.minecraftAccessToken;
      }

      if (account.hasRefreshToken) {
        debugPrint('トークンを更新します');
        await refreshActiveAccount();

        if (state.activeAccount?.hasValidMinecraftToken ?? false) {
          debugPrint(
            '更新されたトークンを返します: ${state.activeAccount?.profile?.name ?? "Unknown"}',
          );
          return state.activeAccount?.minecraftAccessToken;
        }

        debugPrint('トークン更新後も有効なトークンがありません');
      }
    } catch (e) {
      debugPrint('アクセストークン取得エラー: $e');
    }

    return null;
  }

  Future<MinecraftProfile?> _loginWithMicrosoftAccountId(
    String microsoftAccountId,
    String refreshToken,
  ) async {
    try {
      debugPrint('MicrosoftアカウントID: $microsoftAccountId でサインイン中...');
      final authData = await _processAuthentication(refreshToken: refreshToken);

      if (authData.minecraftData.profile == null) {
        debugPrint('プロファイル情報が取得できませんでした');
        return null;
      }

      final newAccount = Account(
        id: microsoftAccountId,
        profile: authData.minecraftData.profile,
        microsoftRefreshToken: authData.microsoftRefreshToken,
        xboxToken: authData.xboxToken,
        xboxTokenExpiry: authData.xboxTokenExpiry,
        minecraftAccessToken: authData.minecraftData.accessToken,
        minecraftTokenExpiry: authData.minecraftData.expiresAt,
        isActive: true,
      );

      await _handleAccountUpdate(
        microsoftAccountId,
        newAccount,
        authData.minecraftData.profile,
      );

      debugPrint(
        'MicrosoftアカウントIDからのサインイン成功: ${authData.minecraftData.profile?.name}',
      );
      return authData.minecraftData.profile;
    } catch (e) {
      debugPrint('MicrosoftアカウントIDからのサインインエラー: $e');
      return null;
    }
  }
}

class _MinecraftData {
  final String? accessToken;
  final DateTime? expiresAt;
  final MinecraftProfile? profile;

  _MinecraftData({this.accessToken, this.expiresAt, this.profile});
}

class _AuthenticationData {
  final String microsoftRefreshToken;
  final String xboxToken;
  final DateTime xboxTokenExpiry;
  final _MinecraftData minecraftData;
  final String microsoftAccountId;

  _AuthenticationData({
    required this.microsoftRefreshToken,
    required this.xboxToken,
    required this.xboxTokenExpiry,
    required this.minecraftData,
    required this.microsoftAccountId,
  });
}
