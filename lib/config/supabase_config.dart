import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // Replace with your Supabase credentials from Settings > API
  static const String supabaseUrl = 'https://uasqfoyqkrstkbfqphgd.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_Xgeaa7Pavk1CrSLlWkRXfA_Pl1gX_i1';

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
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
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
