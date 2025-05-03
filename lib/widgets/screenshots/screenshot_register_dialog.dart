import 'package:flutter/material.dart';

/// スクリーンショットがコレクションに登録されていない場合のダイアログ
class ScreenshotRegisterDialog extends StatelessWidget {
  const ScreenshotRegisterDialog({super.key});

  /// ダイアログを表示するための静的メソッド
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const ScreenshotRegisterDialog(),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('コメントの追加'),
      content: const Text(
        'このスクリーンショットはまだコレクションに登録されていません。'
        'コメントを追加すると自動的にコレクションに登録されます。',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('キャンセル'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('続ける'),
        ),
      ],
    );
  }
}
