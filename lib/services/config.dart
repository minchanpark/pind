class AppConfig {
  static const authRedirectUrl = String.fromEnvironment(
    'AUTH_REDIRECT_URL',
    defaultValue: 'com.pind.app://login-callback',
  );
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );
  static const mapsKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');

  /// Host of shareable profile links (`https://<host>/@handle`). The same
  /// host must serve the iOS/Android app-link files; see `web_links/`.
  static const linkHost = String.fromEnvironment(
    'LINK_HOST',
    defaultValue: 'pind-profile-links.vercel.app',
  );

  /// Kakao native app key; KakaoTalk sharing falls back to the share sheet
  /// without it.
  static const kakaoNativeAppKey = String.fromEnvironment(
    'KAKAO_NATIVE_APP_KEY',
  );
  static const allowAnonymous = bool.fromEnvironment('ALLOW_ANONYMOUS_AUTH');

  static bool get hasBackend =>
      Uri.tryParse(supabaseUrl)?.scheme == 'https' &&
      publishableKey.isNotEmpty &&
      !publishableKey.startsWith('YOUR_');
  static bool get hasMap => mapsKey.isNotEmpty;
}
