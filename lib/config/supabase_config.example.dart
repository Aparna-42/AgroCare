import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // Get these from your Supabase dashboard at https://app.supabase.com
  // Go to Settings > API for your project
  // For security, use environment variables or create a supabase_config.dart with actual values
  
  // TODO: Replace with your actual Supabase credentials
  // Create lib/config/supabase_config.dart with your real credentials
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://YOUR_PROJECT.supabase.co',
  );
  
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'YOUR_ANON_KEY_HERE',
  );

  // Storage bucket names
  static const String plantImagesBucket = 'plant-images';
  static const String profilePicturesBucket = 'profile-pictures';
  static const String diseaseReportsBucket = 'disease-reports';

  // Table names
  static const String usersTable = 'users';
  static const String plantsTable = 'plants';
  static const String tasksTable = 'maintenance_tasks';
  static const String weatherTable = 'weather_data';

  // Initialize Supabase (call this in main.dart before runApp)
  static Future<void> initialize() async {
    // Validation for clearer errors during development
    if (supabaseUrl.isEmpty ||
        supabaseUrl == 'https://YOUR_PROJECT.supabase.co' ||
        supabaseAnonKey.isEmpty ||
        supabaseAnonKey == 'YOUR_ANON_KEY_HERE') {
      throw Exception(
        'Supabase credentials are not configured. '
        'Set SUPABASE_URL and SUPABASE_ANON_KEY environment variables, '
        'or create lib/config/supabase_config.dart with your credentials.',
      );
    }

    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }

  // Get Supabase client
  static SupabaseClient get client => Supabase.instance.client;

  // Get authenticated user
  static User? get currentUser => client.auth.currentUser;

  // Get user ID
  static String? get userId => currentUser?.id;

  // Check if user is authenticated
  static bool get isAuthenticated => currentUser != null;
}
