import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:karasu_launcher/utils/file_utils.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:go_router/go_router.dart';

class DataManagementPage extends ConsumerStatefulWidget {
  const DataManagementPage({super.key});

  @override
  ConsumerState<DataManagementPage> createState() => _DataManagementPageState();
}

class _DataManagementPageState extends ConsumerState<DataManagementPage> {
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            FlutterI18n.translate(context, 'settingsPage.dataManagement'),
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
            FlutterI18n.translate(context, 'settingsPage.appDirectory.title'),
          ),
          subtitle: Text(_appDirectoryPath),
          trailing: IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _appDirectoryPath));
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
            FlutterI18n.translate(context, 'settingsPage.clearAccount.title'),
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
            FlutterI18n.translate(context, 'settingsPage.clearCache.title'),
          ),
          subtitle: Text(
            FlutterI18n.translate(context, 'settingsPage.clearCache.subtitle'),
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
          leading: const Icon(Icons.delete_forever, color: Colors.red),
          title: Text(
            FlutterI18n.translate(context, 'settingsPage.clearAllData.title'),
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
        const Divider(),
      ],
    );
  }

  void _reloadApplicationAfterChange() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        context.go('/');
      }
    });
  }
}
