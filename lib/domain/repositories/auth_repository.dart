import '../entities/app_user.dart';

/// Contract for authentication operations.
abstract interface class AuthRepository {
  Stream<AppUser?> get authStateChanges;

  AppUser? get currentUser;

  Future<AppUser> signIn({
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<void> sendPasswordResetEmail(String email);

  Future<AppUser> refreshProfile();
}
