import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 対応言語リスト
final supportedLocales = [
  const Locale('ja', ''), // 日本語
  const Locale('en', ''), // 英語
  const Locale('zh', ''), // 中国語
];

// 言語設定用のプロバイダー
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  // デフォルトは日本語
  LocaleNotifier() : super(const Locale('ja', '')) {
    _loadSavedLocale();
  }

  // 保存された言語設定を読み込む
  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguageCode = prefs.getString('languageCode');

    if (savedLanguageCode != null) {
      state = Locale(savedLanguageCode, '');
    }
  }

  // 言語を変更する
  Future<void> changeLocale(Locale newLocale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', newLocale.languageCode);
    state = newLocale;
  }

  // 言語名を取得する（表示用）
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

  // 現在の言語名を取得
  String getCurrentLanguageName() {
    return getLanguageName(state);
  }
}
