import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FeatureInDevelopmentDialog extends ConsumerStatefulWidget {
  final String? title;
  final String? message;
  final String? buttonText;

  const FeatureInDevelopmentDialog({
    super.key,
    this.title,
    this.message,
    this.buttonText,
  });

  static Future<void> show(
    BuildContext context, {
    String? title,
    String? message,
    String? buttonText,
  }) async {
    return showDialog(
      context: context,
      builder:
          (context) => FeatureInDevelopmentDialog(
            title: title,
            message: message,
            buttonText: buttonText,
          ),
    );
  }

  @override
  ConsumerState<FeatureInDevelopmentDialog> createState() =>
      _FeatureInDevelopmentDialogState();
}

class _FeatureInDevelopmentDialogState
    extends ConsumerState<FeatureInDevelopmentDialog> {
  late String localizedTitle;
  late String localizedMessage;
  late String localizedButtonText;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initLocalizedTexts();
    });
  }

  void _initLocalizedTexts() {
    localizedTitle =
        widget.title ??
        FlutterI18n.translate(
          context,
          "featureInDevelopmentDialog.defaultTitle",
        );
    localizedMessage =
        widget.message ??
        FlutterI18n.translate(
          context,
          "featureInDevelopmentDialog.defaultMessage",
        );
    localizedButtonText =
        widget.buttonText ??
        FlutterI18n.translate(
          context,
          "featureInDevelopmentDialog.defaultButtonText",
        );

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(localizedTitle),
      content: Text(localizedMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(localizedButtonText),
        ),
      ],
    );
  }
}
