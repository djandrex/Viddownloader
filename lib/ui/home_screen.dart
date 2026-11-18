import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../controllers/download_controller.dart';
import '../controllers/engine_controller.dart';
import '../core/instagram_url.dart';
import '../l10n/app_localizations.dart';
import 'l10n_helpers.dart';
import 'settings_screen.dart';
import 'widgets/clipboard_banner.dart';
import 'widgets/language_toggle.dart';
import 'widgets/status_card.dart';

/// The only main screen: link field, Paste, Download and the status card.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late final DownloadController _controller;

  /// Instagram link found in the clipboard and offered in the banner.
  String? _suggestion;

  /// Last suggestion the user dismissed, so we don't offer it again.
  String? _dismissed;

  @override
  void initState() {
    super.initState();
    _controller = context.read<DownloadController>();
    _controller.addListener(_showTransientError);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // After the first build the notification texts are ready, so a link
      // shared from Instagram can start downloading right away.
      await _controller.initialize();
      await _checkClipboard();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_showTransientError);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkClipboard();
  }

  /// Looks for an Instagram link in the clipboard when the app comes back to
  /// the foreground. `hasStrings()` does not read the content, so we only read
  /// it when there is text. Android 12+ shows a system notice when an app
  /// reads the clipboard; that is expected.
  Future<void> _checkClipboard() async {
    if (!mounted || _controller.isBusy) return;
    try {
      if (!await Clipboard.hasStrings()) return;
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final url = InstagramUrl.extract(data?.text);
      if (!mounted || url == null) return;
      final current = InstagramUrl.extract(_controller.urlController.text);
      if (url == current || url == _dismissed) return;
      setState(() => _suggestion = url);
    } on PlatformException {
      // Clipboard not available: ignore.
    }
  }

  Future<void> _pasteFromClipboard() async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    String? text;
    try {
      text = (await Clipboard.getData(Clipboard.kTextPlain))?.text;
    } on PlatformException {
      text = null;
    }
    if (!mounted) return;
    if (InstagramUrl.extract(text) == null) {
      messenger.showSnackBar(SnackBar(content: Text(l.clipboardNoLink)));
      return;
    }
    _controller.pasteText(text!);
    setState(() => _suggestion = null);
  }

  void _acceptSuggestion() {
    final url = _suggestion;
    if (url == null) return;
    _controller.pasteText(url);
    setState(() => _suggestion = null);
  }

  void _dismissSuggestion() {
    setState(() {
      _dismissed = _suggestion;
      _suggestion = null;
    });
  }

  Future<void> _download() async {
    FocusScope.of(context).unfocus();
    setState(() => _suggestion = null);
    await _controller.start(
      texts: nativeTextsFor(AppLocalizations.of(context)),
    );
  }

  Future<void> _open() async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final opened = await _controller.openFirstVideo();
    if (!opened && mounted) {
      messenger.showSnackBar(SnackBar(content: Text(l.openFailed)));
    }
  }

  /// "Log in" from a LOGIN_REQUIRED error: open the login screen and, if a
  /// session was saved, retry the same link.
  Future<void> _loginAndRetry() async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final saved = await context.read<EngineController>().login(
      l.loginScreenTitle,
    );
    if (!mounted || !saved) return;
    messenger.showSnackBar(SnackBar(content: Text(l.settingsLoggedInMessage)));
    await _download();
  }

  void _showTransientError() {
    final error = _controller.takeTransientError();
    if (error == null || !mounted) return;
    final l = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(errorMessage(l, error))));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final controller = context.watch<DownloadController>();
    // Keep notification texts in the current language for downloads started
    // from Instagram's Share menu.
    controller.nativeTexts = nativeTextsFor(l);
    final busy = controller.isBusy;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.appTitle),
        actions: [
          const LanguageToggle(),
          IconButton(
            tooltip: l.settingsTooltip,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              l.homeHeadline,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l.homeSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            if (_suggestion != null && !busy) ...[
              ClipboardBanner(
                url: _suggestion!,
                onPaste: _acceptSuggestion,
                onDismiss: _dismissSuggestion,
              ),
              const SizedBox(height: 16),
            ],
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller.urlController,
              builder: (context, value, _) => TextField(
                key: const Key('url-field'),
                controller: controller.urlController,
                enabled: !busy,
                keyboardType: TextInputType.url,
                autocorrect: false,
                textInputAction: TextInputAction.go,
                onSubmitted: (_) => _download(),
                decoration: InputDecoration(
                  labelText: l.urlFieldLabel,
                  hintText: l.urlFieldHint,
                  prefixIcon: const Icon(Icons.link),
                  border: const OutlineInputBorder(),
                  suffixIcon: value.text.isEmpty || busy
                      ? null
                      : IconButton(
                          tooltip: l.clearTooltip,
                          icon: const Icon(Icons.clear),
                          onPressed: controller.clear,
                        ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: busy ? null : _pasteFromClipboard,
                  icon: const Icon(Icons.content_paste),
                  label: Text(l.pasteButton),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    key: const Key('download-button'),
                    onPressed: busy ? null : _download,
                    icon: const Icon(Icons.download),
                    label: Text(l.downloadButton),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            StatusCard(
              status: controller.status,
              onCancel: controller.cancel,
              onOpen: _open,
              onShare: controller.shareVideos,
              onLogin: _loginAndRetry,
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l.shareTip,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
