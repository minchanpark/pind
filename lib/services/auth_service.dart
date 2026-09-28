import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/registration_model.dart';

abstract interface class AuthService {
  AuthIdentity? get identity;
  Stream<AuthIdentity?> get changes;
  Future<void> signIn(LoginProvider provider);
  Future<AuthIdentity> preview();
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
    if (!launched) throw StateError('로그인 창을 열지 못했어요. 다시 시도해 주세요.');
  }

  @override
  Future<AuthIdentity> preview() async {
    if (!allowAnonymous) throw StateError('개발용 익명 인증이 허용되지 않았어요.');
    if (identity?.development == true) return identity!;
    final result = await client.auth.signInAnonymously();
    final user = result.user;
    if (user == null) throw StateError('체험을 시작하지 못했어요.');
    return AuthIdentity(user.id, development: true);
  }
}

class UnavailableAuthService implements AuthService {
  @override
  AuthIdentity? get identity => null;
  @override
  Stream<AuthIdentity?> get changes => const Stream.empty();
  @override
  Future<void> signIn(LoginProvider provider) async =>
      throw StateError('로그인에 연결하지 못했어요. 잠시 후 다시 시도해 주세요.');
  @override
  Future<AuthIdentity> preview() async =>
      const AuthIdentity('local-preview', development: true);
}
