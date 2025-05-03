import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:karasu_launcher/models/screenshot.dart';
import 'package:karasu_launcher/providers/screenshots_provider.dart';

class ScreenshotCommentDialog extends ConsumerWidget {
  final Screenshot screenshot;

  const ScreenshotCommentDialog({super.key, required this.screenshot});

  static Future<Screenshot?> show(BuildContext context, Screenshot screenshot) {
    return showDialog<Screenshot?>(
      context: context,
      builder: (context) => ScreenshotCommentDialog(screenshot: screenshot),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextEditingController commentController = TextEditingController(
      text: screenshot.comment ?? '',
    );

    return AlertDialog(
      title: const Text('コメントを編集'),
      content: TextField(
        controller: commentController,
        decoration: const InputDecoration(
          hintText: 'スクリーンショットにコメントを追加',
          border: OutlineInputBorder(),
        ),
        maxLines: 5,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        TextButton(
          onPressed: () async {
            try {
              final updatedScreenshot = screenshot.copyWith(
                comment: commentController.text,
              );

              await ref
                  .read(screenshotsCollectionProvider.notifier)
                  .updateScreenshotComment(screenshot.id, updatedScreenshot);

              if (context.mounted) {
                Navigator.of(context).pop(updatedScreenshot);
              }
            } catch (e) {
              if (context.mounted) {
                _showErrorDialog(context, 'コメントの保存中にエラーが発生しました: $e');
              }
            }
          },
          child: const Text('保存'),
        ),
      ],
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('エラー'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('閉じる'),
              ),
            ],
          ),
    );
  }
}
