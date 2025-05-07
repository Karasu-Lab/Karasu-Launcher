import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:karasu_launcher/providers/locale_provider.dart';
import 'package:go_router/go_router.dart';

class GeneralSettingsPage extends ConsumerStatefulWidget {
  const GeneralSettingsPage({super.key});

  @override
  ConsumerState<GeneralSettingsPage> createState() =>
      _GeneralSettingsPageState();
}

class _GeneralSettingsPageState extends ConsumerState<GeneralSettingsPage> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            FlutterI18n.translate(context, 'settingsPage.general'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.language),
          title: Text(FlutterI18n.translate(context, 'settingsPage.language')),
          subtitle: Text(
            ref.read(localeProvider.notifier).getCurrentLanguageName(),
          ),
          onTap: () => _showLanguageSelectionDialog(),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            FlutterI18n.translate(context, 'settingsPage.others'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.refresh),
          title: Text(
            FlutterI18n.translate(context, 'settingsPage.restartApp.title'),
          ),
          subtitle: Text(
            FlutterI18n.translate(context, 'settingsPage.restartApp.subtitle'),
          ),
          onTap: () => _showRestartConfirmationDialog(),
        ),
      ],
    );
  }

  Future<void> _showRestartConfirmationDialog() async {
    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              FlutterI18n.translate(context, 'settingsPage.restartApp.title'),
            ),
            content: Text(
              FlutterI18n.translate(context, 'settingsPage.restartApp.message'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  FlutterI18n.translate(context, 'settingsPage.buttons.cancel'),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  try {
                    _reloadApplicationAfterChange();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          FlutterI18n.translate(
                            context,
                            'settingsPage.restartApp.success',
                          ),
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          FlutterI18n.translate(
                            context,
                            'settingsPage.restartApp.error',
                            translationParams: {"error": e.toString()},
                          ),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: Text(
                  FlutterI18n.translate(context, 'settingsPage.buttons.ok'),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _showLanguageSelectionDialog() async {
    final mainContext = context;

    return showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(
              FlutterI18n.translate(dialogContext, 'settingsPage.language'),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  supportedLocales.map((locale) {
                    final localeNotifier = ref.read(localeProvider.notifier);
                    final currentLocale = ref.read(localeProvider);
                    final isSelected =
                        locale.languageCode == currentLocale.languageCode;

                    return ListTile(
                      title: Text(localeNotifier.getLanguageName(locale)),
                      trailing:
                          isSelected
                              ? const Icon(Icons.check, color: Colors.green)
                              : null,
                      onTap: () {
                        Navigator.of(dialogContext).pop();
                        if (isSelected) return;
                        _showLanguageChangeConfirmation(
                          mainContext,
                          localeNotifier,
                          locale,
                        );
                      },
                    );
                  }).toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(
                  FlutterI18n.translate(
                    dialogContext,
                    'settingsPage.buttons.cancel',
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _showLanguageChangeConfirmation(
    BuildContext mainContext,
    LocaleNotifier localeNotifier,
    Locale newLocale,
  ) async {
    return showDialog(
      context: mainContext,
      builder:
          (confirmContext) => AlertDialog(
            title: Text(
              FlutterI18n.translate(
                confirmContext,
                'settingsPage.languageConfirm.title',
              ),
            ),
            content: Text(
              FlutterI18n.translate(
                confirmContext,
                'settingsPage.languageConfirm.message',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(confirmContext).pop(),
                child: Text(
                  FlutterI18n.translate(
                    confirmContext,
                    'settingsPage.buttons.cancel',
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(confirmContext).pop();
                  localeNotifier.changeLocale(newLocale);
                  _reloadApplicationAfterChange();
                },
                child: Text(
                  FlutterI18n.translate(
                    confirmContext,
                    'settingsPage.languageConfirm.confirmButton',
                  ),
                ),
              ),
            ],
          ),
    );
  }

  void _reloadApplicationAfterChange() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        context.go('/');
      }
    });
  }
}
