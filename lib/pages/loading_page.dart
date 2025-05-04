import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:karasu_launcher/providers/profiles_provider.dart';
import 'package:karasu_launcher/providers/authentication_provider.dart';
import 'dart:io';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:karasu_launcher/widgets/minecraft_face.dart';
import 'package:karasu_launcher/widgets/window_buttons.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';

class LoadingPage extends ConsumerStatefulWidget {
  const LoadingPage({super.key});

  @override
  ConsumerState<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends ConsumerState<LoadingPage> {
  final bool _isLoading = true;
  String _loadingMessage = '';
  String? _errorMessage;
  bool _hasError = false;
  bool _showMinecraftFace = false;
  String? _profileName;
  String? _skinUrl;

  final double _iconSize = 150.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _loadingMessage = FlutterI18n.translate(
          context,
          'loadingPage.initializing',
        );
      });
      _initializeApp();
    });
  }

  Future<bool> _checkInternetConnection() async {
    try {
      setState(() {
        _loadingMessage = FlutterI18n.translate(
          context,
          'loadingPage.checkingConnection',
        );
      });

      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (e) {
      if (mounted) {
        debugPrint(
          '${FlutterI18n.translate(context, 'loadingPage.noConnection')}: $e',
        );
      }
      return false;
    } catch (e) {
      if (mounted) {
        debugPrint(
          '${FlutterI18n.translate(context, 'loadingPage.connectionError')}: $e',
        );
      }
      return false;
    }
  }

  Future<void> _initializeApp() async {
    try {
      setState(() {
        _loadingMessage = FlutterI18n.translate(
          context,
          'loadingPage.loadingProfiles',
        );
      });

      await ref.read(profilesInitializedProvider.future);

      final hasInternet = await _checkInternetConnection();

      setState(() {
        _loadingMessage = FlutterI18n.translate(
          context,
          'loadingPage.checkingAuth',
        );
      });

      final authNotifier = ref.read(authenticationProvider.notifier);

      if (!hasInternet) {
        setState(() {
          _loadingMessage = FlutterI18n.translate(
            context,
            'loadingPage.offlineMode',
          );
        });

        await authNotifier.clearActiveAccount();
      }

      if (hasInternet) {
        await authNotifier.init();
        var profile = await authNotifier.refreshActiveAccount();

        if (profile != null) {
          setState(() {
            _showMinecraftFace = true;
            _profileName = profile.name;
            _skinUrl = profile.skinUrl;
            _loadingMessage = FlutterI18n.translate(
              context,
              'loadingPage.loggedInAs',
              translationParams: {'name': profile.name},
            );
          });
        }

        await Future.delayed(const Duration(seconds: 1));
      }

      setState(() {
        _loadingMessage = FlutterI18n.translate(
          context,
          'loadingPage.applyingSettings',
        );
      });

      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage =
            '${FlutterI18n.translate(context, 'loadingPage.errorOccurred')}: $e';
        _loadingMessage = FlutterI18n.translate(
          context,
          'loadingPage.initFailed',
        );
      });
      if (mounted) {
        debugPrint(
          '${FlutterI18n.translate(context, 'loadingPage.initError')}: $e',
        );
      }
      await Future.delayed(const Duration(seconds: 2));
    }

    if (!mounted) return;

    if (!_hasError) {
      context.go('/minecraft');
    } else {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      context.go('/minecraft');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          WindowTitleBarBox(
            child: Container(
              color: Colors.transparent,
              child: Row(
                children: [
                  Expanded(child: MoveWindow()),
                  const WindowButtons(),
                ],
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _showMinecraftFace && _skinUrl != null
                      ? SizedBox(
                        width: _iconSize / 1.5,
                        height: _iconSize / 1.5,
                        child: MinecraftFace.network(
                          _skinUrl!,
                          size: _iconSize / 1.5,
                          showOverlay: true,
                        ),
                      )
                      : Image.asset(
                        'assets/images/logo.png',
                        width: _iconSize,
                        errorBuilder:
                            (context, error, stackTrace) => Icon(
                              Icons.launch,
                              size: _iconSize * 0.53,
                              color: Colors.white,
                            ),
                      ),
                  const SizedBox(height: 24),
                  Text(
                    _showMinecraftFace && _profileName != null
                        ? _profileName!
                        : 'Karasu Launcher',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 48),
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 24),
                  Text(
                    _loadingMessage,
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Consumer(
                    builder: (context, ref, child) {
                      final isLoading = ref.watch(profilesLoadingProvider);
                      return Visibility(
                        visible: isLoading,
                        child: Text(
                          FlutterI18n.translate(
                            context,
                            'loadingPage.fetchingProfiles',
                          ),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white60,
                          ),
                        ),
                      );
                    },
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: TextStyle(fontSize: 14, color: Colors.red[300]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
