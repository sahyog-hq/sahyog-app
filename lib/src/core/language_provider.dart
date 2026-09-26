import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const _prefsKey = 'app_locale';

  static const supportedLocales = [
    Locale('en'),
    Locale('hi'),
    Locale('mr'),
  ];

  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  bool isSupported(Locale locale) {
    return supportedLocales.any((item) => item.languageCode == locale.languageCode);
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    if (code == null) return;
    final next = Locale(code);
    if (!isSupported(next) || next == _locale) return;
    _locale = next;
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    if (!isSupported(locale) || locale == _locale) return;
    _locale = Locale(locale.languageCode);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, _locale.languageCode);
  }
}

class LanguageScope extends InheritedNotifier<LanguageProvider> {
  const LanguageScope({
    super.key,
    required LanguageProvider super.notifier,
    required super.child,
  });

  static LanguageProvider of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LanguageScope>();
    assert(scope != null && scope.notifier != null, 'LanguageScope missing');
    return scope!.notifier!;
  }
}
