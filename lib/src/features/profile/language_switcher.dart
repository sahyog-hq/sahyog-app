import 'package:flutter/material.dart';

import '../../core/language_provider.dart';
import 'package:sahyog_app/l10n/app_localizations.dart';
import '../../theme/app_colors.dart';

class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final language = LanguageScope.of(context);
    final l10n = AppLocalizations.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.translate_rounded,
                color: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.language,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.languageSubtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            DropdownButtonHideUnderline(
              child: DropdownButton<Locale>(
                value: language.locale,
                borderRadius: BorderRadius.circular(12),
                onChanged: (locale) {
                  if (locale != null) language.setLocale(locale);
                },
                items: [
                  DropdownMenuItem(
                    value: const Locale('en'),
                    child: Text(l10n.english),
                  ),
                  DropdownMenuItem(
                    value: const Locale('hi'),
                    child: Text(l10n.hindi),
                  ),
                  DropdownMenuItem(
                    value: const Locale('mr'),
                    child: Text(l10n.marathi),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
