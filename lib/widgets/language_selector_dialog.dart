import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:karasu_launcher/providers/locale_provider.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

class LanguageSelectorDialog extends ConsumerWidget {
  const LanguageSelectorDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeNotifier = ref.watch(localeProvider.notifier);
    final currentLocale = ref.watch(localeProvider);

    return AlertDialog(
      title: Text(
        FlutterI18n.translate(context, 'settingPage.language.dialogTitle'),
      ),
      content: SizedBox(
        width: double.minPositive,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: supportedLocales.length,
          itemBuilder: (context, index) {
            final locale = supportedLocales[index];
            final isSelected =
                locale.languageCode == currentLocale.languageCode;

            return ListTile(
              title: Text(localeNotifier.getLanguageName(locale)),
              leading: Radio<String>(
                value: locale.languageCode,
                groupValue: currentLocale.languageCode,
                onChanged: (value) {
                  if (value != null) {
                    localeNotifier.changeLocale(Locale(value, ''));
                    Navigator.of(context).pop();
                  }
                },
              ),
              onTap: () {
                localeNotifier.changeLocale(locale);
                Navigator.of(context).pop();
              },
              selected: isSelected,
              selectedTileColor: Colors.blue.withAlpha((0.1 * 255).toInt()),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            FlutterI18n.translate(context, 'settingPage.language.cancel'),
          ),
        ),
      ],
    );
  }
}
