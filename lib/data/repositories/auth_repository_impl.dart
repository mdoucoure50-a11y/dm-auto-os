import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../../core/errors/app_exception.dart';
import '../../core/permissions/user_role.dart';
import '../../core/utils/logger.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/supabase_service.dart';
import '../models/user_profile_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl();

  final _authController = StreamController<AppUser?>.broadcast();
  AppUser? _cachedUser;

  @override
  Stream<AppUser?> get authStateChanges => _authController.stream;

  @override
  AppUser? get currentUser => _cachedUser;

  GoTrueClient? get _auth {
    if (!SupabaseService.isInitialized) return null;
    try {
      return SupabaseService.auth;
    } catch (_) {
      return null;
    }
  }

  void _emit(AppUser? user) {
    _cachedUser = user;
    _authController.add(user);
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final auth = _auth;
    if (auth == null) {
      return _demoSignIn(email);
    }

    return SupabaseService.execute(() async {
      final response = await auth.signInWithPassword(
        email: email.trim(),
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
    }, errorMessage: 'Unable to sign in');
  }

  @override
  Future<void> signOut() async {
    final auth = _auth;
    if (auth != null) {
      await auth.signOut();
    }
    _emit(null);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    final auth = _auth;
    if (auth == null) {
      throw const NetworkException(
        'Password reset requires Supabase configuration',
      );
    }

    await SupabaseService.execute(
      () => auth.resetPasswordForEmail(email.trim()),
      errorMessage: 'Unable to send reset email',
    );
  }

  @override
  Future<AppUser> refreshProfile() async {
    final auth = _auth;
    if (auth == null) {
      if (_cachedUser != null) return _cachedUser!;
      throw const AuthException('Not authenticated');
    }

    final session = auth.currentSession;
    if (session == null) {
      throw const AuthException('Not authenticated');
    }

    final profile = await _fetchProfile(session.user.id);
    final appUser = _mapToAppUser(profile);
    _emit(appUser);
    return appUser;
  }

  Future<UserProfileModel> _fetchProfile(String userId) async {
    final data = await SupabaseService.table('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

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

  /// Demo mode sign-in when Supabase is not configured.
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
    final auth = _auth;
    if (auth == null) return;

    auth.onAuthStateChange.listen((event) async {
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
