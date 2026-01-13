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
        _isAuthenticated = true;
        _user = user_model.User(
          id: response.user!.id,
          name: response.user!.userMetadata?['name'] ?? email.split('@')[0],
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

  void updateProfile(user_model.User updatedUser) {
    _user = updatedUser;
    notifyListeners();
  }
}
