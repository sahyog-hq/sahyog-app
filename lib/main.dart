import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/app.dart';
import 'src/core/language_provider.dart';

final languageProvider = LanguageProvider();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await languageProvider.load();
  runApp(
    ProviderScope(
      child: LanguageScope(
        notifier: languageProvider,
        child: const SahyogApp(),
      ),
    ),
  );
}

