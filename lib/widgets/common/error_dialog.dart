import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

/// 共通エラーダイアログ
class ErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;

  const ErrorDialog({
    super.key,
    String? title,
    required this.message,
    String? buttonText,
  }) : title = title ?? '',
       buttonText = buttonText ?? '';

  /// ダイアログを表示するための静的メソッド
  static Future<void> show(
    BuildContext context, {
    String? title,
    required String message,
    String? buttonText,
  }) async {
    return showDialog(
      context: context,
      builder:
          (context) => ErrorDialog(
            title: title,
            message: message,
            buttonText: buttonText,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizedTitle =
        title.isNotEmpty
            ? title
            : FlutterI18n.translate(context, "errorDialog.defaultTitle");

    final localizedButtonText =
        buttonText.isNotEmpty
            ? buttonText
            : FlutterI18n.translate(context, "errorDialog.defaultButtonText");

    return AlertDialog(
      title: Text(localizedTitle),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(localizedButtonText),
        ),
      ],
    );
  }
}
