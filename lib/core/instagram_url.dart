/// Finds, validates and cleans Instagram links.
///
/// Everything here is pure Dart (no Flutter, no platform code) so it can be
/// covered by fast unit tests. The Android side receives only URLs that went
/// through [InstagramUrl.clean].
class InstagramUrl {
  InstagramUrl._();

  /// Hosts we accept. Anything else is rejected.
  static const Set<String> _hosts = {
    'instagram.com',
    'www.instagram.com',
    'm.instagram.com',
    'instagr.am',
    'www.instagr.am',
  };

  /// Path types that point to a single post that can contain videos.
  static const Set<String> _mediaKinds = {'reel', 'reels', 'p', 'tv'};

  /// Instagram shortcodes only use these characters.
  static final RegExp _shortcode = RegExp(r'^[A-Za-z0-9_-]+$');

  /// Finds Instagram-looking links inside a longer text, for example the text
  /// Instagram sends when the user taps "Share".
  static final RegExp _linkInText = RegExp(
    r'(?:https?://)?(?:www\.|m\.)?(?:instagram\.com|instagr\.am)/[^\s<>"]+',
    caseSensitive: false,
  );

  /// Characters that often stick to the end of a link copied from a sentence.
  static final RegExp _trailingPunctuation = RegExp(r'''[)\].,;:!?'"»]+$''');

  /// Returns the first valid, cleaned Instagram video link found in [text],
  /// or `null` if there is none.
  static String? extract(String? text) {
    if (text == null || text.trim().isEmpty) return null;
    for (final match in _linkInText.allMatches(text)) {
      final candidate = match.group(0)!.replaceAll(_trailingPunctuation, '');
      final cleaned = clean(candidate);
      if (cleaned != null) return cleaned;
    }
    return null;
  }

  /// Returns `true` if [text] contains a link we can download.
  static bool isValid(String? text) => extract(text) != null;

  /// Returns `true` for short `/share/...` links. They redirect to the real
  /// post, so the Android side resolves them before calling yt-dlp.
  static bool isShareLink(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    final segments = _segments(uri);
    return segments.isNotEmpty && segments.first.toLowerCase() == 'share';
  }

  /// Validates a single link and returns its canonical form
  /// (`https://www.instagram.com/<kind>/<shortcode>/`), without tracking
  /// parameters such as `?igsh=` or `?utm_source=`.
  ///
  /// Returns `null` for other domains and for paths that are not a post
  /// (profiles, stories, audio pages, explore, ...).
  static String? clean(String? input) {
    if (input == null) return null;
    var text = input.trim();
    if (text.isEmpty || text.contains(RegExp(r'\s'))) return null;
    if (!text.toLowerCase().startsWith(RegExp(r'https?://'))) {
      text = 'https://$text';
    }

    final uri = Uri.tryParse(text);
    if (uri == null || !_hosts.contains(uri.host.toLowerCase())) return null;

    final segments = _segments(uri);
    if (segments.isEmpty) return null;

    // Short share links: instagram.com/share/<code> or /share/reel/<code>.
    if (segments.first.toLowerCase() == 'share') {
      final rest = segments.skip(1).toList();
      if (rest.isEmpty || rest.length > 2) return null;
      if (rest.length == 2 && !_mediaKinds.contains(rest.first.toLowerCase())) {
        return null;
      }
      if (!_shortcode.hasMatch(rest.last)) return null;
      final path = rest.length == 2
          ? '${rest.first.toLowerCase()}/${rest.last}'
          : rest.last;
      return 'https://www.instagram.com/share/$path/';
    }

    // instagram.com/<kind>/<shortcode>
    final direct = _canonical(segments, 0);
    if (direct != null) return direct;

    // instagram.com/<username>/<kind>/<shortcode>
    if (segments.length >= 3 &&
        !_reservedFirstSegments.contains(segments[0].toLowerCase())) {
      return _canonical(segments, 1);
    }
    return null;
  }

  /// First path segments that are never a username.
  static const Set<String> _reservedFirstSegments = {
    'stories',
    'explore',
    'accounts',
    'direct',
    'about',
    'legal',
    'reels', // /reels/audio/... is handled (and rejected) in _canonical.
  };

  static String? _canonical(List<String> segments, int kindIndex) {
    if (segments.length < kindIndex + 2) return null;
    final kind = segments[kindIndex].toLowerCase();
    final code = segments[kindIndex + 1];
    if (!_mediaKinds.contains(kind)) return null;
    if (kind == 'reels' && code == 'audio') return null;
    if (!_shortcode.hasMatch(code)) return null;
    final normalizedKind = kind == 'reels' ? 'reel' : kind;
    return 'https://www.instagram.com/$normalizedKind/$code/';
  }

  /// Non-empty path segments. Keywords (`reel`, `p`, `share`...) are compared
  /// in lowercase; shortcodes keep their case because they are case-sensitive.
  static List<String> _segments(Uri uri) =>
      uri.pathSegments.where((s) => s.isNotEmpty).toList();
}
