import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/registration_model.dart';
import '../l10n/l10n.dart';

abstract interface class AuthService {
  AuthIdentity? get identity;
  Stream<AuthIdentity?> get changes;
  Future<void> signIn(LoginProvider provider);
  Future<AuthIdentity> preview();

  /// Ends the session; [changes] then reports null and the app returns to
  /// the login screen.
  Future<void> signOut();
}

class SupabaseAuthService implements AuthService {
  SupabaseAuthService(
    this.client, {
    required this.redirectTo,
    this.allowAnonymous = false,
  });
  final SupabaseClient client;
  final String redirectTo;
  final bool allowAnonymous;

  AuthIdentity? _identity(User? user) => user == null
      ? null
      : AuthIdentity(user.id, development: user.isAnonymous);
  @override
  AuthIdentity? get identity => _identity(client.auth.currentUser);
  @override
  Stream<AuthIdentity?> get changes => client.auth.onAuthStateChange.map(
    (event) => _identity(event.session?.user),
  );

  @override
  Future<void> signIn(LoginProvider provider) async {
    final launched = await client.auth.signInWithOAuth(
      switch (provider) {
        LoginProvider.kakao => OAuthProvider.kakao,
        LoginProvider.apple => OAuthProvider.apple,
        LoginProvider.google => OAuthProvider.google,
      },
      redirectTo: kIsWeb ? null : redirectTo,
      authScreenLaunchMode: kIsWeb
          ? LaunchMode.platformDefault
          : LaunchMode.externalApplication,
    );
    if (!launched) throw StateError(l10n.authOpenFailed);
  }

  @override
  Future<AuthIdentity> preview() async {
    if (!allowAnonymous) throw StateError(l10n.authAnonymousDisabled);
    if (identity?.development == true) return identity!;
    final result = await client.auth.signInAnonymously();
    final user = result.user;
    if (user == null) throw StateError(l10n.authPreviewFailed);
    return AuthIdentity(user.id, development: true);
  }

  /// The device session goes first; if only telling the server fails
  /// (offline, say), I'm still signed out here, so that's not an error.
  @override
  Future<void> signOut() async {
    try {
      await client.auth.signOut();
    } catch (_) {
      if (client.auth.currentSession != null) rethrow;
    }
  }
}

class UnavailableAuthService implements AuthService {
  @override
  AuthIdentity? get identity => null;
  @override
  Stream<AuthIdentity?> get changes => const Stream.empty();
  @override
  Future<void> signIn(LoginProvider provider) async =>
      throw StateError(l10n.authUnavailable);
  @override
  Future<AuthIdentity> preview() async =>
      const AuthIdentity('local-preview', development: true);
  @override
  Future<void> signOut() async {}
}
