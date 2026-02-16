import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/treatment.dart';

/// Service for fetching treatment data from Supabase
class TreatmentService {
  static final _supabase = Supabase.instance.client;

  /// Get treatment suggestions for a specific plant and disease
  /// 
  /// Parameters:
  /// - plantName: Name of the plant (e.g., 'Tomato', 'Apple')
  /// - diseaseName: Name of the disease (e.g., 'Early_blight', 'Black_rot')
  /// 
  /// Returns Treatment object or null if not found
  static Future<Treatment?> getTreatment(String plantName, String diseaseName) async {
    try {
      print('🔍 Fetching treatment for: $plantName - $diseaseName');

      final response = await _supabase
          .from('treatment')
          .select()
          .eq('plant_name', plantName)
          .eq('disease_name', diseaseName)
          .maybeSingle();

      if (response == null) {
        print('⚠️ No treatment found for: $plantName - $diseaseName');
        return null;
      }

      print('✅ Treatment found for: $plantName - $diseaseName');
      return Treatment.fromJson(response);
    } catch (e) {
      print('❌ Error fetching treatment: $e');
      return null;
    }
  }

  /// Get all treatments for a specific plant
  /// 
  /// Returns list of Treatment objects
  static Future<List<Treatment>> getTreatmentsByPlant(String plantName) async {
    try {
      print('🔍 Fetching all treatments for: $plantName');

      final response = await _supabase
          .from('treatment')
          .select()
          .eq('plant_name', plantName);

      final treatments = (response as List)
          .map((item) => Treatment.fromJson(item))
          .toList();

      print('✅ Found ${treatments.length} treatments for: $plantName');
      return treatments;
    } catch (e) {
      print('❌ Error fetching treatments: $e');
      return [];
    }
  }

  /// Get all treatments for a specific disease (across all plants)
  /// 
  /// Returns list of Treatment objects
  static Future<List<Treatment>> getTreatmentsByDisease(String diseaseName) async {
    try {
      print('🔍 Fetching all treatments for disease: $diseaseName');

      final response = await _supabase
          .from('treatment')
          .select()
          .eq('disease_name', diseaseName);

      final treatments = (response as List)
          .map((item) => Treatment.fromJson(item))
          .toList();

      print('✅ Found ${treatments.length} treatments for disease: $diseaseName');
      return treatments;
    } catch (e) {
      print('❌ Error fetching treatments: $e');
      return [];
    }
  }

  /// Get all treatments from database
  /// 
  /// Returns list of all Treatment objects
  static Future<List<Treatment>> getAllTreatments() async {
    try {
      print('🔍 Fetching all treatments from database');

      final response = await _supabase
          .from('treatment')
          .select();

      final treatments = (response as List)
          .map((item) => Treatment.fromJson(item))
          .toList();

      print('✅ Found ${treatments.length} total treatments');
      return treatments;
    } catch (e) {
      print('❌ Error fetching all treatments: $e');
      return [];
    }
  }

  /// Get treatment suggestions as string list (convenience method)
  /// 
  /// Returns treatment suggestions or generic fallback
  static Future<List<String>> getTreatmentSuggestions(
    String plantName,
    String diseaseName,
  ) async {
    final treatment = await getTreatment(plantName, diseaseName);
    
    if (treatment != null && treatment.treatmentSuggestions.isNotEmpty) {
      return treatment.treatmentSuggestions;
    }

    // Return generic fallback if no specific treatment found
    return [
      'Remove affected plant parts immediately',
      'Apply appropriate fungicide or pesticide',
      'Improve air circulation around plants',
      'Avoid overhead watering',
      'Sanitize gardening tools',
      'Consult with a local agricultural expert',
    ];
  }
}
