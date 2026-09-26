import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/app.dart';
import 'src/core/language_provider.dart';
import 'src/core/theme_provider.dart';

final languageProvider = LanguageProvider();
final themeProvider = ThemeProvider();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await languageProvider.load();
  await themeProvider.load();
  runApp(
    ProviderScope(
      child: LanguageScope(
        notifier: languageProvider,
        child: ThemeScope(
          notifier: themeProvider,
          child: const SahyogApp(),
        ),
      ),
    ),
  );
}

