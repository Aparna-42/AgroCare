import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as user_model;

class AuthProvider with ChangeNotifier {
  user_model.User? _user;
  bool _isAuthenticated = false;
  String? _errorMessage;

  user_model.User? get user => _user;
  bool get isAuthenticated => _isAuthenticated;
  String? get errorMessage => _errorMessage;

  final _supabase = Supabase.instance.client;

  Future<void> checkAuthStatus() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session != null) {
        _isAuthenticated = true;
        _user = user_model.User(
          id: session.user.id,
          name: session.user.userMetadata?['name'] ?? session.user.email?.split('@')[0] ?? 'User',
          email: session.user.email ?? '',
        );
      } else {
        _isAuthenticated = false;
        _user = null;
      }
    } catch (e) {
      print('Error checking auth status: $e');
      _isAuthenticated = false;
      _user = null;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    try {
      _errorMessage = null;
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Fetch user data from users table
        try {
          final userData = await _supabase
              .from('users')
              .select()
              .eq('id', response.user!.id)
              .single();
          
          _user = user_model.User(
            id: userData['id'] ?? response.user!.id,
            name: userData['name'] ?? email.split('@')[0],
            email: userData['email'] ?? response.user!.email ?? '',
          );
        } catch (dbError) {
          // If user not found in database, create local user object
          _user = user_model.User(
            id: response.user!.id,
            name: response.user!.userMetadata?['name'] ?? email.split('@')[0],
            email: response.user!.email ?? '',
          );
        }

        _isAuthenticated = true;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isAuthenticated = false;
      _user = null;
      notifyListeners();
      print('Login error: $e');
      return false;
    }
  }

  Future<bool> signup(String name, String email, String password) async {
    try {
      _errorMessage = null;
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );

      if (response.user != null) {
        // Save user data to users table
        try {
          await _supabase.from('users').insert({
            'id': response.user!.id,
            'name': name,
            'email': email,
          });
          print('✅ User saved to database successfully');
        } catch (dbError) {
          print('⚠️ Error saving user to database: $dbError');
          print('This might be due to RLS policies. The user auth is still successful.');
          // Don't fail the signup even if database save fails
          // The user will need to run the FIX_RLS_POLICIES.md SQL
        }

        _isAuthenticated = true;
        _user = user_model.User(
          id: response.user!.id,
          name: name,
          email: response.user!.email ?? '',
        );
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isAuthenticated = false;
      _user = null;
      notifyListeners();
      print('Signup error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
      _user = null;
      _isAuthenticated = false;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      print('Logout error: $e');
    }
    notifyListeners();
  }

  Future<bool> updateProfile({
    required String name,
    String? location,
    String? profileImageUrl,
  }) async {
    try {
      _errorMessage = null;
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        _errorMessage = 'User not authenticated';
        return false;
      }

      // Update users table
      try {
        await _supabase.from('users').update({
          'name': name,
          'location': location,
          'profile_image_url': profileImageUrl,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', userId);
      } catch (dbError) {
        print('⚠️ Error updating users table: $dbError');
        // Continue even if database update fails
      }

      // Update local user object
      _user = user_model.User(
        id: _user!.id,
        name: name,
        email: _user!.email,
      );

      print('✅ Profile updated successfully');
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      print('Error updating profile: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> changePassword(String newPassword) async {
    try {
      _errorMessage = null;
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      print('✅ Password changed successfully');
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      print('Error changing password: $e');
      notifyListeners();
      return false;
    }
  }
}
