import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:karasu_launcher/providers/profiles_provider.dart';
import 'package:karasu_launcher/providers/loading_provider.dart';
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
  final double _iconSize = 150.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  String _translate(String key) {
    return FlutterI18n.translate(context, key);
  }

  String _translateWithParams(
    String key, {
    Map<String, String>? translationParams,
  }) {
    return FlutterI18n.translate(
      context,
      key,
      translationParams: translationParams,
    );
  }

  Future<void> _initializeApp() async {
    final loadingNotifier = ref.read(loadingProvider.notifier);

    loadingNotifier.setLoadingMessage(_translate('loadingPage.initializing'));

    await loadingNotifier.initializeApp(_translate, _translateWithParams);

    final loadingState = ref.read(loadingProvider);

    if (!mounted) return;

    if (!loadingState.hasError) {
      context.go('/minecraft');
    } else {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      context.go('/minecraft');
    }
  }

  @override
  Widget build(BuildContext context) {
    final loadingState = ref.watch(loadingProvider);

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
                  SizedBox(
                    width: _iconSize,
                    height: _iconSize,
                    child: Center(
                      child:
                          loadingState.showMinecraftFace &&
                                  loadingState.skinUrl != null
                              ? MinecraftFace.network(
                                loadingState.skinUrl!,
                                size: _iconSize / 1.5,
                                showOverlay: true,
                              )
                              : Image.asset(
                                'assets/images/logo.png',
                                width: _iconSize,
                                errorBuilder:
                                    (context, error, stackTrace) => Icon(
                                      BoxIcons.bx_run,
                                      size: _iconSize * 0.53,
                                      color: Colors.white,
                                    ),
                              ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    loadingState.showMinecraftFace &&
                            loadingState.profileName != null
                        ? loadingState.profileName!
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
                    loadingState.loadingMessage,
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  if (loadingState.authMessages.isNotEmpty) ...[
                    Container(
                      constraints: const BoxConstraints(
                        maxWidth: 400,
                        maxHeight: 100,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Container(
                        height: 80,
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            final messagesCount =
                                loadingState.authMessages.length;

                            final displayCount =
                                messagesCount > 5 ? 5 : messagesCount;

                            if (index >= displayCount) {
                              return const SizedBox.shrink();
                            }

                            final messageIndex =
                                messagesCount - displayCount + index;

                            return Container(
                              height: 16,
                              alignment: Alignment.center,
                              child: Text(
                                FlutterI18n.translate(
                                  context,
                                  loadingState
                                      .authMessages[messageIndex]
                                      .type
                                      .key,
                                ),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white60,
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

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
                  if (loadingState.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      loadingState.errorMessage!,
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
