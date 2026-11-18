import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:viddownloader/app.dart';
import 'package:viddownloader/controllers/locale_controller.dart';
import 'package:viddownloader/services/downloader_bridge.dart';

import 'support/fake_native.dart';

Future<SharedPreferences> _pumpApp(
  WidgetTester tester,
  FakeNative native, {
  Map<String, Object> saved = const {},
}) async {
  native.install();
  SharedPreferences.setMockInitialValues(saved);
  final prefs = await SharedPreferences.getInstance();
  final locale = await LocaleController.load(prefs);
  await tester.pumpWidget(
    ViddownloaderApp(
      prefs: prefs,
      localeController: locale,
      bridge: DownloaderBridge(),
      autoUpdateEngine: false,
    ),
  );
  await tester.pumpAndSettle();
  return prefs;
}

void main() {
  late FakeNative native;

  // install() is called inside each test (see _pumpApp) so the fake event
  // stream runs in the test's fake-async zone.
  setUp(() => native = FakeNative());
  tearDown(() => native.uninstall());

  testWidgets('starts in English by default', (tester) async {
    await _pumpApp(tester, native);
    expect(find.text('Download'), findsOneWidget);
    expect(find.text('Download Instagram videos'), findsOneWidget);
  });

  testWidgets('starts in the last language chosen', (tester) async {
    await _pumpApp(tester, native, saved: {LocaleController.prefsKey: 'es'});
    expect(find.text('Descargar'), findsOneWidget);
    expect(find.text('Descarga vídeos de Instagram'), findsOneWidget);
  });

  testWidgets('EN/ES toggle changes texts instantly and keeps the link', (
    tester,
  ) async {
    final prefs = await _pumpApp(tester, native);
    const link = 'https://www.instagram.com/reel/ABC123/';

    await tester.enterText(find.byKey(const Key('url-field')), link);
    await tester.pump();

    await tester.tap(find.text('ES'));
    await tester.pumpAndSettle();

    expect(find.text('Descargar'), findsOneWidget);
    expect(find.text('Pegar'), findsOneWidget);
    expect(find.text('Download'), findsNothing);
    expect(find.text(link), findsOneWidget, reason: 'the link is kept');
    expect(prefs.getString(LocaleController.prefsKey), 'es');

    await tester.tap(find.text('EN'));
    await tester.pumpAndSettle();

    expect(find.text('Download'), findsOneWidget);
    expect(find.text(link), findsOneWidget);
    expect(prefs.getString(LocaleController.prefsKey), 'en');
  });
}
