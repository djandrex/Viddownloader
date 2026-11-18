import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:viddownloader/controllers/engine_controller.dart';
import 'package:viddownloader/core/download_state.dart';
import 'package:viddownloader/services/downloader_bridge.dart';

import 'support/fake_native.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeNative native;

  setUp(() => native = FakeNative()..install());
  tearDown(() => native.uninstall());

  Future<EngineController> create(DateTime now, {int? lastCheck}) async {
    SharedPreferences.setMockInitialValues({
      EngineController.lastUpdateCheckKey: ?lastCheck,
    });
    final prefs = await SharedPreferences.getInstance();
    return EngineController(DownloaderBridge(), prefs, clock: () => now);
  }

  test('checks for updates on first launch and saves the time', () async {
    final now = DateTime(2026, 11, 18, 10);
    final engine = await create(now);
    await engine.autoUpdateIfDue();

    expect(native.callsTo('updateEngine'), hasLength(1));
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getInt(EngineController.lastUpdateCheckKey),
      now.millisecondsSinceEpoch,
    );
  });

  test('does not check again within 24 hours', () async {
    final now = DateTime(2026, 11, 18, 10);
    final engine = await create(
      now,
      lastCheck: now.subtract(const Duration(hours: 23)).millisecondsSinceEpoch,
    );
    await engine.autoUpdateIfDue();
    expect(native.callsTo('updateEngine'), isEmpty);
  });

  test('checks again after 24 hours', () async {
    final now = DateTime(2026, 11, 18, 10);
    final engine = await create(
      now,
      lastCheck: now.subtract(const Duration(hours: 25)).millisecondsSinceEpoch,
    );
    await engine.autoUpdateIfDue();
    expect(native.callsTo('updateEngine'), hasLength(1));
  });

  test('a failed check is retried next time (no timestamp saved)', () async {
    native.errors['updateEngine'] = 'UPDATE_FAILED';
    final engine = await create(DateTime(2026, 11, 18, 10));
    await engine.autoUpdateIfDue();
    expect(native.callsTo('updateEngine'), hasLength(1));
    expect(await engine.update(), EngineUpdateResult.failed);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt(EngineController.lastUpdateCheckKey), isNull);
  });

  test('BUSY from Android is reported as busy', () async {
    native.errors['updateEngine'] = 'BUSY';
    final engine = await create(DateTime(2026, 11, 18));
    expect(await engine.update(), EngineUpdateResult.busy);
  });

  test('manual update reports the new version', () async {
    native.responses['updateEngine'] = {
      'status': 'DONE',
      'version': '2026.11.15',
    };
    final engine = await create(DateTime(2026, 11, 18));
    final result = await engine.update();
    expect(result, EngineUpdateResult.updated);
    expect(engine.engineVersion, '2026.11.15');
  });
}
