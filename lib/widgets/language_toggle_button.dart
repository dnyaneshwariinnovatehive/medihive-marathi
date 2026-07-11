import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';

class LanguageToggleButton extends StatelessWidget {
  final bool isCompact;

  const LanguageToggleButton({super.key, this.isCompact = false});

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = localeProvider.locale.languageCode;
    final isEnglish = currentLocale == 'en';

    if (isCompact) {
      return GestureDetector(
        onTap: () => localeProvider.toggleLocale(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.language,
                color: Colors.white.withValues(alpha: 0.9),
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                isEnglish ? 'मर' : 'EN',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return PopupMenuButton<String>(
      onSelected: (code) {
        localeProvider.setLocale(Locale(code));
      },
      icon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.language,
              color: AppTheme.primary,
              size: 20,
            ),
            const SizedBox(width: 6),
            Text(
              isEnglish ? 'EN' : 'मर',
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.arrow_drop_down,
              color: AppTheme.primary,
              size: 18,
            ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'en',
          child: Row(
            children: [
              if (isEnglish)
                Icon(Icons.check, color: AppTheme.primary, size: 18)
              else
                const SizedBox(width: 18),
              const SizedBox(width: 8),
              Text(
                l10n.english,
                style: TextStyle(
                  fontWeight: isEnglish ? FontWeight.bold : FontWeight.normal,
                  color: isEnglish ? AppTheme.primary : AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'mr',
          child: Row(
            children: [
              if (!isEnglish)
                Icon(Icons.check, color: AppTheme.primary, size: 18)
              else
                const SizedBox(width: 18),
              const SizedBox(width: 8),
              Text(
                l10n.marathi,
                style: TextStyle(
                  fontWeight: !isEnglish ? FontWeight.bold : FontWeight.normal,
                  color: !isEnglish ? AppTheme.primary : AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
