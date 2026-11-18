import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keeps the app language (English or Spanish) and remembers the last choice.
///
/// Rules:
/// * First launch: English, even if the phone is in Spanish.
/// * After that: whatever the user picked last time.
class LocaleController extends ChangeNotifier {
  LocaleController._(this._prefs, this._locale);

  /// Key used in SharedPreferences.
  static const String prefsKey = 'app_language';

  static const Locale english = Locale('en');
  static const Locale spanish = Locale('es');
  static const List<Locale> supportedLocales = [english, spanish];

  final SharedPreferences _prefs;
  Locale _locale;

  /// Reads the saved language. Call it before `runApp()` so the first frame is
  /// already in the right language (no flicker).
  static Future<LocaleController> load([SharedPreferences? prefs]) async {
    final store = prefs ?? await SharedPreferences.getInstance();
    return LocaleController._(store, _fromCode(store.getString(prefsKey)));
  }

  Locale get locale => _locale;

  bool get isEnglish => _locale.languageCode == english.languageCode;

  /// Changes the language right away and saves it for the next launch.
  Future<void> setLocale(Locale locale) async {
    final next = _fromCode(locale.languageCode);
    if (next == _locale) return;
    _locale = next;
    notifyListeners();
    await _prefs.setString(prefsKey, next.languageCode);
  }

  /// Switches between English and Spanish.
  Future<void> toggle() => setLocale(isEnglish ? spanish : english);

  static Locale _fromCode(String? code) => supportedLocales.firstWhere(
    (l) => l.languageCode == code,
    orElse: () => english,
  );
}
