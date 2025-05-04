import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
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
      title: Text(
        FlutterI18n.translate(context, "screenshotCommentDialog.title"),
      ),
      content: TextField(
        controller: commentController,
        decoration: InputDecoration(
          hintText: FlutterI18n.translate(
            context,
            "screenshotCommentDialog.hintText",
          ),
          border: const OutlineInputBorder(),
        ),
        maxLines: 5,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            FlutterI18n.translate(context, "screenshotCommentDialog.cancel"),
          ),
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
                _showErrorDialog(
                  context,
                  FlutterI18n.translate(
                    context,
                    "screenshotCommentDialog.error.saveFailed",
                    translationParams: {"error": e.toString()},
                  ),
                );
              }
            }
          },
          child: Text(
            FlutterI18n.translate(context, "screenshotCommentDialog.save"),
          ),
        ),
      ],
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              FlutterI18n.translate(
                context,
                "screenshotCommentDialog.error.title",
              ),
            ),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  FlutterI18n.translate(
                    context,
                    "screenshotCommentDialog.error.close",
                  ),
                ),
              ),
            ],
          ),
    );
  }
}
