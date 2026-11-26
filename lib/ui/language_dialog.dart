import 'package:flutter/material.dart';
import '../core/localization.dart';
import '../core/theme_manager.dart';

class LanguageInfo {
  final Locale locale;
  final String flag;
  final String nativeName;
  final String englishName;

  const LanguageInfo({
    required this.locale,
    required this.flag,
    required this.nativeName,
    required this.englishName,
  });
}

const List<LanguageInfo> kSupportedLanguages = [
  LanguageInfo(
    locale: Locale('ko'),
    flag: '🇰🇷',
    nativeName: '한국어',
    englishName: 'Korean',
  ),
  LanguageInfo(
    locale: Locale('en'),
    flag: '🇺🇸',
    nativeName: 'English',
    englishName: 'English',
  ),
  LanguageInfo(
    locale: Locale('ja'),
    flag: '🇯🇵',
    nativeName: '日本語',
    englishName: 'Japanese',
  ),
  LanguageInfo(
    locale: Locale('es'),
    flag: '🇪🇸',
    nativeName: 'Español',
    englishName: 'Spanish',
  ),
  LanguageInfo(
    locale: Locale('pt'),
    flag: '🇧🇷',
    nativeName: 'Português',
    englishName: 'Portuguese',
  ),
  LanguageInfo(
    locale: Locale('de'),
    flag: '🇩🇪',
    nativeName: 'Deutsch',
    englishName: 'German',
  ),
  LanguageInfo(
    locale: Locale('fr'),
    flag: '🇫🇷',
    nativeName: 'Français',
    englishName: 'French',
  ),
  LanguageInfo(
    locale: Locale('zh', 'TW'),
    flag: '🇹🇼',
    nativeName: '繁體中文',
    englishName: 'Traditional Chinese',
  ),
  LanguageInfo(
    locale: Locale('zh', 'CN'),
    flag: '🇨🇳',
    nativeName: '简体中文',
    englishName: 'Simplified Chinese',
  ),
  LanguageInfo(
    locale: Locale('ru'),
    flag: '🇷🇺',
    nativeName: 'Русский',
    englishName: 'Russian',
  ),
  LanguageInfo(
    locale: Locale('it'),
    flag: '🇮🇹',
    nativeName: 'Italiano',
    englishName: 'Italian',
  ),
  LanguageInfo(
    locale: Locale('vi'),
    flag: '🇻🇳',
    nativeName: 'Tiếng Việt',
    englishName: 'Vietnamese',
  ),
];

class LanguageDialog extends StatelessWidget {
  final AppTheme theme;
  final Locale currentLocale;
  final ValueChanged<Locale> onSelectLocale;

  const LanguageDialog({
    super.key,
    required this.theme,
    required this.currentLocale,
    required this.onSelectLocale,
  });

  bool _isSelected(Locale target) {
    if (target.languageCode != currentLocale.languageCode) return false;
    if (target.countryCode != null &&
        target.countryCode != currentLocale.countryCode) {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations(currentLocale);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: theme.cardBackground,
          borderRadius: BorderRadius.circular(24.0),
          border: Border.all(
            color: theme.tileUnrevealedBorder,
            width: 1.0,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.language_rounded,
                      color: theme.iconActive,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      loc.t('language_select_title'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: theme.textPrimary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  color: theme.textSecondary,
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Languages Grid
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (int i = 0; i < kSupportedLanguages.length; i += 2)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildLangCard(
                                context,
                                kSupportedLanguages[i],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: i + 1 < kSupportedLanguages.length
                                  ? _buildLangCard(
                                      context,
                                      kSupportedLanguages[i + 1],
                                    )
                                  : const SizedBox(),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLangCard(BuildContext context, LanguageInfo item) {
    final selected = _isSelected(item.locale);

    return InkWell(
      onTap: () {
        onSelectLocale(item.locale);
        Navigator.of(context).pop();
      },
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? (theme.isDark
                  ? const Color(0xFF27272A)
                  : const Color(0xFFE2E8F0))
              : (theme.isDark
                  ? const Color(0xFF18181D)
                  : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? theme.iconActive
                : theme.tileUnrevealedBorder.withOpacity(0.5),
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Text(
              item.flag,
              style: const TextStyle(fontSize: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.nativeName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          selected ? FontWeight.w900 : FontWeight.w600,
                      color: selected
                          ? theme.textPrimary
                          : theme.textPrimary.withOpacity(0.85),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    item.englishName,
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(
                Icons.check_circle_rounded,
                color: theme.iconActive,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}
