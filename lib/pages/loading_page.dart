import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:karasu_launcher/providers/profiles_provider.dart';
import 'package:karasu_launcher/providers/authentication_provider.dart';
import 'dart:io';

class LoadingPage extends ConsumerStatefulWidget {
  const LoadingPage({super.key});

  @override
  ConsumerState<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends ConsumerState<LoadingPage> {
  final bool _isLoading = true;
  String _loadingMessage = '初期化中...';
  String? _errorMessage;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  // インターネット接続をチェックするメソッド
  Future<bool> _checkInternetConnection() async {
    try {
      setState(() {
        _loadingMessage = 'インターネット接続を確認しています...';
      });

      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (e) {
      debugPrint('インターネット接続がありません: $e');
      return false;
    } catch (e) {
      debugPrint('接続確認中にエラーが発生しました: $e');
      return false;
    }
  }

  Future<void> _initializeApp() async {
    try {
      setState(() {
        _loadingMessage = 'プロファイル情報を読み込んでいます...';
      });

      await ref.read(profilesInitializedProvider.future);

      // インターネット接続チェック
      final hasInternet = await _checkInternetConnection();

      // 認証状態を確認
      setState(() {
        _loadingMessage = '認証状態を確認しています...';
      });

      final authState = ref.read(authenticationProvider);
      final authNotifier = ref.read(authenticationProvider.notifier);

      // インターネット接続がない場合
      if (!hasInternet) {
        setState(() {
          _loadingMessage = 'インターネット接続がありません。オフラインモードで続行します...';
        });

        // オフラインモードに設定
        await authNotifier.clearActiveAccount();
      }

      if (hasInternet) {
        if (authState.activeAccount != null) {
          setState(() {
            _loadingMessage =
                '${authState.activeAccount?.profile?.name ?? "Unknown"}さんとしてログインしています...';
          });

          try {
            // アクティブアカウントでログインを試みる
            final account = await authNotifier.loginWithActiveAccount();

            if (account != null) {
              setState(() {
                _loadingMessage = '${account.profile?.name}さんとしてログインしました';
              });
              await Future.delayed(const Duration(seconds: 1));
            } else {
              // 自動リフレッシュに失敗した場合でも明示的にトークン更新を試みる
              final profile = await authNotifier.refreshActiveAccount();
              if (profile != null) {
                setState(() {
                  _loadingMessage = '${profile.name}さんとしてログインしました（トークン更新済み）';
                });
                await Future.delayed(const Duration(seconds: 1));
              } else {
                setState(() {
                  _loadingMessage = 'アカウントの認証に失敗しました';
                });
                await Future.delayed(const Duration(milliseconds: 800));
              }
            }
          } catch (e) {
            debugPrint('アクティブアカウントログインエラー: $e');
          }
        }
        // アカウントがない場合はサイレントログインを試みる
        else if (authState.accounts.isEmpty) {
          setState(() {
            _loadingMessage = 'サイレントログインを試みています...';
          });

          try {
            final account = await authNotifier.silentLogin();

            if (account != null) {
              setState(() {
                _loadingMessage = '${account.profile?.name}さんとして自動ログインしました';
              });
              await Future.delayed(const Duration(seconds: 1));
            } else {
              await Future.delayed(const Duration(milliseconds: 500));
            }
          } catch (e) {
            debugPrint('サイレントログインエラー: $e');
          }
        }
      }

      setState(() {
        _loadingMessage = '設定を適用しています...';
      });

      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'エラーが発生しました: $e';
        _loadingMessage = 'アプリケーションの初期化に失敗しました';
      });
      debugPrint('初期化エラー: $e');
      await Future.delayed(const Duration(seconds: 2));
    }

    if (mounted && !_hasError) {
      context.go('/minecraft');
    } else if (mounted) {
      // エラーが発生した場合でも最終的にはメイン画面に移動
      await Future.delayed(const Duration(seconds: 1));
      context.go('/minecraft');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 150,
              errorBuilder:
                  (context, error, stackTrace) =>
                      const Icon(Icons.launch, size: 80, color: Colors.white),
            ),
            const SizedBox(height: 24),
            const Text(
              'Karasu Launcher',
              style: TextStyle(
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
                  child: const Text(
                    'プロファイル情報を取得中...',
                    style: TextStyle(fontSize: 12, color: Colors.white60),
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
    );
  }
}
