import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Viddownloader'**
  String get appTitle;

  /// No description provided for @homeHeadline.
  ///
  /// In en, this message translates to:
  /// **'Download Instagram videos'**
  String get homeHeadline;

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Paste a Reel or post link and save the video to your gallery.'**
  String get homeSubtitle;

  /// No description provided for @urlFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Instagram link'**
  String get urlFieldLabel;

  /// No description provided for @urlFieldHint.
  ///
  /// In en, this message translates to:
  /// **'https://www.instagram.com/reel/…'**
  String get urlFieldHint;

  /// No description provided for @pasteButton.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get pasteButton;

  /// No description provided for @clearTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearTooltip;

  /// No description provided for @downloadButton.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get downloadButton;

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @openButton.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openButton;

  /// No description provided for @shareButton.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareButton;

  /// No description provided for @dismissButton.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismissButton;

  /// No description provided for @settingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTooltip;

  /// No description provided for @languageToggleTooltip.
  ///
  /// In en, this message translates to:
  /// **'Change language'**
  String get languageToggleTooltip;

  /// No description provided for @shareTip.
  ///
  /// In en, this message translates to:
  /// **'Tip: in Instagram, tap Share → Viddownloader to download right away.'**
  String get shareTip;

  /// No description provided for @clipboardBannerText.
  ///
  /// In en, this message translates to:
  /// **'There is an Instagram link in your clipboard.'**
  String get clipboardBannerText;

  /// No description provided for @clipboardNoLink.
  ///
  /// In en, this message translates to:
  /// **'There is no Instagram link in the clipboard.'**
  String get clipboardNoLink;

  /// No description provided for @statusPreparing.
  ///
  /// In en, this message translates to:
  /// **'Getting the video…'**
  String get statusPreparing;

  /// No description provided for @statusDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading… {percent}%'**
  String statusDownloading(int percent);

  /// No description provided for @statusItem.
  ///
  /// In en, this message translates to:
  /// **'Video {current} of {total}'**
  String statusItem(int current, int total);

  /// No description provided for @statusSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving to the gallery…'**
  String get statusSaving;

  /// No description provided for @successMessage.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Video saved to your gallery} other{{count} videos saved to your gallery}}'**
  String successMessage(int count);

  /// No description provided for @successLocation.
  ///
  /// In en, this message translates to:
  /// **'Folder: Movies/Viddownloader'**
  String get successLocation;

  /// No description provided for @canceledMessage.
  ///
  /// In en, this message translates to:
  /// **'Download canceled.'**
  String get canceledMessage;

  /// No description provided for @openFailed.
  ///
  /// In en, this message translates to:
  /// **'No app found to open the video.'**
  String get openFailed;

  /// No description provided for @errorInvalidUrl.
  ///
  /// In en, this message translates to:
  /// **'That doesn\'t look like an Instagram video link. Use the link of a Reel or a post.'**
  String get errorInvalidUrl;

  /// No description provided for @errorPrivateOrDeleted.
  ///
  /// In en, this message translates to:
  /// **'This video is private, was deleted, or the post has no videos.'**
  String get errorPrivateOrDeleted;

  /// No description provided for @errorLoginRequired.
  ///
  /// In en, this message translates to:
  /// **'Instagram is asking to log in to show this video.'**
  String get errorLoginRequired;

  /// No description provided for @errorRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Instagram is limiting requests. Try again in a few minutes.'**
  String get errorRateLimited;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Check your connection and try again.'**
  String get errorNetwork;

  /// No description provided for @errorBusy.
  ///
  /// In en, this message translates to:
  /// **'A download is already in progress.'**
  String get errorBusy;

  /// No description provided for @errorStoragePermission.
  ///
  /// In en, this message translates to:
  /// **'Storage permission is needed to save videos.'**
  String get errorStoragePermission;

  /// No description provided for @errorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again or update the download engine in Settings.'**
  String get errorUnknown;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Log in to Instagram'**
  String get loginButton;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsEngineSection.
  ///
  /// In en, this message translates to:
  /// **'Download engine'**
  String get settingsEngineSection;

  /// No description provided for @settingsEngineVersion.
  ///
  /// In en, this message translates to:
  /// **'yt-dlp version: {version}'**
  String settingsEngineVersion(String version);

  /// No description provided for @settingsLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get settingsLoading;

  /// No description provided for @settingsUpdateEngine.
  ///
  /// In en, this message translates to:
  /// **'Update download engine'**
  String get settingsUpdateEngine;

  /// No description provided for @settingsEngineUpdated.
  ///
  /// In en, this message translates to:
  /// **'Download engine updated to {version}.'**
  String settingsEngineUpdated(String version);

  /// No description provided for @settingsEngineUpToDate.
  ///
  /// In en, this message translates to:
  /// **'The download engine is already up to date.'**
  String get settingsEngineUpToDate;

  /// No description provided for @settingsEngineUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update. Check your connection and try again.'**
  String get settingsEngineUpdateFailed;

  /// No description provided for @settingsEngineBusy.
  ///
  /// In en, this message translates to:
  /// **'Wait for the current download to finish.'**
  String get settingsEngineBusy;

  /// No description provided for @settingsSessionSection.
  ///
  /// In en, this message translates to:
  /// **'Instagram session (optional)'**
  String get settingsSessionSection;

  /// No description provided for @settingsSessionLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'Logged in. It is only used when Instagram requires it.'**
  String get settingsSessionLoggedIn;

  /// No description provided for @settingsSessionLoggedOut.
  ///
  /// In en, this message translates to:
  /// **'Not logged in. Only needed if Instagram asks for it.'**
  String get settingsSessionLoggedOut;

  /// No description provided for @settingsSessionTip.
  ///
  /// In en, this message translates to:
  /// **'We recommend using a secondary account.'**
  String get settingsSessionTip;

  /// No description provided for @logoutButton.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logoutButton;

  /// No description provided for @settingsLoggedInMessage.
  ///
  /// In en, this message translates to:
  /// **'Session saved.'**
  String get settingsLoggedInMessage;

  /// No description provided for @settingsLoggedOutMessage.
  ///
  /// In en, this message translates to:
  /// **'Session closed.'**
  String get settingsLoggedOutMessage;

  /// No description provided for @settingsAboutSection.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAboutSection;

  /// No description provided for @settingsAppVersion.
  ///
  /// In en, this message translates to:
  /// **'App version: {version}'**
  String settingsAppVersion(String version);

  /// No description provided for @settingsLegalNote.
  ///
  /// In en, this message translates to:
  /// **'Download only public content and respect the creators\' rights.'**
  String get settingsLegalNote;

  /// No description provided for @notifChannelName.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get notifChannelName;

  /// No description provided for @notifDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading video…'**
  String get notifDownloading;

  /// No description provided for @notifFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed'**
  String get notifFailed;

  /// No description provided for @loginScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Log in to Instagram'**
  String get loginScreenTitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
