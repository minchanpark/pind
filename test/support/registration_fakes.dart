import 'dart:async';

import 'package:pind_flutter/model/registration_model.dart';
import 'package:pind_flutter/services/auth_service.dart';

class FakeAuthService implements AuthService {
  FakeAuthService({AuthIdentity? initial}) : _identity = initial;
  AuthIdentity? _identity;
  final _events = StreamController<AuthIdentity?>.broadcast(sync: true);
  Future<void> Function(LoginProvider)? onSignIn;
  @override
  AuthIdentity? get identity => _identity;
  @override
  Stream<AuthIdentity?> get changes => _events.stream;
  void emit(AuthIdentity? identity) {
    _identity = identity;
    _events.add(identity);
  }

  @override
  Future<void> signIn(LoginProvider provider) async {
    await onSignIn?.call(provider);
  }

  @override
  Future<AuthIdentity> preview() async =>
      const AuthIdentity('preview-user', development: true);
  Future<void> close() => _events.close();
}
