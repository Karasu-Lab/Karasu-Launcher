import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:karasu_launcher/providers/authentication_provider.dart';
import 'package:karasu_launcher/providers/profiles_provider.dart';
import 'package:karasu_launcher/services/auth/auth_events.dart';

class LoadingState {
  final bool isLoading;
  final String loadingMessage;
  final String? errorMessage;
  final bool hasError;
  final bool showMinecraftFace;
  final String? profileName;
  final String? skinUrl;
  final AuthEvent? authMessage;
  final List<AuthEvent> authMessages;

  LoadingState({
    this.isLoading = true,
    this.loadingMessage = '',
    this.errorMessage,
    this.hasError = false,
    this.showMinecraftFace = false,
    this.profileName,
    this.skinUrl,
    this.authMessage,
    this.authMessages = const [],
  });

  LoadingState copyWith({
    bool? isLoading,
    String? loadingMessage,
    String? errorMessage,
    bool? hasError,
    bool? showMinecraftFace,
    String? profileName,
    String? skinUrl,
    AuthEvent? authMessage,
    List<AuthEvent>? authMessages,
  }) {
    return LoadingState(
      isLoading: isLoading ?? this.isLoading,
      loadingMessage: loadingMessage ?? this.loadingMessage,
      errorMessage: errorMessage ?? this.errorMessage,
      hasError: hasError ?? this.hasError,
      showMinecraftFace: showMinecraftFace ?? this.showMinecraftFace,
      profileName: profileName ?? this.profileName,
      skinUrl: skinUrl ?? this.skinUrl,
      authMessage: authMessage ?? this.authMessage,
      authMessages: authMessages ?? this.authMessages,
    );
  }
}

class LoadingNotifier extends StateNotifier<LoadingState> {
  final Ref ref;
  static const int _maxAuthMessages = 5;

  LoadingNotifier(this.ref) : super(LoadingState());

  void setLoadingMessage(String message) {
    state = state.copyWith(loadingMessage: message);
  }

  void setAuthMessage(AuthEvent? message) {
    if (message == null) return;

    final List<AuthEvent> updatedMessages = [...state.authMessages];

    updatedMessages.add(message);

    if (updatedMessages.length > _maxAuthMessages) {
      updatedMessages.removeAt(0);
    }

    state = state.copyWith(authMessage: message, authMessages: updatedMessages);
  }

  void setError(String errorMessage, String loadingMessage) {
    state = state.copyWith(
      hasError: true,
      errorMessage: errorMessage,
      loadingMessage: loadingMessage,
    );
  }

  void setProfileInfo(String profileName, String skinUrl) {
    state = state.copyWith(
      showMinecraftFace: true,
      profileName: profileName,
      skinUrl: skinUrl,
    );
  }

  void setLoadingComplete() {
    state = state.copyWith(isLoading: false);
  }

  Future<bool> checkInternetConnection(Function(String) translateFunc) async {
    try {
      setLoadingMessage(translateFunc('loadingPage.checkingConnection'));

      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (e) {
      debugPrint('${translateFunc('loadingPage.noConnection')}: $e');
      return false;
    } catch (e) {
      debugPrint('${translateFunc('loadingPage.connectionError')}: $e');
      return false;
    }
  }

  Future<void> initializeApp(
    Function(String) translateFunc, [
    Function(String, {Map<String, String>? translationParams})?
    translateWithParams,
  ]) async {
    try {
      setLoadingMessage(translateFunc('loadingPage.loadingProfiles'));

      await ref.read(profilesInitializedProvider.future);

      final hasInternet = await checkInternetConnection(translateFunc);

      setLoadingMessage(translateFunc('loadingPage.checkingAuth'));

      final authNotifier = ref.read(authenticationProvider.notifier);

      authNotifier.authEvent = (message) {
        setAuthMessage(message);
      };

      if (!hasInternet) {
        setLoadingMessage(translateFunc('loadingPage.offlineMode'));
        await authNotifier.clearActiveAccount();
      }

      if (hasInternet) {
        await authNotifier.init();
        var profile = await authNotifier.refreshActiveAccount();

        if (profile != null && translateWithParams != null) {
          setProfileInfo(profile.name, profile.skinUrl!);
          setLoadingMessage(
            translateWithParams(
              'loadingPage.loggedInAs',
              translationParams: {'name': profile.name},
            ),
          );
        }

        await Future.delayed(const Duration(seconds: 1));
      }

      setLoadingMessage(translateFunc('loadingPage.applyingSettings'));

      await Future.delayed(const Duration(milliseconds: 500));

      setLoadingComplete();
    } catch (e) {
      setError(
        '${translateFunc('loadingPage.errorOccurred')}: $e',
        translateFunc('loadingPage.initFailed'),
      );
      debugPrint('${translateFunc('loadingPage.initError')}: $e');

      setLoadingComplete();
    }
  }
}

final loadingProvider = StateNotifierProvider<LoadingNotifier, LoadingState>((
  ref,
) {
  return LoadingNotifier(ref);
});
