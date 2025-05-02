import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

class SettingPage extends ConsumerStatefulWidget {
  const SettingPage({super.key});

  @override
  ConsumerState<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends ConsumerState<SettingPage> {
  bool _isLoading = false;

  Future<void> _clearSharedPreferences() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('アカウント情報を削除しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: $e'),
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
        await cacheDir.delete(recursive: true);
        await cacheDir.create();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('キャッシュを削除しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: $e'),
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

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      final cacheDir = await getTemporaryDirectory();
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        await cacheDir.create();
      }

      final appDir = await getApplicationDocumentsDirectory();
      if (await appDir.exists()) {
        final contents = appDir.listSync();
        for (var fileOrDir in contents) {
          await fileOrDir.delete(recursive: true);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('すべてのデータを削除しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: $e'),
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
                child: const Text('キャンセル'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onConfirm();
                },
                child: const Text('削除', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      '一般',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  const Divider(),

                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'データ管理',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.delete_outline),
                    title: const Text('アカウント情報を削除'),
                    subtitle: const Text('保存されているアカウント情報を削除します'),
                    onTap:
                        () => _showConfirmationDialog(
                          'アカウント情報の削除',
                          'すべてのアカウント情報が削除されます。この操作は元に戻せません。続行しますか？',
                          _clearSharedPreferences,
                        ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.cleaning_services_outlined),
                    title: const Text('キャッシュを削除'),
                    subtitle: const Text('一時的なキャッシュデータを削除します'),
                    onTap:
                        () => _showConfirmationDialog(
                          'キャッシュの削除',
                          'キャッシュデータを削除します。アプリの動作が遅い場合に実行してください。',
                          _clearCache,
                        ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(
                      Icons.delete_forever,
                      color: Colors.red,
                    ),
                    title: const Text('すべてのデータを削除'),
                    subtitle: const Text('アプリのすべてのデータを削除し初期状態に戻します'),
                    onTap:
                        () => _showConfirmationDialog(
                          'すべてのデータの削除',
                          'アプリのすべてのデータが削除され、初期状態に戻ります。この操作は元に戻せません。本当に続行しますか？',
                          _clearAllData,
                        ),
                  ),
                ],
              ),
    );
  }
}
