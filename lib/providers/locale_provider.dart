import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final supportedLocales = [
  const Locale('ja', ''),
  const Locale('en', ''),
  const Locale('zh', ''),
];

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('ja', '')) {
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguageCode = prefs.getString('languageCode');

    if (savedLanguageCode != null) {
      state = Locale(savedLanguageCode, '');
    }
  }

  Future<void> changeLocale(Locale newLocale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', newLocale.languageCode);
    state = newLocale;
  }

  String getLanguageName(Locale locale) {
    switch (locale.languageCode) {
      case 'ja':
        return '日本語';
      case 'en':
        return 'English';
      case 'zh':
        return '中文';
      default:
        return '日本語';
    }
  }

  String getCurrentLanguageName() {
    return getLanguageName(state);
  }
}
