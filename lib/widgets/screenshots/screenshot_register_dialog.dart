import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

class ScreenshotRegisterDialog extends StatelessWidget {
  const ScreenshotRegisterDialog({super.key});

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
      title: Text(
        FlutterI18n.translate(context, "screenshotRegisterDialog.title"),
      ),
      content: Text(
        FlutterI18n.translate(context, "screenshotRegisterDialog.message"),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            FlutterI18n.translate(context, "screenshotRegisterDialog.cancel"),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            FlutterI18n.translate(context, "screenshotRegisterDialog.continue"),
          ),
        ),
      ],
    );
  }
}
