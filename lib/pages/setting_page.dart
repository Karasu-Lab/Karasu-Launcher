import 'package:flutter/material.dart';
import 'package:karasu_launcher/utils/file_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:karasu_launcher/providers/locale_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:async';

class SettingPage extends ConsumerStatefulWidget {
  const SettingPage({super.key});

  @override
  ConsumerState<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends ConsumerState<SettingPage> {
  bool _isLoading = false;
  String _appDirectoryPath = '';

  @override
  void initState() {
    super.initState();
    _loadAppDirectoryPath();
  }

  Future<void> _loadAppDirectoryPath() async {
    final appDir = await getAppDirectory();
    setState(() {
      _appDirectoryPath = appDir.path;
    });
  }

  Future<bool> _deleteWithRetry(
    FileSystemEntity entity, {
    int maxRetries = 3,
    int delayMs = 500,
  }) async {
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        if (await entity.exists()) {
          await entity.delete(recursive: true);
        }
        return true;
      } catch (e) {
        if (attempt < maxRetries - 1) {
          await Future.delayed(Duration(milliseconds: delayMs * (attempt + 1)));
          continue;
        }
        return false;
      }
    }
    return false;
  }

  Future<List<String>> _safelyDeleteDirectoryContents(
    Directory dir, {
    Set<String> excludeFolders = const {},
  }) async {
    List<String> failedItems = [];

    if (await dir.exists()) {
      final contents = dir.listSync();

      for (var fileOrDir in contents) {
        final path = fileOrDir.path;
        final name = path.split(Platform.pathSeparator).last;

        if (excludeFolders.contains(name)) {
          continue;
        }

        bool success = await _deleteWithRetry(fileOrDir);
        if (!success) {
          failedItems.add(path);
        }
      }
    }

    return failedItems;
  }

  Future<void> _clearSharedPreferences() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              FlutterI18n.translate(
                context,
                'settingsPage.clearAccount.success',
              ),
            ),
            backgroundColor: Colors.green,
          ),
        );

        _reloadApplicationAfterChange();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              FlutterI18n.translate(
                context,
                'settingsPage.clearAccount.error',
                translationParams: {"error": e.toString()},
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearCache() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final cacheDir = await getTemporaryDirectory();
      if (await cacheDir.exists()) {
        final failedItems = await _safelyDeleteDirectoryContents(cacheDir);

        if (failedItems.isNotEmpty) {
          if (mounted) {
            throw Exception(
              FlutterI18n.translate(
                context,
                'settingsPage.errors.filesInUse',
                translationParams: {"count": failedItems.length.toString()},
              ),
            );
          }
        }

        if (!await cacheDir.exists()) {
          await cacheDir.create();
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              FlutterI18n.translate(context, 'settingsPage.clearCache.success'),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              FlutterI18n.translate(
                context,
                'settingsPage.clearCache.error',
                translationParams: {"error": e.toString()},
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearAllData() async {
    setState(() {
      _isLoading = true;
    });

    List<String> failedItems = [];

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      final appDir = await getAppDirectory();
      if (await appDir.exists()) {
        final appDirFailedItems = await _safelyDeleteDirectoryContents(
          appDir,
          excludeFolders: {'saves', 'screenshots'},
        );
        failedItems.addAll(appDirFailedItems);
      }

      if (failedItems.isNotEmpty && mounted) {
        throw Exception(
          FlutterI18n.translate(
            context,
            'settingsPage.errors.filesInUse',
            translationParams: {"count": failedItems.length.toString()},
          ),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              FlutterI18n.translate(
                context,
                'settingsPage.clearAllData.success',
              ),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              FlutterI18n.translate(
                context,
                'settingsPage.clearAllData.error',
                translationParams: {"error": e.toString()},
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }

    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      final snackBar = SnackBar(
        content: Text(
          FlutterI18n.translate(
            context,
            'settingsPage.clearAllData.reloadMessage',
          ),
        ),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
      );

      ScaffoldMessenger.of(context).showSnackBar(snackBar).closed.then((_) {
        _reloadApplicationAfterChange();
      });
    }
  }

  Future<void> _showConfirmationDialog(
    String title,
    String content,
    Function() onConfirm,
  ) async {
    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  FlutterI18n.translate(context, 'settingsPage.buttons.cancel'),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onConfirm();
                },
                child: Text(
                  FlutterI18n.translate(context, 'settingsPage.buttons.delete'),
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(FlutterI18n.translate(context, 'settingsPage.title')),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      FlutterI18n.translate(context, 'settingsPage.general'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.language),
                    title: Text(
                      FlutterI18n.translate(context, 'settingsPage.language'),
                    ),
                    subtitle: Text(
                      ref
                          .read(localeProvider.notifier)
                          .getCurrentLanguageName(),
                    ),
                    onTap: () => _showLanguageSelectionDialog(),
                  ),
                  const Divider(),

                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      FlutterI18n.translate(
                        context,
                        'settingsPage.dataManagement',
                      ),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.folder),
                    title: Text(
                      FlutterI18n.translate(
                        context,
                        'settingsPage.appDirectory.title',
                      ),
                    ),
                    subtitle: Text(_appDirectoryPath),
                    trailing: IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: _appDirectoryPath),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              FlutterI18n.translate(
                                context,
                                'settingsPage.appDirectory.copied',
                              ),
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      tooltip: FlutterI18n.translate(
                        context,
                        'settingsPage.appDirectory.copyTooltip',
                      ),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.delete_outline),
                    title: Text(
                      FlutterI18n.translate(
                        context,
                        'settingsPage.clearAccount.title',
                      ),
                    ),
                    subtitle: Text(
                      FlutterI18n.translate(
                        context,
                        'settingsPage.clearAccount.subtitle',
                      ),
                    ),
                    onTap:
                        () => _showConfirmationDialog(
                          FlutterI18n.translate(
                            context,
                            'settingsPage.clearAccount.confirmTitle',
                          ),
                          FlutterI18n.translate(
                            context,
                            'settingsPage.clearAccount.confirmMessage',
                          ),
                          _clearSharedPreferences,
                        ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.cleaning_services_outlined),
                    title: Text(
                      FlutterI18n.translate(
                        context,
                        'settingsPage.clearCache.title',
                      ),
                    ),
                    subtitle: Text(
                      FlutterI18n.translate(
                        context,
                        'settingsPage.clearCache.subtitle',
                      ),
                    ),
                    onTap:
                        () => _showConfirmationDialog(
                          FlutterI18n.translate(
                            context,
                            'settingsPage.clearCache.confirmTitle',
                          ),
                          FlutterI18n.translate(
                            context,
                            'settingsPage.clearCache.confirmMessage',
                          ),
                          _clearCache,
                        ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(
                      Icons.delete_forever,
                      color: Colors.red,
                    ),
                    title: Text(
                      FlutterI18n.translate(
                        context,
                        'settingsPage.clearAllData.title',
                      ),
                    ),
                    subtitle: Text(
                      FlutterI18n.translate(
                        context,
                        'settingsPage.clearAllData.subtitle',
                      ),
                    ),
                    onTap:
                        () => _showConfirmationDialog(
                          FlutterI18n.translate(
                            context,
                            'settingsPage.clearAllData.confirmTitle',
                          ),
                          FlutterI18n.translate(
                            context,
                            'settingsPage.clearAllData.confirmMessage',
                          ),
                          _clearAllData,
                        ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      FlutterI18n.translate(context, 'settingsPage.others'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.refresh),
                    title: Text(
                      FlutterI18n.translate(
                        context,
                        'settingsPage.restartApp.title',
                      ),
                    ),
                    subtitle: Text(
                      FlutterI18n.translate(
                        context,
                        'settingsPage.restartApp.subtitle',
                      ),
                    ),
                    onTap: () => _showRestartConfirmationDialog(),
                  ),
                ],
              ),
    );
  }

  Future<void> _showRestartConfirmationDialog() async {
    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              FlutterI18n.translate(context, 'settingsPage.restartApp.title'),
            ),
            content: Text(
              FlutterI18n.translate(context, 'settingsPage.restartApp.message'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  FlutterI18n.translate(context, 'settingsPage.buttons.cancel'),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  try {
                    _reloadApplicationAfterChange();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          FlutterI18n.translate(
                            context,
                            'settingsPage.restartApp.success',
                          ),
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          FlutterI18n.translate(
                            context,
                            'settingsPage.restartApp.error',
                            translationParams: {"error": e.toString()},
                          ),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: Text(
                  FlutterI18n.translate(context, 'settingsPage.buttons.ok'),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _showLanguageSelectionDialog() async {
    final mainContext = context;

    return showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(
              FlutterI18n.translate(dialogContext, 'settingsPage.language'),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  supportedLocales.map((locale) {
                    final localeNotifier = ref.read(localeProvider.notifier);
                    final currentLocale = ref.read(localeProvider);
                    final isSelected =
                        locale.languageCode == currentLocale.languageCode;

                    return ListTile(
                      title: Text(localeNotifier.getLanguageName(locale)),
                      trailing:
                          isSelected
                              ? const Icon(Icons.check, color: Colors.green)
                              : null,
                      onTap: () {
                        Navigator.of(dialogContext).pop();
                        if (isSelected) return;
                        _showLanguageChangeConfirmation(
                          mainContext,
                          localeNotifier,
                          locale,
                        );
                      },
                    );
                  }).toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(
                  FlutterI18n.translate(
                    dialogContext,
                    'settingsPage.buttons.cancel',
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _showLanguageChangeConfirmation(
    BuildContext mainContext,
    LocaleNotifier localeNotifier,
    Locale newLocale,
  ) async {
    return showDialog(
      context: mainContext,
      builder:
          (confirmContext) => AlertDialog(
            title: Text(
              FlutterI18n.translate(
                confirmContext,
                'settingsPage.languageConfirm.title',
              ),
            ),
            content: Text(
              FlutterI18n.translate(
                confirmContext,
                'settingsPage.languageConfirm.message',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(confirmContext).pop(),
                child: Text(
                  FlutterI18n.translate(
                    confirmContext,
                    'settingsPage.buttons.cancel',
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(confirmContext).pop();
                  localeNotifier.changeLocale(newLocale);
                  _reloadApplicationAfterChange();
                },
                child: Text(
                  FlutterI18n.translate(
                    confirmContext,
                    'settingsPage.languageConfirm.confirmButton',
                  ),
                ),
              ),
            ],
          ),
    );
  }

  void _reloadApplicationAfterChange() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        GoRouter.of(context).go('/');
      }
    });
  }
}
