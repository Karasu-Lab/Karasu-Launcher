import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  Future<void> init() async {
    if (!state.isInitialized) {
      await _init();
    }
  }

  Future<void> _init() async {
    await _loadAccounts();

    final activeMicrosoftAccountId = await _getActiveAccountId();
    if (activeMicrosoftAccountId != null) {
      final account = state.accounts[activeMicrosoftAccountId];
      if (account != null && account.hasRefreshToken) {
        debugPrint(
          'Restoring refresh token from active Microsoft account ID: $activeMicrosoftAccountId',
        );
        try {
          if (state.activeAccount == null) {
            await _loginWithMicrosoftAccountId(
              activeMicrosoftAccountId,
              account.microsoftRefreshToken!,
            );
          }
        } catch (e) {
          debugPrint('Error signing in with refresh token: $e');
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
      debugPrint('Error loading accounts: $e');
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
      debugPrint('Error saving accounts: $e');
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
      debugPrint('Error saving active account ID: $e');
    }
  }

  Future<String?> _getActiveAccountId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_activeAccountKey);
    } catch (e) {
      debugPrint('Error retrieving active account ID: $e');
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
        debugPrint('Updating tokens for newly active account');
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

    debugPrint('Active account has been cleared (offline mode)');
  }

  Future<Account?> restoreLastActiveAccount() async {
    if (state.accounts.isEmpty) {
      debugPrint('No accounts to restore');
      return null;
    }

    final lastUsedAccountId = await _getActiveAccountId();

    final accountId = lastUsedAccountId ?? state.accounts.keys.first;
    debugPrint('Restoring account: $accountId');

    final isValid = await setActiveAccount(accountId);
    if (isValid) {
      debugPrint(
        'Restored account with valid token: ${state.activeAccount?.profile?.name ?? "Unknown"}',
      );
    } else {
      debugPrint(
        'Restored account with invalid token: ${state.activeAccount?.profile?.name ?? "Unknown"}',
      );
    }

    return state.activeAccount;
  }

  Future<Account?> loginWithActiveAccount() async {
    if (state.activeAccount == null) return null;

    try {
      debugPrint(
        'Logging in with active account: ${state.activeAccount?.profile?.name ?? "Unknown"}',
      );
      final account = state.activeAccount!;

      if (account.hasValidMinecraftToken && account.hasValidXboxToken) {
        debugPrint('Valid tokens available, using existing tokens');
        return account;
      }

      if (account.hasRefreshToken) {
        debugPrint('Refreshing tokens');
        final profile = await refreshActiveAccount();
        if (profile != null) {
          debugPrint('Token refresh successful: ${profile.name}');
          return state.activeAccount;
        } else {
          debugPrint('Token refresh failed');
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error logging in with active account: $e');
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

      final xuid = xboxLiveResponse.displayClaims.xui[0].uhs;
      debugPrint('Retrieved Microsoft account ID (UHS): $microsoftAccountId');
      debugPrint('Retrieved Xbox XUID: $xuid');

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
        xuid: xuid,
      );
    } catch (e) {
      debugPrint('Authentication process error: $e');
      rethrow;
    }
  }

  Account _createOrUpdateAccount(
    String microsoftAccountId,
    _AuthenticationData authData,
    Account? existingAccount,
  ) {
    final minecraftProfile = authData.minecraftData.profile;
    final minecraftId = minecraftProfile?.id;

    if (existingAccount != null) {
      debugPrint(
        'Updating existing Microsoft account: $microsoftAccountId (Minecraft ID: $minecraftId)',
      );
      return existingAccount.copyWith(
        profile: authData.minecraftData.profile,
        microsoftRefreshToken: authData.microsoftRefreshToken,
        xboxToken: authData.xboxToken,
        xboxTokenExpiry: authData.xboxTokenExpiry,
        minecraftAccessToken: authData.minecraftData.accessToken,
        minecraftTokenExpiry: authData.minecraftData.expiresAt,
        isActive: true,
        xuid: authData.xuid,
      );
    } else {
      debugPrint(
        'Adding new Microsoft account: $microsoftAccountId (Minecraft ID: $minecraftId)',
      );
      return Account(
        id: microsoftAccountId,
        profile: authData.minecraftData.profile,
        microsoftRefreshToken: authData.microsoftRefreshToken,
        xboxToken: authData.xboxToken,
        xboxTokenExpiry: authData.xboxTokenExpiry,
        minecraftAccessToken: authData.minecraftData.accessToken,
        minecraftTokenExpiry: authData.minecraftData.expiresAt,
        isActive: true,
        xuid: authData.xuid,
      );
    }
  }

  Future<MinecraftProfile?> completeAuthFlow(String deviceCode) async {
    try {
      final authData = await _processAuthentication(deviceCode: deviceCode);
      final microsoftAccountId = authData.microsoftAccountId;

      await _saveActiveAccountId(microsoftAccountId);

      final existingAccount = state.accounts[microsoftAccountId];

      final Account updatedAccount = _createOrUpdateAccount(
        microsoftAccountId,
        authData,
        existingAccount,
      );

      await _handleAccountUpdate(
        microsoftAccountId,
        updatedAccount,
        authData.minecraftData.profile,
      );

      return authData.minecraftData.profile;
    } catch (e) {
      debugPrint('Error completing authentication flow: $e');
      rethrow;
    }
  }

  Future<_MinecraftData> _getMinecraftData(String uhs, String xstsToken) async {
    String? accessToken;
    DateTime? expiresAt;
    MinecraftProfile? profile;

    try {
      debugPrint('Getting Minecraft access token...');
      final minecraftToken = await _authService.getMinecraftAccessToken(
        uhs,
        xstsToken,
      );

      accessToken = minecraftToken.accessToken;
      expiresAt = DateTime.now().add(
        Duration(seconds: minecraftToken.expiresIn),
      );
      debugPrint('Successfully obtained Minecraft access token');

      try {
        debugPrint('Checking Minecraft ownership...');
        final hasGame = await _authService.checkMinecraftOwnership(
          minecraftToken.accessToken,
        );

        if (hasGame) {
          debugPrint('Minecraft ownership confirmed, getting profile...');
          profile = await _authService.getMinecraftProfile(
            minecraftToken.accessToken,
          );
          debugPrint(
            'Successfully retrieved Minecraft profile: ${profile.name}',
          );
        } else {
          debugPrint('No ownership of Minecraft: Java Edition');
        }
      } catch (e) {
        debugPrint('Error getting Minecraft ownership/profile: $e');
      }
    } catch (e) {
      debugPrint('Error getting Minecraft token: $e');
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

    if (profile != null) {
      final minecraftId = profile.id;
      debugPrint('Checking for duplicate Minecraft ID: $minecraftId');

      final duplicateAccountIds =
          updatedAccounts.entries
              .where(
                (entry) =>
                    entry.key != microsoftAccountId &&
                    entry.value.profile?.id == minecraftId,
              )
              .map((e) => e.key)
              .toList();

      if (duplicateAccountIds.isNotEmpty) {
        for (final accountId in duplicateAccountIds) {
          debugPrint(
            'Removing account with duplicate Minecraft ID: $accountId',
          );
          updatedAccounts.remove(accountId);
        }
      }
    }

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
          'fromIndex out of bounds: from=$fromIndex, length=${state.accounts.length}',
        );
        return false;
      }

      int adjustedToIndex = toIndex;
      if (adjustedToIndex < 0) {
        adjustedToIndex = 0;
        debugPrint('Adjusted negative toIndex to 0');
      } else if (adjustedToIndex > state.accounts.length) {
        adjustedToIndex = state.accounts.length;
        debugPrint(
          'Adjusted toIndex to position after the last item (${state.accounts.length})',
        );
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

      debugPrint(
        'Starting account refresh: ${existingProfile?.name ?? "Unknown"}',
      );

      if (account.microsoftRefreshToken == null) {
        debugPrint('No refresh token available');
        state = state.copyWith(isRefreshing: false);
        return existingProfile;
      }

      debugPrint('Starting authentication process...');
      final authData = await _processAuthentication(
        refreshToken: account.microsoftRefreshToken!,
      );

      if (authData.minecraftData.profile == null) {
        debugPrint(
          'Warning: No Minecraft profile obtained from authentication process',
        );
        debugPrint(
          'Access token exists: ${authData.minecraftData.accessToken != null}',
        );
        debugPrint('Existing profile exists: ${existingProfile != null}');

        if (authData.minecraftData.accessToken != null) {
          debugPrint('Attempting direct profile retrieval...');
          try {
            final profile = await _authService.getMinecraftProfile(
              authData.minecraftData.accessToken!,
            );

            debugPrint('Direct profile retrieval successful: ${profile.name}');
            final updatedAccount = account.copyWith(
              profile: profile,
              microsoftRefreshToken: authData.microsoftRefreshToken,
              xboxToken: authData.xboxToken,
              xboxTokenExpiry: authData.xboxTokenExpiry,
              minecraftAccessToken: authData.minecraftData.accessToken,
              minecraftTokenExpiry: authData.minecraftData.expiresAt,
              xuid: authData.xuid,
            );

            await _updateAccount(microsoftAccountId, updatedAccount);
            state = state.copyWith(isRefreshing: false);
            debugPrint(
              'Account update successful (direct profile retrieval): ${profile.name}',
            );
            return profile;
          } catch (e) {
            debugPrint('Error retrieving profile directly: $e');
          }
        }
      }

      final profileToUse = authData.minecraftData.profile ?? existingProfile;
      debugPrint(
        'Updating account information... Using profile: ${profileToUse?.name ?? "unknown"}',
      );
      final updatedAccount = account.copyWith(
        profile: profileToUse,
        microsoftRefreshToken: authData.microsoftRefreshToken,
        xboxToken: authData.xboxToken,
        xboxTokenExpiry: authData.xboxTokenExpiry,
        minecraftAccessToken: authData.minecraftData.accessToken,
        minecraftTokenExpiry: authData.minecraftData.expiresAt,
        xuid: authData.xuid,
      );

      await _updateAccount(microsoftAccountId, updatedAccount);
      state = state.copyWith(isRefreshing: false);

      if (authData.minecraftData.profile != null) {
        debugPrint(
          'Account update successful: ${authData.minecraftData.profile!.name}',
        );
      } else if (profileToUse != null) {
        debugPrint(
          'Account update completed (using existing profile: ${profileToUse.name})',
        );
      } else {
        debugPrint('Account update completed (no profile information)');
      }

      return profileToUse;
    } catch (e) {
      debugPrint('Error updating account: $e');
      state = state.copyWith(isRefreshing: false);

      return state.activeAccount?.profile;
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
      debugPrint('Error retrieving Minecraft token: $e');
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
      debugPrint('Error retrieving Xbox token: $e');
    }

    return null;
  }

  Future<void> logout() async {
    if (state.activeMicrosoftAccountId != null) {
      await removeAccount(state.activeMicrosoftAccountId!);
    }
  }

  Future<void> logoutMicrosoftAccount(String microsoftAccountId) async {
    try {
      debugPrint('Signing out Microsoft account: $microsoftAccountId');

      if (!state.accounts.containsKey(microsoftAccountId)) {
        debugPrint('Account not found: $microsoftAccountId');
        return;
      }

      final isActiveAccount =
          state.activeMicrosoftAccountId == microsoftAccountId;
      final updatedAccounts = Map<String, Account>.from(state.accounts);
      updatedAccounts.remove(microsoftAccountId);

      String? newActiveId;

      if (isActiveAccount) {
        if (updatedAccounts.isNotEmpty) {
          newActiveId = updatedAccounts.keys.first;
          debugPrint('Switching to new active account: $newActiveId');
        } else {
          newActiveId = null;
          debugPrint('No accounts left, switching to offline mode');
        }
        await _saveActiveAccountId(newActiveId);
      }

      state = state.copyWith(
        accounts: updatedAccounts,
        activeMicrosoftAccountId:
            isActiveAccount ? newActiveId : state.activeMicrosoftAccountId,
      );

      await _saveAccounts();
      debugPrint('Account removal from storage completed: $microsoftAccountId');
    } catch (e) {
      debugPrint('Error occurred during sign out: $e');
    }
  }

  Future<String?> getAccessTokenForService() async {
    if (state.activeAccount == null) return null;

    try {
      final account = state.activeAccount!;

      if (account.hasValidMinecraftToken) {
        debugPrint(
          'Returning valid token from active account: ${account.profile?.name ?? "Unknown"}',
        );
        return account.minecraftAccessToken;
      }

      if (account.hasRefreshToken) {
        debugPrint('Refreshing token');
        await refreshActiveAccount();

        if (state.activeAccount?.hasValidMinecraftToken ?? false) {
          debugPrint(
            'Returning refreshed token: ${state.activeAccount?.profile?.name ?? "Unknown"}',
          );
          return state.activeAccount?.minecraftAccessToken;
        }

        debugPrint('No valid token after refresh');
      }
    } catch (e) {
      debugPrint('Error retrieving access token: $e');
    }

    return null;
  }

  Future<MinecraftProfile?> _loginWithMicrosoftAccountId(
    String microsoftAccountId,
    String refreshToken,
  ) async {
    try {
      debugPrint(
        'Signing in with Microsoft account ID: $microsoftAccountId...',
      );
      final authData = await _processAuthentication(refreshToken: refreshToken);

      if (authData.minecraftData.profile == null) {
        debugPrint('Failed to retrieve profile information');
        return null;
      }

      final existingAccount = state.accounts[microsoftAccountId];

      final Account updatedAccount = _createOrUpdateAccount(
        microsoftAccountId,
        authData,
        existingAccount,
      );

      await _handleAccountUpdate(
        microsoftAccountId,
        updatedAccount,
        authData.minecraftData.profile,
      );

      debugPrint(
        'Sign in successful with Microsoft account ID: ${authData.minecraftData.profile?.name}',
      );
      return authData.minecraftData.profile;
    } catch (e) {
      debugPrint('Error signing in with Microsoft account ID: $e');
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
  final String? xuid;

  _AuthenticationData({
    required this.microsoftRefreshToken,
    required this.xboxToken,
    required this.xboxTokenExpiry,
    required this.minecraftData,
    required this.microsoftAccountId,
    this.xuid,
  });
}
