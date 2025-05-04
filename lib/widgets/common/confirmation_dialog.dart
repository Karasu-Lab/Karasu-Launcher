import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

/// 確認ダイアログの共通コンポーネント
class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String content;
  final String? cancelText;
  final String? confirmText;
  final Color? confirmColor;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.content,
    this.cancelText,
    this.confirmText,
    this.confirmColor,
  });

  /// ダイアログを表示するための静的メソッド
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String content,
    String? cancelText,
    String? confirmText,
    Color? confirmColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => ConfirmationDialog(
            title: title,
            content: content,
            cancelText: cancelText,
            confirmText: confirmText,
            confirmColor: confirmColor,
          ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final localizedCancelText =
        cancelText ??
        FlutterI18n.translate(context, "confirmationDialog.defaultCancel");
    final localizedConfirmText =
        confirmText ??
        FlutterI18n.translate(context, "confirmationDialog.defaultConfirm");

    return AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(localizedCancelText),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style:
              confirmColor != null
                  ? TextButton.styleFrom(foregroundColor: confirmColor)
                  : null,
          child: Text(localizedConfirmText),
        ),
      ],
    );
  }
}
