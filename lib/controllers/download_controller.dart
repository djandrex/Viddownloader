import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../core/download_state.dart';
import '../core/instagram_url.dart';
import '../services/downloader_bridge.dart';

/// Holds the state of the main screen: the link field and the current
/// download. The UI only reads from here and calls its methods.
class DownloadController extends ChangeNotifier {
  DownloadController(this._bridge) {
    _statusSub = _bridge.statusStream.listen(
      _onStatus,
      onError: (Object _) {}, // Progress stream errors are not fatal.
    );
    _sharedSub = _bridge.sharedTexts.listen(handleSharedText);
  }

  final DownloaderBridge _bridge;
  late final StreamSubscription<DownloadStatus> _statusSub;
  late final StreamSubscription<String> _sharedSub;

  /// The link text field. Kept here so it survives language changes.
  final TextEditingController urlController = TextEditingController();

  DownloadStatus _status = DownloadStatus.idle;
  DownloadStatus get status => _status;

  bool get isBusy => _status.phase.isBusy;

  /// Restores the state after a cold start: a download that was still running
  /// and a link shared from Instagram that opened the app.
  Future<void> initialize() async {
    try {
      final current = await _bridge.getCurrentStatus();
      if (current.phase.isBusy) _setStatus(current);
      final shared = await _bridge.getInitialSharedText();
      if (shared != null) await handleSharedText(shared);
    } on PlatformException {
      // Nothing to restore.
    } on MissingPluginException {
      // Running without the Android side (e.g. some tests).
    }
  }

  /// Called when text arrives from Instagram's "Share" menu: fills the field
  /// and starts downloading right away.
  Future<void> handleSharedText(String text) async {
    final url = InstagramUrl.extract(text);
    if (url == null) {
      urlController.text = text.trim();
      _setStatus(DownloadStatus.failure(DownloadErrorCode.invalidUrl));
      return;
    }
    if (isBusy) {
      _setStatus(_status, transientError: DownloadErrorCode.busy);
      return;
    }
    urlController.text = url;
    await start(texts: _pendingTexts);
  }

  /// Texts for native notifications. The UI sets them on every build so they
  /// always follow the current language.
  NativeTexts? _pendingTexts;
  set nativeTexts(NativeTexts texts) => _pendingTexts = texts;

  /// Error shown once in a snackbar without replacing the current status
  /// (for example "a download is already in progress").
  DownloadErrorCode? _transientError;
  DownloadErrorCode? takeTransientError() {
    final error = _transientError;
    _transientError = null;
    return error;
  }

  /// Validates the link in the field and asks Android to download it.
  Future<void> start({NativeTexts? texts}) async {
    if (isBusy) {
      _setStatus(_status, transientError: DownloadErrorCode.busy);
      return;
    }
    final url = InstagramUrl.extract(urlController.text);
    if (url == null) {
      _setStatus(DownloadStatus.failure(DownloadErrorCode.invalidUrl));
      return;
    }
    urlController.text = url;
    final nativeTexts = texts ?? _pendingTexts;
    if (nativeTexts == null) return; // UI not built yet.

    _setStatus(DownloadStatus(phase: DownloadPhase.preparing, url: url));
    try {
      final allowed = await _bridge.requestPermissions();
      if (!allowed) {
        _setStatus(
          DownloadStatus.failure(DownloadErrorCode.storagePermission, url: url),
        );
        return;
      }
      await _bridge.startDownload(url, nativeTexts);
    } on PlatformException catch (e) {
      _setStatus(
        DownloadStatus.failure(DownloadErrorCode.fromCode(e.code), url: url),
      );
    }
  }

  Future<void> cancel() async {
    try {
      await _bridge.cancelDownload();
    } on PlatformException {
      // Already finished.
    }
  }

  /// Pastes [text] into the field (from the button or the clipboard banner).
  void pasteText(String text) {
    urlController.text = InstagramUrl.extract(text) ?? text.trim();
    if (_status.phase == DownloadPhase.error) _setStatus(DownloadStatus.idle);
  }

  void clear() {
    urlController.clear();
    if (!isBusy) _setStatus(DownloadStatus.idle);
  }

  Future<bool> openFirstVideo() async {
    if (_status.uris.isEmpty) return false;
    try {
      return await _bridge.openVideo(_status.uris.first);
    } on PlatformException {
      return false;
    }
  }

  Future<void> shareVideos() async {
    if (_status.uris.isEmpty) return;
    try {
      await _bridge.shareVideos(_status.uris);
    } on PlatformException {
      // Nothing useful to show.
    }
  }

  void _onStatus(DownloadStatus status) {
    // Ignore a stale "idle" while we are waiting for the worker to start.
    if (status.phase == DownloadPhase.idle && _status.phase.isBusy) return;
    _setStatus(status);
  }

  void _setStatus(DownloadStatus status, {DownloadErrorCode? transientError}) {
    _status = status;
    _transientError = transientError;
    notifyListeners();
  }

  @override
  void dispose() {
    _statusSub.cancel();
    _sharedSub.cancel();
    urlController.dispose();
    super.dispose();
  }
}
