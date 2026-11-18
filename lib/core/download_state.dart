/// Data types shared by the download controller and the native bridge.
library;

/// Error codes sent by the Android side (and a few produced in Dart).
/// The UI translates each one into a friendly message.
enum DownloadErrorCode {
  invalidUrl('INVALID_URL'),
  privateOrDeleted('PRIVATE_OR_DELETED'),
  loginRequired('LOGIN_REQUIRED'),
  rateLimited('RATE_LIMITED'),
  network('NETWORK'),
  busy('BUSY'),
  storagePermission('STORAGE_PERMISSION'),
  unknown('UNKNOWN');

  const DownloadErrorCode(this.code);

  /// Code used on the platform channel.
  final String code;

  static DownloadErrorCode fromCode(String? code) =>
      DownloadErrorCode.values.firstWhere(
        (e) => e.code == code,
        orElse: () => DownloadErrorCode.unknown,
      );
}

/// Phases of a download, in the order they normally happen.
enum DownloadPhase {
  idle,
  preparing,
  downloading,
  saving,
  success,
  error,
  canceled;

  /// `true` while the native side is working.
  bool get isBusy => this == preparing || this == downloading || this == saving;

  static DownloadPhase fromName(String? name) => DownloadPhase.values
      .firstWhere((e) => e.name == name, orElse: () => DownloadPhase.idle);
}

/// Snapshot of the current download, as reported by the Android side.
class DownloadStatus {
  const DownloadStatus({
    this.phase = DownloadPhase.idle,
    this.progress,
    this.item,
    this.itemCount,
    this.uris = const [],
    this.error,
    this.url,
  });

  static const idle = DownloadStatus();

  final DownloadPhase phase;

  /// 0–100, or `null` when unknown.
  final double? progress;

  /// Current video (1-based) and total videos, for carousels.
  final int? item;
  final int? itemCount;

  /// `content://` URIs of the saved videos (only on success).
  final List<String> uris;

  final DownloadErrorCode? error;

  /// The link being downloaded.
  final String? url;

  /// Builds a status from the map sent through the EventChannel.
  factory DownloadStatus.fromMap(Map<Object?, Object?> map) {
    final phase = DownloadPhase.fromName(map['phase'] as String?);
    final progress = (map['progress'] as num?)?.toDouble();
    return DownloadStatus(
      phase: phase,
      progress: progress == null || progress < 0
          ? null
          : progress.clamp(0, 100),
      item: (map['item'] as num?)?.toInt(),
      itemCount: (map['itemCount'] as num?)?.toInt(),
      uris: (map['uris'] as List<Object?>? ?? const [])
          .whereType<String>()
          .toList(),
      error: phase == DownloadPhase.error
          ? DownloadErrorCode.fromCode(map['errorCode'] as String?)
          : null,
      url: map['url'] as String?,
    );
  }

  /// Local error (for example an invalid link) that never reached Android.
  factory DownloadStatus.failure(DownloadErrorCode error, {String? url}) =>
      DownloadStatus(phase: DownloadPhase.error, error: error, url: url);
}

/// Result of updating yt-dlp.
enum EngineUpdateResult { updated, alreadyUpToDate, busy, failed }
