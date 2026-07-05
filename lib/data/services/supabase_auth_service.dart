import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import 'supabase_client_service.dart';

/// Supabase Authentication service (GoTrue).
class SupabaseAuthService {
  SupabaseAuthService(this._clientService);

  final SupabaseClientService _clientService;

  bool get isAvailable => _clientService.isConnected;

  supa.GoTrueClient? get _auth {
    if (!_clientService.isConnected) return null;
    return _clientService.client.auth;
  }

  supa.User? get currentUser => _auth?.currentUser;

  supa.Session? get currentSession => _auth?.currentSession;

  Stream<supa.AuthState> get onAuthStateChange {
    final auth = _auth;
    if (auth == null) return const Stream.empty();
    return auth.onAuthStateChange;
  }

  Future<supa.AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final auth = _auth;
    if (auth == null) {
      throw const NetworkException('Authentication requires Supabase connection');
    }

    return _execute(
      () => auth.signInWithPassword(
        email: email.trim(),
        password: password,
      ),
      errorMessage: 'Unable to sign in',
    );
  }

  Future<void> signOut() async {
    final auth = _auth;
    if (auth == null) return;
    await _execute(() => auth.signOut(), errorMessage: 'Unable to sign out');
  }

  Future<void> resetPasswordForEmail(String email) async {
    final auth = _auth;
    if (auth == null) {
      throw const NetworkException(
        'Password reset requires Supabase connection',
      );
    }

    await _execute(
      () => auth.resetPasswordForEmail(email.trim()),
      errorMessage: 'Unable to send reset email',
    );
  }

  Future<T> _execute<T>(
    Future<T> Function() operation, {
    String? errorMessage,
  }) async {
    try {
      return await operation().timeout(AppConstants.networkTimeout);
    } on supa.AuthException catch (e) {
      throw AuthException(e.message, code: e.code);
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException(errorMessage ?? e.toString());
    }
  }
}
