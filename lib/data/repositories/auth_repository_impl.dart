import 'dart:async';

import '../../core/errors/app_exception.dart';
import '../../core/permissions/user_role.dart';
import '../../core/utils/logger.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_profile_model.dart';
import '../services/supabase_auth_service.dart';
import '../services/supabase_database_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required SupabaseAuthService authService,
    required SupabaseDatabaseService databaseService,
  })  : _authService = authService,
        _databaseService = databaseService;

  final SupabaseAuthService _authService;
  final SupabaseDatabaseService _databaseService;

  final _authController = StreamController<AppUser?>.broadcast();
  AppUser? _cachedUser;

  @override
  Stream<AppUser?> get authStateChanges => _authController.stream;

  @override
  AppUser? get currentUser => _cachedUser;

  void _emit(AppUser? user) {
    _cachedUser = user;
    _authController.add(user);
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    if (!_authService.isAvailable) {
      return _demoSignIn(email);
    }

    final response = await _authService.signInWithPassword(
      email: email,
      password: password,
    );

    final user = response.user;
    if (user == null) {
      throw const AuthException('Sign in failed. Please try again.');
    }

    final profile = await _fetchProfile(user.id);
    final appUser = _mapToAppUser(profile);
    _emit(appUser);
    return appUser;
  }

  @override
  Future<void> signOut() async {
    if (_authService.isAvailable) {
      await _authService.signOut();
    }
    _emit(null);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _authService.resetPasswordForEmail(email);
  }

  @override
  Future<AppUser> refreshProfile() async {
    if (!_authService.isAvailable) {
      if (_cachedUser != null) return _cachedUser!;
      throw const AuthException('Not authenticated');
    }

    final session = _authService.currentSession;
    if (session == null) {
      throw const AuthException('Not authenticated');
    }

    final profile = await _fetchProfile(session.user.id);
    final appUser = _mapToAppUser(profile);
    _emit(appUser);
    return appUser;
  }

  Future<UserProfileModel> _fetchProfile(String userId) async {
    final data = await _databaseService.fetchById('profiles', userId);

    if (data == null) {
      throw const NotFoundException('User profile not found');
    }

    return UserProfileModel.fromJson(data);
  }

  AppUser _mapToAppUser(UserProfileModel profile) {
    if (!profile.isActive) {
      throw const AuthException('Your account has been deactivated');
    }

    return AppUser(
      id: profile.id,
      email: profile.email,
      fullName: profile.fullName,
      role: profile.role,
      phone: profile.phone,
      avatarUrl: profile.avatarUrl,
      isActive: profile.isActive,
    );
  }

  Future<AppUser> _demoSignIn(String email) async {
    AppLogger.info('Demo mode sign-in for: $email');
    await Future<void>.delayed(const Duration(milliseconds: 800));

    final isAdmin = email.toLowerCase().contains('admin');
    final user = AppUser(
      id: 'demo-user-id',
      email: email,
      fullName: isAdmin ? 'Demo Administrator' : 'Demo Employee',
      role: isAdmin ? UserRole.administrator : UserRole.employee,
      isActive: true,
    );

    _emit(user);
    return user;
  }

  void listenToAuthChanges() {
    if (!_authService.isAvailable) return;

    _authService.onAuthStateChange.listen((event) async {
      final session = event.session;
      if (session == null) {
        _emit(null);
        return;
      }

      try {
        final profile = await _fetchProfile(session.user.id);
        _emit(_mapToAppUser(profile));
      } catch (e) {
        AppLogger.error('Failed to load profile on auth change', e);
        _emit(null);
      }
    });
  }

  void dispose() {
    _authController.close();
  }
}
