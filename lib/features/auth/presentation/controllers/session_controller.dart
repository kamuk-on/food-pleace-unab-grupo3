// ignore_for_file: prefer_initializing_formals

import 'package:flutter/material.dart';

import '../../../../core/network/api_exception.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/auth_use_cases.dart';

class SessionController extends ChangeNotifier {
  SessionController({
    required SignInUseCase signInUseCase,
    required SignOutUseCase signOutUseCase,
    required RestoreSessionUseCase restoreSessionUseCase,
  }) : _signInUseCase = signInUseCase,
       _signOutUseCase = signOutUseCase,
       _restoreSessionUseCase = restoreSessionUseCase;

  final SignInUseCase _signInUseCase;
  final SignOutUseCase _signOutUseCase;
  final RestoreSessionUseCase _restoreSessionUseCase;

  AuthSession? _session;
  String? _lastErrorMessage;

  bool get isAuthenticated => _session != null;
  String? get email => _session?.email;
  String? get authToken => _session?.token;
  User? get currentUser => _session?.user;
  String? get displayName => _session?.user.name;
  String? get lastErrorMessage => _lastErrorMessage;

  /// Carga la sesion persistida al iniciar la app.
  Future<void> restore() async {
    _session = await _restoreSessionUseCase();
    _lastErrorMessage = null;
    if (_session != null) {
      notifyListeners();
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    if (email.trim().isEmpty || password.trim().isEmpty) {
      _lastErrorMessage = 'Email y contrasena son requeridos';
      return false;
    }

    try {
      _session = await _signInUseCase(email: email.trim(), password: password);
      _lastErrorMessage = null;
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      _lastErrorMessage = error.message;
      return false;
    } catch (_) {
      _lastErrorMessage = 'No fue posible iniciar sesion';
      return false;
    }
  }

  Future<void> signOut() async {
    await _signOutUseCase();
    _session = null;
    _lastErrorMessage = null;
    notifyListeners();
  }

  void updateCurrentUser(User user) {
    final AuthSession? session = _session;
    if (session == null) {
      return;
    }

    _session = session.copyWith(user: user);
    _lastErrorMessage = null;
    notifyListeners();
  }
}
