class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );
  static const mapsKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');
  static const allowAnonymous = bool.fromEnvironment('ALLOW_ANONYMOUS_AUTH');

  static bool get hasBackend =>
      Uri.tryParse(supabaseUrl)?.scheme == 'https' &&
      publishableKey.isNotEmpty &&
      !publishableKey.startsWith('YOUR_');
  static bool get hasMap => mapsKey.isNotEmpty;
}
