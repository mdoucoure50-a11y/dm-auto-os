import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/app_exception.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../domain/entities/app_user.dart';
import '../domain/entities/auth_state.dart';
import '../domain/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final repository = AuthRepositoryImpl();
  repository.listenToAuthChanges();
  ref.onDispose(repository.dispose);
  return repository;
});

final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
      return AuthController(ref.watch(authRepositoryProvider));
    });

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repository) : super(const AuthInitial());

  final AuthRepository _repository;

  Future<void> signIn({required String email, required String password}) async {
    state = const AuthLoading();
    try {
      final user = await _repository.signIn(email: email, password: password);
      state = AuthAuthenticated(user);
    } on AuthException catch (e) {
      state = AuthError(e.message);
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    state = const AuthUnauthenticated();
  }

  Future<void> resetPassword(String email) async {
    await _repository.sendPasswordResetEmail(email);
  }
}
