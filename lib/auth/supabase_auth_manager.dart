import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fittravel/auth/auth_manager.dart';
import 'package:fittravel/models/user_model.dart' as app;
import 'package:fittravel/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase implementation of AuthManager with email/password authentication
class SupabaseAuthManager extends AuthManager with EmailSignInManager {
  final _authStateController = StreamController<app.UserModel?>.broadcast();

  SupabaseAuthManager() {
    // Listen to Supabase auth state changes and convert to UserModel
    SupabaseConfig.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      if (session?.user != null) {
        // Try to resolve full user; fall back to basic model if profile missing
        final authUser = session!.user;
        app.UserModel? user;
        try {
          user = await _getUserModelFromAuth(authUser);
          if (user == null) {
            // Attempt to create a profile on-the-fly if missing
            await _createUserProfile(authUser);
            user = await _getUserModelFromAuth(authUser);
          }
        } catch (e) {
          debugPrint('AuthStateChange user load error: $e');
        }
        _authStateController.add(user ?? _convertAuthUserToUserModel(authUser));
      } else {
        _authStateController.add(null);
      }
    });
  }

  @override
  Stream<app.UserModel?> get authStateChanges => _authStateController.stream;

  @override
  app.UserModel? get currentUser {
    final authUser = SupabaseConfig.auth.currentUser;
    return authUser != null ? _convertAuthUserToUserModel(authUser) : null;
  }

  /// Sign in with email and password
  @override
  Future<app.UserModel?> signInWithEmail(
    BuildContext context,
    String email,
    String password,
  ) async {
    try {
      final response = await SupabaseConfig.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        final authUser = response.user!;
        // Try to fetch profile; create if missing; never return null on success
        try {
          var user = await _getUserModelFromAuth(authUser);
          if (user == null) {
            debugPrint('No user profile found; creating profile for ${authUser.id}');
            await _createUserProfile(authUser);
            user = await _getUserModelFromAuth(authUser);
          }
          return user ?? _convertAuthUserToUserModel(authUser);
        } catch (e) {
          debugPrint('Post sign-in profile fetch error: $e');
          return _convertAuthUserToUserModel(authUser);
        }
      }
      return null;
    } on AuthException catch (e) {
      debugPrint('Supabase sign in error: ${e.message}');
      if (context.mounted) {
        _showErrorSnackBar(context, e.message);
      }
      return null;
    } catch (e) {
      debugPrint('Unexpected sign in error: $e');
      if (context.mounted) {
        _showErrorSnackBar(context, 'An unexpected error occurred');
      }
      return null;
    }
  }

  /// Create account with email and password
  @override
  Future<app.UserModel?> createAccountWithEmail(
    BuildContext context,
    String email,
    String password,
  ) async {
    try {
      final response = await SupabaseConfig.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Create user profile in users table
        await _createUserProfile(response.user!);
        return await _getUserModelFromAuth(response.user!);
      }
      return null;
    } on AuthException catch (e) {
      debugPrint('Supabase sign up error: ${e.message}');
      if (context.mounted) {
        _showErrorSnackBar(context, e.message);
      }
      return null;
    } catch (e) {
      debugPrint('Unexpected sign up error: $e');
      if (context.mounted) {
        _showErrorSnackBar(context, 'An unexpected error occurred');
      }
      return null;
    }
  }

  /// Sign out
  @override
  Future<void> signOut() async {
    try {
      await SupabaseConfig.auth.signOut();
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
  }

  /// Delete user account
  @override
  Future<void> deleteUser(BuildContext context) async {
    try {
      final user = SupabaseConfig.auth.currentUser;
      if (user != null) {
        // Delete user profile from users table (cascade will handle related data)
        await SupabaseService.delete('users', filters: {'id': user.id});
        
        // Delete auth user
        await SupabaseConfig.client.rpc('delete_user');
      }
    } catch (e) {
      debugPrint('Delete user error: $e');
      if (context.mounted) {
        _showErrorSnackBar(context, 'Failed to delete account');
      }
    }
  }

  /// Update email
  @override
  Future<void> updateEmail({
    required String email,
    required BuildContext context,
  }) async {
    try {
      await SupabaseConfig.auth.updateUser(UserAttributes(email: email));
      
      // Update email in users table
      final user = SupabaseConfig.auth.currentUser;
      if (user != null) {
        await SupabaseService.update(
          'users',
          {'email': email, 'updated_at': DateTime.now().toIso8601String()},
          filters: {'id': user.id},
        );
      }
      
      if (context.mounted) {
        _showSuccessSnackBar(context, 'Email updated successfully');
      }
    } on AuthException catch (e) {
      debugPrint('Update email error: ${e.message}');
      if (context.mounted) {
        _showErrorSnackBar(context, e.message);
      }
    } catch (e) {
      debugPrint('Unexpected update email error: $e');
      if (context.mounted) {
        _showErrorSnackBar(context, 'Failed to update email');
      }
    }
  }

  /// Reset password
  @override
  Future<void> resetPassword({
    required String email,
    required BuildContext context,
  }) async {
    try {
      await SupabaseConfig.auth.resetPasswordForEmail(email);
      if (context.mounted) {
        _showSuccessSnackBar(
          context,
          'Password reset email sent. Please check your inbox.',
        );
      }
    } on AuthException catch (e) {
      debugPrint('Reset password error: ${e.message}');
      if (context.mounted) {
        _showErrorSnackBar(context, e.message);
      }
    } catch (e) {
      debugPrint('Unexpected reset password error: $e');
      if (context.mounted) {
        _showErrorSnackBar(context, 'Failed to send reset email');
      }
    }
  }

  /// Create user profile in users table
  Future<void> _createUserProfile(User authUser) async {
    try {
      await SupabaseService.insert('users', {
        'id': authUser.id,
        'email': authUser.email,
        'display_name': authUser.email?.split('@').first ?? 'User',
        'fitness_level': 'beginner',
        'dietary_preferences': [],
        'current_streak': 0,
        'longest_streak': 0,
        'total_xp': 0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error creating user profile: $e');
    }
  }

  /// Get UserModel from auth User (queries users table)
  Future<app.UserModel?> _getUserModelFromAuth(User authUser) async {
    try {
      final userData = await SupabaseService.selectSingle(
        'users',
        filters: {'id': authUser.id},
      );

      if (userData != null) {
        // Map snake_case columns from Supabase to our app model
        return app.UserModel.fromSupabaseJson(userData);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching user model: $e');
      return null;
    }
  }

  /// Convert auth User to UserModel (without DB query - basic info only)
  app.UserModel _convertAuthUserToUserModel(User authUser) {
    return app.UserModel(
      id: authUser.id,
      email: authUser.email,
      displayName: authUser.email?.split('@').first ?? 'User',
      fitnessLevel: app.FitnessLevel.beginner,
      dietaryPreferences: const [],
      currentStreak: 0,
      longestStreak: 0,
      totalXp: 0,
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void dispose() {
    _authStateController.close();
  }
}
