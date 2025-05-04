import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import '../../providers/authentication_provider.dart';
import '../../models/auth/device_code_response.dart';

class AccountSignInPage extends ConsumerStatefulWidget {
  const AccountSignInPage({super.key});

  @override
  ConsumerState<AccountSignInPage> createState() => _AccountSignInPageState();
}

class _AccountSignInPageState extends ConsumerState<AccountSignInPage> {
  bool _isLoading = false;
  String? _verificationUrl;
  String? _userCode;
  bool _isAuthenticating = false;
  String? _errorMessage;

  Future<void> _startAuthentication() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authNotifier = ref.read(authenticationProvider.notifier);
      DeviceCodeResponse deviceCode = await authNotifier.startAuthFlow();

      setState(() {
        _verificationUrl = deviceCode.verificationUri;
        _userCode = deviceCode.userCode;
        _isLoading = false;
        _isAuthenticating = true;
      });

      // バックグラウンドでポーリングを開始
      authNotifier
          .completeAuthFlow(deviceCode.deviceCode)
          .then((_) {
            // 認証完了後、アカウントホームページに戻る
            if (mounted) {
              context.go('/accounts');
            }
          })
          .catchError((error) {
            setState(() {
              _isAuthenticating = false;
              _errorMessage = FlutterI18n.translate(
                context,
                'accountSignIn.authFailed',
                translationParams: {"error": error.toString()},
              );
            });
          });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = FlutterI18n.translate(
          context,
          'accountSignIn.startAuthFailed',
          translationParams: {"error": e.toString()},
        );
      });
    }
  }

  Future<void> _launchVerificationUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  Future<void> _copyCodeToClipboard() async {
    if (_userCode != null) {
      await Clipboard.setData(ClipboardData(text: _userCode!));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              FlutterI18n.translate(context, 'accountSignIn.codeCopied'),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(FlutterI18n.translate(context, 'accountSignIn.title')),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                FlutterI18n.translate(context, 'accountSignIn.microsoftSignIn'),
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 20),

              if (_isLoading)
                const CircularProgressIndicator()
              else if (_userCode != null && _verificationUrl != null)
                Column(
                  children: [
                    Text(
                      FlutterI18n.translate(context, 'accountSignIn.enterCode'),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _userCode!,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy),
                            onPressed: _copyCodeToClipboard,
                            tooltip: FlutterI18n.translate(
                              context,
                              'accountSignIn.copyCode',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.open_in_browser),
                      label: Text(
                        FlutterI18n.translate(
                          context,
                          'accountSignIn.openAuthPage',
                        ),
                      ),
                      onPressed:
                          () => _launchVerificationUrl(_verificationUrl!),
                    ),
                    const SizedBox(height: 16),
                    if (_isAuthenticating)
                      Column(
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 8),
                          Text(
                            FlutterI18n.translate(
                              context,
                              'accountSignIn.authenticating',
                            ),
                          ),
                        ],
                      ),
                  ],
                )
              else
                Column(
                  children: [
                    Text(
                      FlutterI18n.translate(
                        context,
                        'accountSignIn.useAccount',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _startAuthentication,
                      child: Text(
                        FlutterI18n.translate(
                          context,
                          'accountSignIn.startSignIn',
                        ),
                      ),
                    ),
                  ],
                ),

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (_errorMessage != null)
                TextButton.icon(
                  icon: const Icon(Icons.copy),
                  label: Text(
                    FlutterI18n.translate(context, 'accountSignIn.copyError'),
                  ),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _errorMessage!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          FlutterI18n.translate(
                            context,
                            'accountSignIn.errorCopied',
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
