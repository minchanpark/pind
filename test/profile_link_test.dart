import 'package:flutter_test/flutter_test.dart';
import 'package:pind_flutter/model/profile_link.dart';
import 'package:pind_flutter/model/profile_model.dart';

void main() {
  const id = '9f1c2d3e-4b5a-6c7d-8e9f-0a1b2c3d4e5f';

  test('parses handle and user links on the configured host', () {
    for (final raw in [
      'https://pind-profile-links.vercel.app/@pind_junhwan',
      'https://www.pind-profile-links.vercel.app/@pind_junhwan/',
      'http://pind-profile-links.vercel.app/@PIND_JUNHWAN?utm=qr',
      ' com.pind.app://profile/@pind_junhwan ',
    ]) {
      expect(
        ProfileLink.parse(raw),
        const ProfileLink.handle('pind_junhwan'),
        reason: raw,
      );
    }
    expect(
      ProfileLink.parse('https://pind-profile-links.vercel.app/u/$id'),
      const ProfileLink.user(id),
    );
    expect(
      ProfileLink.parse(
        'https://staging.pind-profile-links.vercel.app/@a_b',
        host: 'staging.pind-profile-links.vercel.app',
      ),
      const ProfileLink.handle('a_b'),
    );
  });

  test('rejects anything else', () {
    for (final raw in [
      'https://evil.com/@pind_junhwan',
      'https://pind-profile-links.vercel.app.evil.com/@pind_junhwan',
      'https://pind-profile-links.vercel.app/pind_junhwan',
      'https://pind-profile-links.vercel.app/@ab', // too short
      'https://pind-profile-links.vercel.app/@bad-handle',
      'https://pind-profile-links.vercel.app/u/not-a-uuid',
      'https://pind-profile-links.vercel.app/@a_b/extra',
      'com.pind.app://login-callback?code=1',
      'ftp://pind-profile-links.vercel.app/@pind_junhwan',
      'hello',
      '',
    ]) {
      expect(ProfileLink.parse(raw), isNull, reason: raw);
    }
  });

  test('builds the link from a profile and round-trips', () {
    final withHandle = ProfileLink.of(
      const UserProfile(id: id, handle: 'pind_junhwan', displayName: '이준환'),
    );
    expect('${withHandle.uri}', 'https://pind-profile-links.vercel.app/@pind_junhwan');
    expect(withHandle.display, 'pind-profile-links.vercel.app/@pind_junhwan');
    final noHandle = ProfileLink.of(
      const UserProfile(id: id, displayName: '이준환'),
    );
    expect('${noHandle.uri}', 'https://pind-profile-links.vercel.app/u/$id');
    for (final l in [withHandle, noHandle]) {
      expect(ProfileLink.parse('${l.uri}'), l);
    }
  });
}
