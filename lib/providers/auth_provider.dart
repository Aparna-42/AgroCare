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
            location: userData['location'],
            profileImage: userData['profile_image_url'],
          );
          print('✅ Loaded user with location: ${_user!.location}');
        } catch (dbError) {
          // If user not found in database, create local user object
          _user = user_model.User(
            id: response.user!.id,
            name: response.user!.userMetadata?['name'] ?? email.split('@')[0],
            email: response.user!.email ?? '',
          );
          print('⚠️ No user in database, created local user');
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
        print('❌ Error: User not authenticated');
        return false;
      }

      print('🔄 Updating profile for user: $userId');
      print('   Name: $name, Location: $location');

      // Only update with non-null values to minimize RLS issues
      final updateData = {
        'id': userId,
        'name': name,
        'email': _supabase.auth.currentUser?.email ?? '',
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      if (location != null && location.isNotEmpty) {
        updateData['location'] = location;
      }
      
      if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
        updateData['profile_image_url'] = profileImageUrl;
      }

      print('📤 Attempting update with data: $updateData');

      try {
        // Try UPDATE first (if user already exists)
        final updateResponse = await _supabase
            .from('users')
            .update(updateData)
            .eq('id', userId)
            .select();
        
        print('✅ UPDATE successful: $updateResponse');
        
        // If update returned nothing, try upsert
        if (updateResponse.isEmpty) {
          print('⚠️ UPDATE returned empty, trying upsert...');
          final upsertResponse = await _supabase
              .from('users')
              .upsert(updateData, onConflict: 'id')
              .select();
          print('✅ UPSERT successful: $upsertResponse');
        }
      } catch (dbError) {
        print('⚠️ UPDATE failed: $dbError, trying simple update without select...');
        // Try without select() in case that's causing issues
        await _supabase
            .from('users')
            .update({
              'name': name,
              'updated_at': DateTime.now().toIso8601String(),
              if (location != null && location.isNotEmpty) 'location': location,
              if (profileImageUrl != null && profileImageUrl.isNotEmpty) 'profile_image_url': profileImageUrl,
            })
            .eq('id', userId);
        print('✅ Simple UPDATE successful');
      }

      // Update local user object with all changes
      _user = user_model.User(
        id: _user!.id,
        name: name,
        email: _user!.email,
        location: location ?? _user!.location,
        profileImage: profileImageUrl ?? _user!.profileImage,
      );

      print('✅ Profile updated successfully');
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      print('❌ Error updating profile: $e');
      print('   Type: ${e.runtimeType}');
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
