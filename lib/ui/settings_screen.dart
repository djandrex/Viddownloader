import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../controllers/engine_controller.dart';
import '../core/download_state.dart';
import '../l10n/app_localizations.dart';
import 'widgets/language_toggle.dart';

/// Minimal settings: language, download engine, Instagram session and about.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final engine = context.watch<EngineController>();
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Scaffold(
      appBar: AppBar(title: Text(l.settingsTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _SectionTitle(l.settingsLanguage),
            const Align(
              alignment: Alignment.centerLeft,
              child: LanguageToggle(compact: false),
            ),
            const SizedBox(height: 28),
            _SectionTitle(l.settingsEngineSection),
            Text(
              l.settingsEngineVersion(
                engine.engineVersion ?? l.settingsLoading,
              ),
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonalIcon(
                onPressed: engine.updating ? null : () => _update(context),
                icon: engine.updating
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.system_update_alt),
                label: Text(l.settingsUpdateEngine),
              ),
            ),
            const SizedBox(height: 28),
            _SectionTitle(l.settingsSessionSection),
            Text(
              engine.loggedIn
                  ? l.settingsSessionLoggedIn
                  : l.settingsSessionLoggedOut,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 4),
            Text(l.settingsSessionTip, style: muted),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: engine.loggedIn
                  ? OutlinedButton.icon(
                      onPressed: () => _logout(context),
                      icon: const Icon(Icons.logout),
                      label: Text(l.logoutButton),
                    )
                  : OutlinedButton.icon(
                      onPressed: () => _login(context),
                      icon: const Icon(Icons.login),
                      label: Text(l.loginButton),
                    ),
            ),
            const SizedBox(height: 28),
            _SectionTitle(l.settingsAboutSection),
            Text(
              l.settingsAppVersion(engine.appVersion),
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 4),
            Text(l.settingsLegalNote, style: muted),
          ],
        ),
      ),
    );
  }

  Future<void> _update(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final engine = context.read<EngineController>();
    final result = await engine.update();
    final message = switch (result) {
      EngineUpdateResult.updated => l.settingsEngineUpdated(
        engine.engineVersion ?? '',
      ),
      EngineUpdateResult.alreadyUpToDate => l.settingsEngineUpToDate,
      EngineUpdateResult.busy => l.settingsEngineBusy,
      EngineUpdateResult.failed => l.settingsEngineUpdateFailed,
    };
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _login(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final saved = await context.read<EngineController>().login(
      l.loginScreenTitle,
    );
    if (saved) {
      messenger.showSnackBar(
        SnackBar(content: Text(l.settingsLoggedInMessage)),
      );
    }
  }

  Future<void> _logout(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await context.read<EngineController>().logout();
    messenger.showSnackBar(SnackBar(content: Text(l.settingsLoggedOutMessage)));
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
