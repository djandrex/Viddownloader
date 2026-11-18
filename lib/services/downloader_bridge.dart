import 'dart:async';

import 'package:flutter/services.dart';

import '../core/download_state.dart';

/// Texts the Android side shows in notifications and in the login screen.
/// They are sent already translated, so notifications follow the app language.
class NativeTexts {
  const NativeTexts({
    required this.channelName,
    required this.downloading,
    required this.itemPattern,
    required this.saving,
    required this.successSingle,
    required this.successMultiplePattern,
    required this.failed,
    required this.canceled,
    required this.cancelAction,
  });

  final String channelName;
  final String downloading;

  /// Contains `{current}` and `{total}`, replaced on the Android side.
  final String itemPattern;
  final String saving;
  final String successSingle;

  /// Contains `{count}`, replaced on the Android side.
  final String successMultiplePattern;
  final String failed;
  final String canceled;
  final String cancelAction;

  Map<String, String> toMap() => {
    'channelName': channelName,
    'downloading': downloading,
    'itemPattern': itemPattern,
    'saving': saving,
    'successSingle': successSingle,
    'successMultiplePattern': successMultiplePattern,
    'failed': failed,
    'canceled': canceled,
    'cancelAction': cancelAction,
  };
}

/// Thin wrapper around the platform channels that talk to the Kotlin code in
/// `android/app/src/main/kotlin/.../bridge/DownloaderChannel.kt`.
///
/// All Instagram/yt-dlp work happens on Android; Dart only sends commands and
/// listens to progress.
class DownloaderBridge {
  DownloaderBridge({MethodChannel? methodChannel, EventChannel? eventChannel})
    : _methods = methodChannel ?? const MethodChannel(methodChannelName),
      _events = eventChannel ?? const EventChannel(eventChannelName) {
    _methods.setMethodCallHandler(_handleNativeCall);
  }

  static const String methodChannelName =
      'io.github.djandrex.viddownloader/downloader';
  static const String eventChannelName =
      'io.github.djandrex.viddownloader/progress';

  final MethodChannel _methods;
  final EventChannel _events;

  final StreamController<String> _sharedTexts =
      StreamController<String>.broadcast();

  Stream<DownloadStatus>? _statusStream;

  /// Texts shared from other apps (Instagram "Share" menu) while the app is
  /// already running.
  Stream<String> get sharedTexts => _sharedTexts.stream;

  /// Continuous download progress coming from Android.
  Stream<DownloadStatus> get statusStream => _statusStream ??= _events
      .receiveBroadcastStream()
      .where((event) => event is Map)
      .map((event) => DownloadStatus.fromMap(event as Map<Object?, Object?>))
      .asBroadcastStream();

  Future<void> _handleNativeCall(MethodCall call) async {
    if (call.method == 'onSharedText' && call.arguments is String) {
      _sharedTexts.add(call.arguments as String);
    }
  }

  /// Text shared to the app when it was launched from the "Share" menu.
  Future<String?> getInitialSharedText() =>
      _methods.invokeMethod<String>('getInitialSharedText');

  /// Starts downloading [url]. Throws a [PlatformException] with code `BUSY`
  /// if another download is running.
  Future<void> startDownload(String url, NativeTexts texts) =>
      _methods.invokeMethod<void>('startDownload', {
        'url': url,
        'texts': texts.toMap(),
      });

  Future<void> cancelDownload() =>
      _methods.invokeMethod<void>('cancelDownload');

  /// Current download state (useful when the app is reopened mid-download).
  Future<DownloadStatus> getCurrentStatus() async {
    final map = await _methods.invokeMapMethod<Object?, Object?>(
      'getCurrentStatus',
    );
    return map == null ? DownloadStatus.idle : DownloadStatus.fromMap(map);
  }

  /// Asks for notification permission (Android 13+) and storage permission
  /// (Android 8–9). Returns `false` only if a permission required to save
  /// videos was denied.
  Future<bool> requestPermissions() async =>
      await _methods.invokeMethod<bool>('requestPermissions') ?? true;

  /// Returns `false` if no app can open the video.
  Future<bool> openVideo(String uri) async =>
      await _methods.invokeMethod<bool>('openVideo', {'uri': uri}) ?? false;

  Future<void> shareVideos(List<String> uris) =>
      _methods.invokeMethod<void>('shareVideos', {'uris': uris});

  Future<String?> getEngineVersion() =>
      _methods.invokeMethod<String>('getEngineVersion');

  /// Updates yt-dlp. Returns the new version, or `null` if it was already up
  /// to date. Throws a [PlatformException] (`BUSY`, `UPDATE_FAILED`) on error.
  Future<EngineUpdateOutcome> updateEngine() async {
    final map = await _methods.invokeMapMethod<String, Object?>('updateEngine');
    final status = map?['status'] as String?;
    return EngineUpdateOutcome(
      updated: status == 'DONE',
      version: map?['version'] as String?,
    );
  }

  Future<String> getAppVersion() async =>
      await _methods.invokeMethod<String>('getAppVersion') ?? '';

  Future<bool> isLoggedIn() async =>
      await _methods.invokeMethod<bool>('isLoggedIn') ?? false;

  /// Opens the Instagram login screen. Returns `true` if a session was saved.
  Future<bool> login(String screenTitle) async =>
      await _methods.invokeMethod<bool>('login', {'title': screenTitle}) ??
      false;

  Future<void> logout() => _methods.invokeMethod<void>('logout');

  void dispose() {
    _methods.setMethodCallHandler(null);
    _sharedTexts.close();
  }
}

/// What happened after asking Android to update yt-dlp.
class EngineUpdateOutcome {
  const EngineUpdateOutcome({required this.updated, this.version});

  final bool updated;
  final String? version;
}
