import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:viddownloader/controllers/locale_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('first launch starts in English even if nothing is saved', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = await LocaleController.load();
    expect(controller.locale, LocaleController.english);
    expect(controller.isEnglish, isTrue);
  });

  test('restores the last language chosen', () async {
    SharedPreferences.setMockInitialValues({LocaleController.prefsKey: 'es'});
    final controller = await LocaleController.load();
    expect(controller.locale, LocaleController.spanish);
  });

  test('unknown saved values fall back to English', () async {
    SharedPreferences.setMockInitialValues({LocaleController.prefsKey: 'fr'});
    final controller = await LocaleController.load();
    expect(controller.locale, LocaleController.english);
  });

  test('changing the language notifies and is saved for next launch', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = await LocaleController.load();
    var notified = 0;
    controller.addListener(() => notified++);

    await controller.setLocale(const Locale('es'));

    expect(controller.locale, LocaleController.spanish);
    expect(notified, 1);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(LocaleController.prefsKey), 'es');

    // Simulate an app restart.
    final restarted = await LocaleController.load();
    expect(restarted.locale, LocaleController.spanish);
  });

  test('toggle switches between English and Spanish', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = await LocaleController.load();
    await controller.toggle();
    expect(controller.locale, LocaleController.spanish);
    await controller.toggle();
    expect(controller.locale, LocaleController.english);
  });

  test('setting the same language does not notify', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = await LocaleController.load();
    var notified = 0;
    controller.addListener(() => notified++);
    await controller.setLocale(const Locale('en'));
    expect(notified, 0);
  });
}
