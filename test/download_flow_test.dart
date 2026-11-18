import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:viddownloader/app.dart';
import 'package:viddownloader/controllers/locale_controller.dart';
import 'package:viddownloader/services/downloader_bridge.dart';

import 'support/fake_native.dart';

Future<void> _pumpApp(
  WidgetTester tester,
  FakeNative native, {
  bool settle = true,
}) async {
  native.install();
  SharedPreferences.setMockInitialValues({});
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
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    // A running download shows an endless progress animation.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  late FakeNative native;

  // install() is called inside each test (see _pumpApp) so the fake event
  // stream runs in the test's fake-async zone.
  setUp(() => native = FakeNative());
  tearDown(() => native.uninstall());

  testWidgets('invalid link shows an error and does not call Android', (
    tester,
  ) async {
    await _pumpApp(tester, native);
    await tester.enterText(
      find.byKey(const Key('url-field')),
      'https://www.instagram.com/some.user/',
    );
    await tester.tap(find.byKey(const Key('download-button')));
    await tester.pumpAndSettle();

    expect(
      find.textContaining("doesn't look like an Instagram"),
      findsOneWidget,
    );
    expect(native.callsTo('startDownload'), isEmpty);
  });

  testWidgets('valid link is cleaned, sent to Android and progress is shown', (
    tester,
  ) async {
    await _pumpApp(tester, native);
    await tester.enterText(
      find.byKey(const Key('url-field')),
      'https://www.instagram.com/reel/ABC123/?igsh=xyz',
    );
    await tester.tap(find.byKey(const Key('download-button')));
    await tester.pump();

    final call = native.callsTo('startDownload').single;
    final args = call.arguments as Map;
    expect(args['url'], 'https://www.instagram.com/reel/ABC123/');
    final texts = args['texts'] as Map;
    expect(texts['downloading'], 'Downloading video…');
    expect(texts['itemPattern'], 'Video {current} of {total}');
    expect(
      texts['successMultiplePattern'],
      '{count} videos saved to your gallery',
    );

    native.emit({
      'phase': 'downloading',
      'progress': 42.4,
      'item': 2,
      'itemCount': 3,
    });
    await tester.pump();
    expect(find.text('Downloading… 42%'), findsOneWidget);
    expect(find.text('Video 2 of 3'), findsOneWidget);

    native.emit({
      'phase': 'success',
      'uris': ['content://media/1', 'content://media/2', 'content://media/3'],
    });
    await tester.pumpAndSettle();
    expect(find.text('3 videos saved to your gallery'), findsOneWidget);

    await tester.tap(find.text('Share'));
    await tester.pump();
    expect(
      (native.callsTo('shareVideos').single.arguments as Map)['uris'],
      hasLength(3),
    );
  });

  testWidgets('error codes from Android are shown translated', (tester) async {
    await _pumpApp(tester, native);
    native.emit({'phase': 'error', 'errorCode': 'LOGIN_REQUIRED'});
    await tester.pumpAndSettle();
    expect(
      find.text('Instagram is asking to log in to show this video.'),
      findsOneWidget,
    );
    expect(find.text('Log in to Instagram'), findsOneWidget);
  });

  testWidgets('clipboard banner offers the link but never pastes by itself', (
    tester,
  ) async {
    native.clipboardText = 'Look https://www.instagram.com/reel/XYZ789/?igsh=1';
    await _pumpApp(tester, native);

    expect(
      find.text('There is an Instagram link in your clipboard.'),
      findsOneWidget,
    );
    final field = tester.widget<TextField>(find.byKey(const Key('url-field')));
    expect(field.controller!.text, isEmpty);

    await tester.tap(find.widgetWithText(TextButton, 'Paste'));
    await tester.pumpAndSettle();
    expect(field.controller!.text, 'https://www.instagram.com/reel/XYZ789/');
    expect(
      find.text('There is an Instagram link in your clipboard.'),
      findsNothing,
    );
  });

  testWidgets('a link shared from Instagram starts the download directly', (
    tester,
  ) async {
    native.responses['getInitialSharedText'] =
        'https://www.instagram.com/p/SHARED1/?utm_source=ig';
    await _pumpApp(tester, native, settle: false);

    final call = native.callsTo('startDownload').single;
    expect(
      (call.arguments as Map)['url'],
      'https://www.instagram.com/p/SHARED1/',
    );
  });
}
