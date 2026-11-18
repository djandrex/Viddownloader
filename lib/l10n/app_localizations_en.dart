// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Viddownloader';

  @override
  String get homeHeadline => 'Download Instagram videos';

  @override
  String get homeSubtitle =>
      'Paste a Reel or post link and save the video to your gallery.';

  @override
  String get urlFieldLabel => 'Instagram link';

  @override
  String get urlFieldHint => 'https://www.instagram.com/reel/…';

  @override
  String get pasteButton => 'Paste';

  @override
  String get clearTooltip => 'Clear';

  @override
  String get downloadButton => 'Download';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get openButton => 'Open';

  @override
  String get shareButton => 'Share';

  @override
  String get dismissButton => 'Dismiss';

  @override
  String get settingsTooltip => 'Settings';

  @override
  String get languageToggleTooltip => 'Change language';

  @override
  String get shareTip =>
      'Tip: in Instagram, tap Share → Viddownloader to download right away.';

  @override
  String get clipboardBannerText =>
      'There is an Instagram link in your clipboard.';

  @override
  String get clipboardNoLink => 'There is no Instagram link in the clipboard.';

  @override
  String get statusPreparing => 'Getting the video…';

  @override
  String statusDownloading(int percent) {
    return 'Downloading… $percent%';
  }

  @override
  String statusItem(int current, int total) {
    return 'Video $current of $total';
  }

  @override
  String get statusSaving => 'Saving to the gallery…';

  @override
  String successMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count videos saved to your gallery',
      one: 'Video saved to your gallery',
    );
    return '$_temp0';
  }

  @override
  String get successLocation => 'Folder: Movies/Viddownloader';

  @override
  String get canceledMessage => 'Download canceled.';

  @override
  String get openFailed => 'No app found to open the video.';

  @override
  String get errorInvalidUrl =>
      'That doesn\'t look like an Instagram video link. Use the link of a Reel or a post.';

  @override
  String get errorPrivateOrDeleted =>
      'This video is private, was deleted, or the post has no videos.';

  @override
  String get errorLoginRequired =>
      'Instagram is asking to log in to show this video.';

  @override
  String get errorRateLimited =>
      'Instagram is limiting requests. Try again in a few minutes.';

  @override
  String get errorNetwork =>
      'No internet connection. Check your connection and try again.';

  @override
  String get errorBusy => 'A download is already in progress.';

  @override
  String get errorStoragePermission =>
      'Storage permission is needed to save videos.';

  @override
  String get errorUnknown =>
      'Something went wrong. Try again or update the download engine in Settings.';

  @override
  String get loginButton => 'Log in to Instagram';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsEngineSection => 'Download engine';

  @override
  String settingsEngineVersion(String version) {
    return 'yt-dlp version: $version';
  }

  @override
  String get settingsLoading => 'Loading…';

  @override
  String get settingsUpdateEngine => 'Update download engine';

  @override
  String settingsEngineUpdated(String version) {
    return 'Download engine updated to $version.';
  }

  @override
  String get settingsEngineUpToDate =>
      'The download engine is already up to date.';

  @override
  String get settingsEngineUpdateFailed =>
      'Could not update. Check your connection and try again.';

  @override
  String get settingsEngineBusy => 'Wait for the current download to finish.';

  @override
  String get settingsSessionSection => 'Instagram session (optional)';

  @override
  String get settingsSessionLoggedIn =>
      'Logged in. It is only used when Instagram requires it.';

  @override
  String get settingsSessionLoggedOut =>
      'Not logged in. Only needed if Instagram asks for it.';

  @override
  String get settingsSessionTip => 'We recommend using a secondary account.';

  @override
  String get logoutButton => 'Log out';

  @override
  String get settingsLoggedInMessage => 'Session saved.';

  @override
  String get settingsLoggedOutMessage => 'Session closed.';

  @override
  String get settingsAboutSection => 'About';

  @override
  String settingsAppVersion(String version) {
    return 'App version: $version';
  }

  @override
  String get settingsLegalNote =>
      'Download only public content and respect the creators\' rights.';

  @override
  String get notifChannelName => 'Downloads';

  @override
  String get notifDownloading => 'Downloading video…';

  @override
  String get notifFailed => 'Download failed';

  @override
  String get loginScreenTitle => 'Log in to Instagram';
}
