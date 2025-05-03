import 'package:flutter/material.dart';

/// 共通エラーダイアログ
class ErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;

  const ErrorDialog({
    super.key,
    this.title = 'エラー',
    required this.message,
    this.buttonText = '閉じる',
  });

  /// ダイアログを表示するための静的メソッド
  static Future<void> show(
    BuildContext context, {
    String title = 'エラー',
    required String message,
    String buttonText = '閉じる',
  }) async {
    return showDialog(
      context: context,
      builder: (context) => ErrorDialog(
        title: title,
        message: message,
        buttonText: buttonText,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(buttonText),
        ),
      ],
    );
  }
}
