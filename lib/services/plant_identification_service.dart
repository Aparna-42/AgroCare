import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PlantIdentificationService {
  // Plant.id API key - Get from https://plant.id
  static const String _plantIdApiKey = 'tr30Vft12ZDkK1YH8w6tZO7tmPSMchwacT21pRnnfQLIj8bgZ2';
  static const String _plantIdBaseUrl = 'https://api.plant.id/v2';

  /// Identify plant from image bytes (web-compatible)
  /// Returns plant details or null if identification fails
  static Future<Map<String, dynamic>?> identifyPlantFromBytes(
      Uint8List imageBytes) async {
    try {
      print('🔄 Starting plant identification from bytes...');

      final base64Image = base64Encode(imageBytes);

      // Prepare request to Plant.id API
      final url = Uri.parse('$_plantIdBaseUrl/identify');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'api_key': _plantIdApiKey,
          'images': [base64Image],
          'modifiers': ['similar_images'],
          'plant_details': [
            'watering',
            'sunlight',
            'propagation_methods',
            'common_names',
            'description'
          ]
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Plant identification request timed out');
        },
      );

      print('📊 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        print('✅ Plant identification successful');
        print('📋 Full API Response: $jsonResponse');
        print('📋 Response keys: ${jsonResponse.keys.toList()}');

        // Plant.id API response structure: suggestions array at root level
        if (jsonResponse['suggestions'] != null && 
            jsonResponse['suggestions'].isNotEmpty) {
          
          final suggestion = jsonResponse['suggestions'][0];
          print('🔍 Top suggestion: $suggestion');
          
          try {
            // Extract plant details safely
            final plantDetails = suggestion['plant_details'] ?? {};
            final plantName = suggestion['plant_name'] ?? 'Unknown Plant';
            final probability = (suggestion['probability'] ?? 0.0) * 100;
            final scientificName = plantDetails['scientific_name'] ?? plantDetails['common_names']?[0] ?? 'Unknown';
            
            // Parse watering info (max: 2, min: 1)
            String wateringInfo = 'Water regularly, check soil moisture';
            final watering = plantDetails['watering'];
            if (watering is Map) {
              final maxDays = watering['max'];
              final minDays = watering['min'];
              if (maxDays != null && minDays != null) {
                wateringInfo = 'Water every $minDays-$maxDays days';
              }
            }
            
            // Parse description
            final description = plantDetails['description'] is Map
                ? plantDetails['description']['value'] ?? 'Plant details available'
                : plantDetails['description'] ?? 'Plant details available';
            
            // Parse sunlight
            final sunlightInfo = _getSunlightValue(plantDetails['sunlight']);
            
            // Parse propagation
            final propagationInfo = _getPropagationValue(plantDetails['propagation_methods']);
            
            // Get similar images
            final similarImages = suggestion['similar_images'] ?? [];
            
            final plantData = {
              'plant_name': plantName,
              'scientific_name': scientificName,
              'confidence': probability,
              'description': description,
              'watering': wateringInfo,
              'sunlight': sunlightInfo,
              'propagation': propagationInfo,
              'similar_images': similarImages,
            };
            
            print('✅ Successfully parsed plant data: $plantData');
            return plantData;
          } catch (e) {
            print('⚠️ Error parsing suggestion: $e');
            print('📋 Suggestion data: $suggestion');
          }
        }
        
        // If we got here, parsing failed but response was 200
        print('⚠️ Could not parse valid plant data from API response');
        print('📋 Response keys: ${jsonResponse.keys.toList()}');
        
        // Return a fallback
        return {
          'plant_name': 'Plant (Identification unclear)',
          'scientific_name': 'Species unknown',
          'confidence': 50.0,
          'description': 'The Plant.id API could not identify this plant clearly. Try a different angle or clearer image.',
          'watering': 'Water regularly, check soil moisture',
          'sunlight': 'Most plants need 4-6 hours of light daily',
          'propagation': 'Propagation method varies by species',
          'similar_images': [],
        };
      } else {
        print(
            '❌ API Error: ${response.statusCode} - ${response.body}');
        throw Exception(
            'Failed to identify plant. Status: ${response.statusCode}');
      }

      return null;
    } catch (e) {
      print('❌ Error in identifyPlantFromBytes: $e');
      // Return a fallback response instead of failing completely
      print('⚠️ Returning fallback plant data');
      return {
        'plant_name': 'Unknown Plant',
        'scientific_name': 'Species unknown',
        'confidence': 0.0,
        'description': 'Could not identify this plant. Try a clearer image.',
        'watering': 'Water regularly, adjust based on soil moisture',
        'sunlight': 'Most plants need 4-6 hours of sunlight daily',
        'propagation': 'Propagation method unknown',
        'similar_images': [],
      };
    }
  }

  /// Identify plant from image file (for mobile/native platforms)
  /// Wrapper around identifyPlantFromBytes for File objects
  static Future<Map<String, dynamic>?> identifyPlant(File imageFile) async {
    try {
      print('🔄 Starting plant identification from file...');
      final bytes = await imageFile.readAsBytes();
      return await identifyPlantFromBytes(bytes);
    } catch (e) {
      print('❌ Error in identifyPlant: $e');
      rethrow;
    }
  }

  /// Get plant care information (fallback/additional data)
  static Future<Map<String, dynamic>?> getPlantCareInfo(
      String plantName) async {
    try {
      // This is a fallback method to get more detailed care information
      // You can use any plant care API or local data

      // Example: Using a local care database
      final careData = _getLocalPlantCareData(plantName);
      return careData;
    } catch (e) {
      print('❌ Error getting care info: $e');
      return null;
    }
  }

  /// Local plant care database
  /// Stores common care recommendations
  static Map<String, dynamic>? _getLocalPlantCareData(String plantName) {
    final plantCareDatabase = {
      'tomato': {
        'watering': 'Water deeply 2-3 times per week',
        'sunlight': '6-8 hours of direct sunlight daily',
        'temperature': '20-25°C optimal',
        'soil': 'Well-draining, fertile soil',
        'fertilizer': 'Monthly with balanced fertilizer',
        'pruning': 'Remove suckers for better growth'
      },
      'potatoes': {
        'watering': 'Keep soil consistently moist',
        'sunlight': '6-8 hours of sunlight',
        'temperature': '15-20°C optimal',
        'soil': 'Loose, well-draining soil',
        'fertilizer': 'Phosphorus-rich fertilizer',
        'spacing': '25-30cm apart'
      },
      'pepper': {
        'watering': 'Water regularly, allow soil to dry slightly',
        'sunlight': '8-10 hours of direct sunlight',
        'temperature': '21-29°C optimal',
        'soil': 'Well-draining soil with organic matter',
        'fertilizer': 'Balanced fertilizer every 2 weeks',
        'humidity': 'Prefers 70-80% humidity'
      },
      'rose': {
        'watering': 'Water at base, 2-3 times per week',
        'sunlight': '6 hours minimum direct sunlight',
        'temperature': '15-25°C optimal',
        'soil': 'Well-draining soil',
        'fertilizer': 'Rose-specific fertilizer monthly',
        'pruning': 'Prune dead flowers regularly'
      },
    };

    final key = plantName.toLowerCase().trim();
    for (final entry in plantCareDatabase.entries) {
      if (key.contains(entry.key) || entry.key.contains(key)) {
        return entry.value;
      }
    }

    // Return default care info if plant not found
    return {
      'watering': 'Water regularly, adjust based on weather',
      'sunlight': 'Most plants need 4-6 hours of sunlight',
      'temperature': '15-25°C is suitable for most plants',
      'soil': 'Use well-draining soil',
      'fertilizer': 'Apply fertilizer monthly during growing season',
      'humidity': 'Maintain moderate humidity'
    };
  }

  /// Extract sunlight value from nested API response
  static String _getSunlightValue(dynamic sunlightData) {
    try {
      if (sunlightData is List && sunlightData.isNotEmpty) {
        final firstItem = sunlightData[0];
        if (firstItem is Map && firstItem.containsKey('value')) {
          return firstItem['value'].toString();
        }
      }
    } catch (e) {
      print('Error extracting sunlight: $e');
    }
    return 'Not specified';
  }

  /// Extract propagation value from nested API response
  static String _getPropagationValue(dynamic propagationData) {
    try {
      if (propagationData is List && propagationData.isNotEmpty) {
        final firstItem = propagationData[0];
        if (firstItem is Map && firstItem.containsKey('value')) {
          return firstItem['value'].toString();
        }
      }
    } catch (e) {
      print('Error extracting propagation: $e');
    }
    return 'Not specified';
  }
}
