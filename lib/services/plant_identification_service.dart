import 'dart:io';  //read image files
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PlantIdentificationService {
  // Plant.id API
  // WARNING: Keep API key secure! Add to .env or environment variables
  // Get your API key from https://plant.id
  static const String _plantIdApiKey = String.fromEnvironment(
    'PLANT_ID_API_KEY',
    defaultValue: 'YOUR_PLANT_ID_API_KEY_HERE',
  );
  static const String _plantIdBaseUrl = 'https://plant.id/api/v3';

  /// Identify plant from image bytes (web-compatible)
  /// Returns plant details or null if identification fails
  static Future<Map<String, dynamic>?> identifyPlantFromBytes(
      Uint8List imageBytes) async {
    try {
      print('🔄 Starting plant identification with Plant.id...');
      print('📷 Image size: ${imageBytes.length} bytes');

      final base64Image = base64Encode(imageBytes);
      final url = Uri.parse('$_plantIdBaseUrl/identification');

      print('🌐 Sending request to Plant.id API...');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Api-Key': _plantIdApiKey,
        },
        body: jsonEncode({
          'images': ['data:image/jpeg;base64,$base64Image'],
          'similar_images': true,
          'classification_level': 'species',
        }),
      ).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          print('⏱️ Plant.id request timed out');
          throw Exception('Request timed out');
        },
      );

      print('📊 Plant.id Response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        print('✅ Plant.id API call successful');
        
        final result = jsonResponse['result'];
        
        if (result == null) {
          print('⚠️ No result in response');
          return _createFallbackResponse('API returned empty result');
        }
        
        // Check if it's a plant
        final isPlant = result['is_plant'];
        if (isPlant != null) {
          final isPlantBinary = isPlant['binary'] ?? false;
          final isPlantProbability = (isPlant['probability'] ?? 0.0) * 100;
          print('🌱 Is plant: $isPlantBinary (${isPlantProbability.toStringAsFixed(1)}%)');
          
          if (!isPlantBinary && isPlantProbability < 30) {
            print('⚠️ Not a plant detected');
            return {
              'plant_name': 'Unknown Plant',
              'scientific_name': 'Not a plant',
              'confidence': 0.0,
              'description': 'The image does not appear to be a plant.',
              'watering': 'Water regularly, adjust based on soil moisture',
              'sunlight': 'Most plants need 4-6 hours of sunlight daily',
              'temperature': 'Not specified',
              'propagation': 'Not applicable',
              'similar_images': [],
            };
          }
        }
        
        // Get classification
        if (result['classification'] != null) {
          final suggestions = result['classification']['suggestions'] as List?;
          print('📊 Number of suggestions: ${suggestions?.length ?? 0}');
          
          if (suggestions != null && suggestions.isNotEmpty) {
            final suggestion = suggestions[0];
            final plantName = suggestion['name'] ?? 'Unknown Plant';
            final probability = (suggestion['probability'] ?? 0.0) * 100;
            
            print('🌱 Identified: $plantName with ${probability.toStringAsFixed(1)}% confidence');
            
            final details = suggestion['details'] ?? {};
            final commonNames = details['common_names'] as List?;
            String displayName = plantName;
            if (commonNames != null && commonNames.isNotEmpty) {
              displayName = commonNames[0].toString();
            }
            
            return {
              'plant_name': displayName,
              'scientific_name': plantName,
              'confidence': probability,
              'description': 'Plant identified successfully',
              'watering': _getWateringInfo(displayName),
              'sunlight': _getSunlightInfo(displayName),
              'temperature': 'Not specified',
              'propagation': 'Propagation varies by species',
              'similar_images': suggestion['similar_images'] ?? [],
            };
          }
        }
        
        print('⚠️ No classifications found');
        return _createFallbackResponse('No classifications found');
        
      } else if (response.statusCode == 401) {
        print('❌ API authentication failed - check API key');
        return _createFallbackResponse('API authentication failed. Please check API key.');
      } else if (response.statusCode == 429) {
        print('❌ Rate limit exceeded - wait before trying again');
        return _createFallbackResponse('Rate limit exceeded. Your API key has reached its usage limit. Please wait a few minutes or upgrade your API plan.');
      } else {
        print('❌ API Error: ${response.statusCode}');
        final errorBody = response.body.length > 200 ? response.body.substring(0, 200) : response.body;
        print('Error details: $errorBody');
        return _createFallbackResponse('API error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Plant.id Error: $e');
      return _createFallbackResponse('Error: $e');
    }
  }
  
  /// Get watering info based on plant name
  static String _getWateringInfo(String plantName) {
    final name = plantName.toLowerCase();
    if (name.contains('cactus') || name.contains('succulent')) {
      return 'Water sparingly, once every 2-3 weeks';
    } else if (name.contains('fern') || name.contains('moss')) {
      return 'Keep soil consistently moist';
    } else if (name.contains('tomato') || name.contains('pepper')) {
      return 'Water deeply 2-3 times per week';
    }
    return 'Water regularly, adjust based on soil moisture';
  }
  
  /// Get sunlight info based on plant name
  static String _getSunlightInfo(String plantName) {
    final name = plantName.toLowerCase();
    if (name.contains('fern') || name.contains('moss')) {
      return 'Prefers indirect light or shade';
    } else if (name.contains('tomato') || name.contains('pepper') || name.contains('rose')) {
      return '6-8 hours of direct sunlight daily';
    }
    return 'Most plants need 4-6 hours of sunlight daily';
  }
  
  /// Create a fallback response with error info
  static Map<String, dynamic> _createFallbackResponse(String reason) {
    print('⚠️ Creating fallback response: $reason');
    return {
      'plant_name': 'Unknown Plant',
      'scientific_name': 'Species unknown',
      'confidence': 0.0,
      'description': 'Could not identify this plant. $reason',
      'watering': 'Water regularly, adjust based on soil moisture',
      'sunlight': 'Most plants need 4-6 hours of sunlight daily',
      'temperature': 'Not specified',
      'propagation': 'Propagation method unknown',
      'similar_images': [],
    };
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
