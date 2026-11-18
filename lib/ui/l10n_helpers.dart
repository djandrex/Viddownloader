import '../core/download_state.dart';
import '../l10n/app_localizations.dart';
import '../services/downloader_bridge.dart';

/// Friendly, translated message for each error code.
String errorMessage(AppLocalizations l, DownloadErrorCode code) =>
    switch (code) {
      DownloadErrorCode.invalidUrl => l.errorInvalidUrl,
      DownloadErrorCode.privateOrDeleted => l.errorPrivateOrDeleted,
      DownloadErrorCode.loginRequired => l.errorLoginRequired,
      DownloadErrorCode.rateLimited => l.errorRateLimited,
      DownloadErrorCode.network => l.errorNetwork,
      DownloadErrorCode.busy => l.errorBusy,
      DownloadErrorCode.storagePermission => l.errorStoragePermission,
      DownloadErrorCode.unknown => l.errorUnknown,
    };

/// Notification texts in the current language, sent to Android when a
/// download starts. `{current}`, `{total}` and `{count}` are filled in natively.
NativeTexts nativeTextsFor(AppLocalizations l) {
  // Build the patterns with sentinel numbers and swap them for placeholders,
  // so translators only maintain the normal ARB messages.
  const a = 1234567, b = 7654321;
  return NativeTexts(
    channelName: l.notifChannelName,
    downloading: l.notifDownloading,
    itemPattern: l
        .statusItem(a, b)
        .replaceAll('$a', '{current}')
        .replaceAll('$b', '{total}'),
    saving: l.statusSaving,
    successSingle: l.successMessage(1),
    successMultiplePattern: l.successMessage(a).replaceAll('$a', '{count}'),
    failed: l.notifFailed,
    canceled: l.canceledMessage,
    cancelAction: l.cancelButton,
  );
}
