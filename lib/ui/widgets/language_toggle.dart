import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../controllers/locale_controller.dart';
import '../../l10n/app_localizations.dart';

/// EN / ES switch. The change is applied instantly and remembered.
class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key, this.compact = true});

  /// `true` shows "EN / ES" (app bar); `false` shows full names (Settings).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final localeController = context.watch<LocaleController>();
    final l = AppLocalizations.of(context);
    return Tooltip(
      message: l.languageToggleTooltip,
      child: SegmentedButton<String>(
        segments: [
          ButtonSegment(
            value: LocaleController.english.languageCode,
            label: Text(compact ? 'EN' : 'English'),
          ),
          ButtonSegment(
            value: LocaleController.spanish.languageCode,
            label: Text(compact ? 'ES' : 'Español'),
          ),
        ],
        selected: {localeController.locale.languageCode},
        showSelectedIcon: false,
        onSelectionChanged: (selection) =>
            localeController.setLocale(Locale(selection.first)),
        style: compact
            ? SegmentedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 6),
              )
            : null,
      ),
    );
  }
}
