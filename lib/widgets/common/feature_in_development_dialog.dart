import 'package:flutter/material.dart';

/// 機能開発中ダイアログ
class FeatureInDevelopmentDialog extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;

  const FeatureInDevelopmentDialog({
    super.key,
    this.title = '機能開発中',
    this.message = '共有機能は開発中です。',
    this.buttonText = '閉じる',
  });

  /// ダイアログを表示するための静的メソッド
  static Future<void> show(
    BuildContext context, {
    String title = '機能開発中',
    String message = '共有機能は開発中です。',
    String buttonText = '閉じる',
  }) async {
    return showDialog(
      context: context,
      builder: (context) => FeatureInDevelopmentDialog(
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
