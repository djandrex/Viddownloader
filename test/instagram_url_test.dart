import 'package:flutter_test/flutter_test.dart';
import 'package:viddownloader/core/instagram_url.dart';

void main() {
  group('InstagramUrl.clean accepts and normalizes', () {
    const cases = {
      // Reels
      'https://www.instagram.com/reel/C1a2B3c4D5e/':
          'https://www.instagram.com/reel/C1a2B3c4D5e/',
      'https://www.instagram.com/reel/C1a2B3c4D5e':
          'https://www.instagram.com/reel/C1a2B3c4D5e/',
      'https://www.instagram.com/reels/C1a2B3c4D5e/':
          'https://www.instagram.com/reel/C1a2B3c4D5e/',
      // Posts and IGTV
      'https://www.instagram.com/p/Cx_Y-z123/':
          'https://www.instagram.com/p/Cx_Y-z123/',
      'https://www.instagram.com/tv/B8a9C0d1E2f/':
          'https://www.instagram.com/tv/B8a9C0d1E2f/',
      // Without www, mobile domain, no scheme, http, uppercase host
      'https://instagram.com/reel/ABC123/':
          'https://www.instagram.com/reel/ABC123/',
      'https://m.instagram.com/p/ABC123/':
          'https://www.instagram.com/p/ABC123/',
      'instagram.com/reel/ABC123': 'https://www.instagram.com/reel/ABC123/',
      'http://www.instagram.com/reel/ABC123/':
          'https://www.instagram.com/reel/ABC123/',
      'https://WWW.Instagram.com/reel/ABC123/':
          'https://www.instagram.com/reel/ABC123/',
      // Short domain
      'https://instagr.am/p/ABC123/': 'https://www.instagram.com/p/ABC123/',
      // Username before the type
      'https://www.instagram.com/some.user/reel/ABC123/':
          'https://www.instagram.com/reel/ABC123/',
      'https://www.instagram.com/some_user/p/ABC123/?img_index=2':
          'https://www.instagram.com/p/ABC123/',
      // Short share links (resolved on the Android side)
      'https://www.instagram.com/share/BAabc123XYZ':
          'https://www.instagram.com/share/BAabc123XYZ/',
      'https://www.instagram.com/share/reel/BAabc123XYZ/':
          'https://www.instagram.com/share/reel/BAabc123XYZ/',
      // Shortcode case is preserved
      'https://www.instagram.com/reel/AbCdEf/':
          'https://www.instagram.com/reel/AbCdEf/',
    };

    cases.forEach((input, expected) {
      test(input, () => expect(InstagramUrl.clean(input), expected));
    });
  });

  group('InstagramUrl.clean removes junk parameters', () {
    test('igsh', () {
      expect(
        InstagramUrl.clean(
          'https://www.instagram.com/reel/ABC123/?igsh=MWQ1ZGUxMzBkMA==',
        ),
        'https://www.instagram.com/reel/ABC123/',
      );
    });
    test('utm and fragment', () {
      expect(
        InstagramUrl.clean(
          'https://www.instagram.com/p/ABC123/?utm_source=ig_web_copy_link&utm_medium=x#comments',
        ),
        'https://www.instagram.com/p/ABC123/',
      );
    });
    test('surrounding spaces', () {
      expect(
        InstagramUrl.clean('   https://www.instagram.com/reel/ABC123/  '),
        'https://www.instagram.com/reel/ABC123/',
      );
    });
  });

  group('InstagramUrl.clean rejects', () {
    const rejected = [
      null,
      '',
      '   ',
      'not a link',
      // Other domains (including look-alikes)
      'https://www.youtube.com/watch?v=abc',
      'https://www.tiktok.com/@user/video/123',
      'https://instagram.com.evil.com/reel/ABC123/',
      'https://evilinstagram.com/reel/ABC123/',
      'https://www.instagram.co/reel/ABC123/',
      // Profiles, stories, audio, explore, home
      'https://www.instagram.com/',
      'https://www.instagram.com/some.user/',
      'https://www.instagram.com/stories/some.user/3123456789012345678/',
      'https://www.instagram.com/reels/audio/123456789/',
      'https://www.instagram.com/explore/tags/cats/',
      'https://www.instagram.com/accounts/login/',
      // Missing or invalid shortcode
      'https://www.instagram.com/reel/',
      'https://www.instagram.com/p/',
      'https://www.instagram.com/reel/ABC%20123/',
      'https://www.instagram.com/share/',
      'https://www.instagram.com/share/stories/ABC123/',
      // Text with spaces is not a single link
      'https://www.instagram.com/reel/ABC123/ and more',
      // Other schemes
      'ftp://www.instagram.com/reel/ABC123/',
    ];

    for (final input in rejected) {
      test('$input', () => expect(InstagramUrl.clean(input), isNull));
    }
  });

  group('InstagramUrl.extract finds links inside text', () {
    test('text shared by the Instagram app', () {
      expect(
        InstagramUrl.extract(
          'Check out this reel! https://www.instagram.com/reel/ABC123/?igsh=xyz',
        ),
        'https://www.instagram.com/reel/ABC123/',
      );
    });
    test('link between parentheses and with a final dot', () {
      expect(
        InstagramUrl.extract('Look (https://instagram.com/p/ABC123/).'),
        'https://www.instagram.com/p/ABC123/',
      );
    });
    test('skips invalid links and returns the first valid one', () {
      expect(
        InstagramUrl.extract(
          'https://www.instagram.com/some.user/ then https://www.instagram.com/tv/XYZ789/',
        ),
        'https://www.instagram.com/tv/XYZ789/',
      );
    });
    test('returns null without Instagram links', () {
      expect(InstagramUrl.extract('hello https://example.com/reel/1'), isNull);
      expect(InstagramUrl.extract(null), isNull);
      expect(InstagramUrl.isValid('just text'), isFalse);
    });
  });

  test('isShareLink', () {
    expect(
      InstagramUrl.isShareLink('https://www.instagram.com/share/BAabc123/'),
      isTrue,
    );
    expect(
      InstagramUrl.isShareLink('https://www.instagram.com/reel/ABC123/'),
      isFalse,
    );
  });
}
