import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/download_state.dart';
import '../services/downloader_bridge.dart';

/// State of the Settings screen: yt-dlp version and updates, Instagram
/// session and app version.
class EngineController extends ChangeNotifier {
  EngineController(this._bridge, this._prefs, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  /// Key that stores when yt-dlp was last checked for updates.
  static const String lastUpdateCheckKey = 'engine_last_update_check';

  /// Automatic update checks happen at most once per this period.
  static const Duration autoUpdateInterval = Duration(hours: 24);

  final DownloaderBridge _bridge;
  final SharedPreferences _prefs;
  final DateTime Function() _clock;

  String? engineVersion;
  String appVersion = '';
  bool loggedIn = false;
  bool updating = false;

  /// Loads everything the Settings screen shows.
  Future<void> load() async {
    try {
      appVersion = await _bridge.getAppVersion();
      loggedIn = await _bridge.isLoggedIn();
      notifyListeners();
      engineVersion = await _bridge.getEngineVersion();
    } on PlatformException {
      // Keep the defaults.
    } on MissingPluginException {
      // Running without the Android side.
    }
    notifyListeners();
  }

  /// Checks for a new yt-dlp in the background, at most once every 24 hours.
  /// Errors are ignored: the user can always update manually in Settings.
  Future<void> autoUpdateIfDue() async {
    final last = _prefs.getInt(lastUpdateCheckKey);
    final now = _clock();
    if (last != null &&
        now.difference(DateTime.fromMillisecondsSinceEpoch(last)) <
            autoUpdateInterval) {
      return;
    }
    final result = await update();
    if (result == EngineUpdateResult.updated ||
        result == EngineUpdateResult.alreadyUpToDate) {
      await _prefs.setInt(lastUpdateCheckKey, now.millisecondsSinceEpoch);
    }
  }

  /// Updates yt-dlp (stable channel).
  Future<EngineUpdateResult> update() async {
    if (updating) return EngineUpdateResult.busy;
    updating = true;
    notifyListeners();
    try {
      final outcome = await _bridge.updateEngine();
      if (outcome.version != null) engineVersion = outcome.version;
      return outcome.updated
          ? EngineUpdateResult.updated
          : EngineUpdateResult.alreadyUpToDate;
    } on PlatformException catch (e) {
      return e.code == 'BUSY'
          ? EngineUpdateResult.busy
          : EngineUpdateResult.failed;
    } on MissingPluginException {
      return EngineUpdateResult.failed;
    } finally {
      updating = false;
      notifyListeners();
    }
  }

  /// Opens the Instagram login screen. Returns `true` if a session was saved.
  Future<bool> login(String screenTitle) async {
    try {
      final saved = await _bridge.login(screenTitle);
      loggedIn = await _bridge.isLoggedIn();
      notifyListeners();
      return saved;
    } on PlatformException {
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _bridge.logout();
    } on PlatformException {
      // Ignore: nothing to remove.
    }
    loggedIn = false;
    notifyListeners();
  }
}
