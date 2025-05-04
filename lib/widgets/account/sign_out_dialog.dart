import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

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
      title: Text(FlutterI18n.translate(context, 'accountSignOut.title')),
      content: Text(
        FlutterI18n.translate(
          context,
          'accountSignOut.confirmationMessage',
          translationParams: {"accountName": accountName},
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(FlutterI18n.translate(context, 'accountSignOut.cancel')),
        ),
        TextButton(
          onPressed: () {
            onSignOut?.call();
            Navigator.of(context).pop(true);
          },
          child: Text(
            FlutterI18n.translate(context, 'accountSignOut.signOut'),
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    );
  }
}
