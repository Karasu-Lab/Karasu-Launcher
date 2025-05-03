import 'package:flutter/material.dart';

class SignOutDialog extends StatelessWidget {
  const SignOutDialog({super.key, required this.accountName, this.onSignOut});

  final String accountName;

  final VoidCallback? onSignOut;

  static Future<bool> show(
    BuildContext context, {
    required String accountName,
    VoidCallback? onSignOut,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) =>
              SignOutDialog(accountName: accountName, onSignOut: onSignOut),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('サインアウトの確認'),
      content: Text('$accountNameをサインアウトしますか？'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('キャンセル'),
        ),
        TextButton(
          onPressed: () {
            onSignOut?.call();
            Navigator.of(context).pop(true);
          },
          child: const Text('サインアウト', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}
