import 'package:material_ui/material_ui.dart';

import '../../core/download_state.dart';
import '../../l10n/app_localizations.dart';
import '../l10n_helpers.dart';

/// Shows the progress, result or error of the current download.
class StatusCard extends StatelessWidget {
  const StatusCard({
    super.key,
    required this.status,
    required this.onCancel,
    required this.onOpen,
    required this.onShare,
    required this.onLogin,
  });

  final DownloadStatus status;
  final VoidCallback onCancel;
  final VoidCallback onOpen;
  final VoidCallback onShare;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final child = switch (status.phase) {
      DownloadPhase.idle => null,
      DownloadPhase.preparing ||
      DownloadPhase.downloading ||
      DownloadPhase.saving => _progress(context, l),
      DownloadPhase.success => _success(context, l),
      DownloadPhase.error => _error(context, l),
      DownloadPhase.canceled => _message(
        context,
        icon: Icons.info_outline,
        text: l.canceledMessage,
      ),
    };
    if (child == null) return const SizedBox.shrink();
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }

  Widget _progress(BuildContext context, AppLocalizations l) {
    final theme = Theme.of(context);
    final percent = status.progress;
    final String label = switch (status.phase) {
      DownloadPhase.saving => l.statusSaving,
      DownloadPhase.downloading when percent != null => l.statusDownloading(
        percent.round(),
      ),
      _ => l.statusPreparing,
    };
    final showItem = (status.itemCount ?? 0) > 1 && status.item != null;
    final showBar =
        status.phase == DownloadPhase.downloading && percent != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showItem)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              l.statusItem(status.item!, status.itemCount!),
              style: theme.textTheme.labelLarge,
            ),
          ),
        Text(label, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 12),
        LinearProgressIndicator(value: showBar ? percent / 100 : null),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: onCancel,
            icon: const Icon(Icons.close),
            label: Text(l.cancelButton),
          ),
        ),
      ],
    );
  }

  Widget _success(BuildContext context, AppLocalizations l) {
    final theme = Theme.of(context);
    final count = status.uris.isEmpty ? 1 : status.uris.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _message(
          context,
          icon: Icons.check_circle,
          iconColor: theme.colorScheme.primary,
          text: l.successMessage(count),
          detail: l.successLocation,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: status.uris.isEmpty ? null : onOpen,
                icon: const Icon(Icons.play_arrow),
                label: Text(l.openButton),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: status.uris.isEmpty ? null : onShare,
                icon: const Icon(Icons.share),
                label: Text(l.shareButton),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _error(BuildContext context, AppLocalizations l) {
    final theme = Theme.of(context);
    final code = status.error ?? DownloadErrorCode.unknown;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _message(
          context,
          icon: Icons.error_outline,
          iconColor: theme.colorScheme.error,
          text: errorMessage(l, code),
        ),
        if (code == DownloadErrorCode.loginRequired) ...[
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: onLogin,
            icon: const Icon(Icons.login),
            label: Text(l.loginButton),
          ),
        ],
      ],
    );
  }

  Widget _message(
    BuildContext context, {
    required IconData icon,
    required String text,
    Color? iconColor,
    String? detail,
  }) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(text, style: theme.textTheme.bodyLarge),
              if (detail != null)
                Text(
                  detail,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
