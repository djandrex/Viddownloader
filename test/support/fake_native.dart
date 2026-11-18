import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:viddownloader/services/downloader_bridge.dart';

/// Simulates the Android side (MethodChannel + EventChannel) and the system
/// clipboard, so widget tests run without a device.
class FakeNative {
  FakeNative({this.clipboardText});

  /// Text returned by the clipboard (null = empty clipboard).
  String? clipboardText;

  /// Every call received on the MethodChannel, in order.
  final List<MethodCall> calls = [];

  /// Values returned by specific methods (method name -> value).
  final Map<String, Object?> responses = {
    'getCurrentStatus': null,
    'getInitialSharedText': null,
    'requestPermissions': true,
    'getEngineVersion': '2026.11.01',
    'getAppVersion': '1.0.0 (1)',
    'isLoggedIn': false,
    'updateEngine': {'status': 'ALREADY_UP_TO_DATE', 'version': '2026.11.01'},
  };

  /// Methods that fail with a PlatformException of the given code.
  final Map<String, String> errors = {};

  MockStreamHandlerEventSink? _events;

  TestDefaultBinaryMessenger get _messenger =>
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  static const _methods = MethodChannel(DownloaderBridge.methodChannelName);
  static const _progress = EventChannel(DownloaderBridge.eventChannelName);

  void install() {
    _messenger.setMockMethodCallHandler(_methods, (call) async {
      calls.add(call);
      final error = errors[call.method];
      if (error != null) throw PlatformException(code: error);
      return responses[call.method];
    });
    _messenger.setMockStreamHandler(
      _progress,
      MockStreamHandler.inline(
        onListen: (arguments, events) {
          _events = events;
        },
        onCancel: (arguments) {
          _events = null;
        },
      ),
    );
    _messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      switch (call.method) {
        case 'Clipboard.hasStrings':
          return {'value': clipboardText?.isNotEmpty ?? false};
        case 'Clipboard.getData':
          return clipboardText == null ? null : {'text': clipboardText};
      }
      return null;
    });
  }

  void uninstall() {
    _messenger.setMockMethodCallHandler(_methods, null);
    _messenger.setMockStreamHandler(_progress, null);
    _messenger.setMockMethodCallHandler(SystemChannels.platform, null);
  }

  /// Sends a progress event as the Android side would.
  void emit(Map<String, Object?> event) => _events?.success(event);

  /// Calls of a given method.
  Iterable<MethodCall> callsTo(String method) =>
      calls.where((c) => c.method == method);
}
