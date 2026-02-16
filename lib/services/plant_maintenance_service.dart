import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/plant.dart';
import '../models/plant_maintenance.dart';
import '../models/weather_data.dart';
import '../providers/weather_provider.dart';
import '../providers/auth_provider.dart';
import 'weather_service.dart';

/// Enum representing alert types for weather comparison
enum AlertType {
  optimal,
  tempHigh,
  tempLow,
  humidityHigh,
  humidityLow,
  windHigh,
}

/// Enum representing alert severity levels
enum AlertSeverity {
  success,
  info,
  warning,
  critical,
}

/// Model class for weather alerts
/// 
/// Contains information about weather conditions that may affect plant health.
class WeatherAlert {
  final AlertType type;
  final AlertSeverity severity;
  final String title;
  final String message;
  final String recommendation;

  WeatherAlert({
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    required this.recommendation,
  });

  /// Get color associated with alert severity
  String get colorHex {
    switch (severity) {
      case AlertSeverity.success:
        return '#4CAF50'; // Green
      case AlertSeverity.info:
        return '#2196F3'; // Blue
      case AlertSeverity.warning:
        return '#FF9800'; // Orange
      case AlertSeverity.critical:
        return '#F44336'; // Red
    }
  }

  /// Get icon name for alert type
  String get iconName {
    switch (type) {
      case AlertType.optimal:
        return 'check_circle';
      case AlertType.tempHigh:
        return 'thermostat';
      case AlertType.tempLow:
        return 'ac_unit';
      case AlertType.humidityHigh:
        return 'water_drop';
      case AlertType.humidityLow:
        return 'water_drop_outlined';
      case AlertType.windHigh:
        return 'air';
    }
  }
}

class PlantMaintenanceService {
  // Supabase client instance for plant_maintenance table queries
  static final _supabase = Supabase.instance.client;

  // Groq API key for AI plant care recommendations
  // Get free API key from: https://console.groq.com
  // TODO: Store API key securely in environment variables
  static const String _groqApiKey = 'YOUR_GROQ_API_KEY_HERE';
  static const String _groqBaseUrl = 'https://api.groq.com/openai/v1';

  /// Get current weather data from user's location
  /// 
  /// This method fetches real weather data from the user's saved location
  /// or defaults to a fallback location if none is available.
  static Future<WeatherData?> getCurrentWeather(BuildContext context) async {
    try {
      final authProvider = context.read<AuthProvider>();
      final weatherProvider = context.read<WeatherProvider>();

      // Try to get from WeatherProvider first
      if (weatherProvider.currentWeather != null) {
        print('✅ Using cached weather data from provider');
        return weatherProvider.currentWeather!;
      }

      // Get user location or use default
      final userLocation = authProvider.user?.location ?? 'London';
      print('🌍 Fetching weather for user location: $userLocation');

      // Fetch fresh weather data
      final weatherData = await WeatherService.getWeatherByCity(userLocation);
      
      // Update weather provider with fresh data
      await weatherProvider.fetchWeatherByCity(userLocation);
      
      print('✅ Fresh weather data fetched for: $userLocation');
      return weatherData;
    } catch (e) {
      print('❌ Error getting current weather: $e');
      // Return demo weather as fallback
      return _getDemoWeatherData();
    }
  }

  /// Get current weather without context dependency
  /// 
  /// This method fetches weather data using a location string.
  /// Used when context is not available.
  static Future<WeatherData?> getCurrentWeatherByLocation(String location) async {
    try {
      print('🌍 Fetching weather for location: $location');
      final weatherData = await WeatherService.getWeatherByCity(location);
      print('✅ Weather data fetched for: $location');
      return weatherData;
    } catch (e) {
      print('❌ Error getting weather by location: $e');
      return _getDemoWeatherData();
    }
  }

  /// Generate demo weather data as fallback
  static WeatherData _getDemoWeatherData() {
    final now = DateTime.now();
    return WeatherData(
      temperature: 28.0,
      humidity: 65.0,
      rainfall: 0.0,
      condition: 'Partly Cloudy',
      windSpeed: 12.0,
      timestamp: now,
      cityName: 'Demo Location',
      description: 'partly cloudy',
      feelsLike: 30.0,
      pressure: 1013,
      visibility: 10000,
      icon: '02d',
    );
  }

  // ============================================================
  // SUPABASE PLANT MAINTENANCE DATABASE METHODS
  // ============================================================

  /// Fetch plant maintenance data by scientific name
  /// 
  /// Performs a case-insensitive search on the scientific_name column.
  /// Returns null if no matching plant is found.
  static Future<PlantMaintenance?> getPlantMaintenanceByScientificName(String scientificName) async {
    try {
      print('🔍 Fetching maintenance data for: $scientificName');

      final response = await _supabase
          .from('plant_maintenance')
          .select()
          .ilike('scientific_name', '%$scientificName%')
          .limit(1)
          .maybeSingle();

      if (response == null) {
        print('⚠️ No maintenance data found for: $scientificName');
        return null;
      }

      print('✅ Maintenance data found for: $scientificName');
      return PlantMaintenance.fromJson(response);
    } catch (e) {
      print('❌ Error fetching plant maintenance: $e');
      return null;
    }
  }

  /// Fetch plant maintenance data by common name
  /// 
  /// Performs a case-insensitive search on the common_name column.
  /// Returns null if no matching plant is found.
  static Future<PlantMaintenance?> getPlantMaintenanceByCommonName(String commonName) async {
    try {
      print('🔍 Fetching maintenance data for common name: $commonName');

      final response = await _supabase
          .from('plant_maintenance')
          .select()
          .ilike('common_name', '%$commonName%')
          .limit(1)
          .maybeSingle();

      if (response == null) {
        print('⚠️ No maintenance data found for: $commonName');
        return null;
      }

      print('✅ Maintenance data found for: $commonName');
      return PlantMaintenance.fromJson(response);
    } catch (e) {
      print('❌ Error fetching plant maintenance by common name: $e');
      return null;
    }
  }

  /// Search plants by name (both scientific and common names)
  /// 
  /// Returns a list of matching plants for autocomplete functionality.
  /// Limited to 10 results for performance.
  static Future<List<PlantMaintenance>> searchPlants(String query) async {
    try {
      if (query.isEmpty) return [];

      print('🔍 Searching plants with query: $query');

      final response = await _supabase
          .from('plant_maintenance')
          .select()
          .or('scientific_name.ilike.%$query%,common_name.ilike.%$query%')
          .limit(10);

      final plants = (response as List)
          .map((item) => PlantMaintenance.fromJson(item))
          .toList();

      print('✅ Found ${plants.length} plants matching: $query');
      return plants;
    } catch (e) {
      print('❌ Error searching plants: $e');
      return [];
    }
  }

  /// Get all plants from the maintenance database
  /// 
  /// Returns a list of all available plants.
  /// Use with caution for large datasets - consider pagination.
  static Future<List<PlantMaintenance>> getAllPlants() async {
    try {
      print('🔍 Fetching all plants from maintenance database');

      final response = await _supabase
          .from('plant_maintenance')
          .select()
          .order('common_name', ascending: true);

      final plants = (response as List)
          .map((item) => PlantMaintenance.fromJson(item))
          .toList();

      print('✅ Fetched ${plants.length} plants');
      return plants;
    } catch (e) {
      print('❌ Error fetching all plants: $e');
      return [];
    }
  }

  /// Compare current weather conditions with plant requirements
  /// 
  /// Returns a list of weather alerts based on the comparison.
  /// Alerts include temperature, humidity, and wind warnings.
  static List<WeatherAlert> compareWithWeather(
    PlantMaintenance maintenance,
    WeatherData weather,
  ) {
    final alerts = <WeatherAlert>[];

    // Temperature checks
    if (weather.temperature > maintenance.maxTempC) {
      alerts.add(WeatherAlert(
        type: AlertType.tempHigh,
        severity: AlertSeverity.warning,
        title: 'Temperature too high',
        message: 'Current: ${weather.temperature.toStringAsFixed(1)}°C, '
            'Max recommended: ${maintenance.maxTempC}°C',
        recommendation: 'Move plant to a cooler location or provide shade. '
            'Increase watering frequency to compensate for heat stress.',
      ));
    } else if (weather.temperature < maintenance.minTempC) {
      alerts.add(WeatherAlert(
        type: AlertType.tempLow,
        severity: AlertSeverity.critical,
        title: 'Temperature too low',
        message: 'Current: ${weather.temperature.toStringAsFixed(1)}°C, '
            'Min recommended: ${maintenance.minTempC}°C',
        recommendation: 'Move plant indoors or provide frost protection. '
            'Consider using row covers or mulch for insulation.',
      ));
    }

    // Humidity checks
    if (weather.humidity > maintenance.maxHumidity) {
      alerts.add(WeatherAlert(
        type: AlertType.humidityHigh,
        severity: AlertSeverity.info,
        title: 'High humidity',
        message: 'Current: ${weather.humidity.toStringAsFixed(0)}%, '
            'Max recommended: ${maintenance.maxHumidity.toInt()}%',
        recommendation: 'Ensure good air circulation to prevent fungal diseases. '
            'Reduce watering frequency.',
      ));
    } else if (weather.humidity < maintenance.minHumidity) {
      alerts.add(WeatherAlert(
        type: AlertType.humidityLow,
        severity: AlertSeverity.warning,
        title: 'Low humidity - increase watering',
        message: 'Current: ${weather.humidity.toStringAsFixed(0)}%, '
            'Min recommended: ${maintenance.minHumidity.toInt()}%',
        recommendation: 'Increase watering frequency. Consider misting the leaves '
            'or using a humidity tray.',
      ));
    }

    // Wind speed check
    if (weather.windSpeed > maintenance.maxWindSpeedKmph) {
      alerts.add(WeatherAlert(
        type: AlertType.windHigh,
        severity: AlertSeverity.warning,
        title: 'High wind speed',
        message: 'Current: ${weather.windSpeed.toStringAsFixed(1)} km/h, '
            'Max tolerable: ${maintenance.maxWindSpeedKmph} km/h',
        recommendation: 'Provide windbreak protection or move plant to a sheltered location. '
            'Stake tall plants to prevent breakage.',
      ));
    }

    // If no alerts, conditions are optimal
    if (alerts.isEmpty) {
      alerts.add(WeatherAlert(
        type: AlertType.optimal,
        severity: AlertSeverity.success,
        title: 'Weather conditions are optimal',
        message: 'All environmental conditions are within the recommended range '
            'for ${maintenance.commonName}.',
        recommendation: 'Continue regular maintenance schedule. '
            'Water every ${maintenance.wateringFrequencyDays} days.',
      ));
    }

    return alerts;
  }

  /// Get maintenance recommendations based on current conditions
  /// 
  /// Provides dynamic recommendations considering weather and plant requirements.
  static Map<String, String> getPlantMaintenanceRecommendations(
    PlantMaintenance maintenance,
    WeatherData? weather,
  ) {
    final recommendations = <String, String>{};

    // Watering recommendation
    String wateringAdvice = 'Water every ${maintenance.wateringFrequencyDays} days '
        'with ${maintenance.wateringAmountLiters}L of water.';
    if (weather != null) {
      if (weather.temperature > maintenance.maxTempC) {
        wateringAdvice += ' Due to high temperature, consider increasing frequency.';
      }
      if (weather.humidity < maintenance.minHumidity) {
        wateringAdvice += ' Low humidity detected - check soil moisture daily.';
      }
      if (weather.rainfall > 5) {
        wateringAdvice = 'Recent rainfall detected. Skip watering for today and check soil moisture.';
      }
    }
    recommendations['watering'] = wateringAdvice;

    // Fertilizing recommendation
    recommendations['fertilizing'] = 'Apply ${maintenance.fertilizerType} '
        'every ${maintenance.fertilizerIntervalDays} days for optimal growth.';

    // Pruning recommendation
    recommendations['pruning'] = 'Prune ${maintenance.commonName} '
        'every ${maintenance.pruningFrequencyDays} days to maintain shape and health.';

    // Sunlight recommendation
    recommendations['sunlight'] = 'This plant requires ${maintenance.sunlightRequirement}. '
        'Ensure proper placement for best results.';

    // Soil recommendation
    recommendations['soil'] = 'Use ${maintenance.soilType} soil for optimal drainage and nutrients.';

    return recommendations;
  }

  // ============================================================
  // AI-BASED RECOMMENDATIONS (GROQ API)
  // ============================================================

  /// Generate personalized plant maintenance recommendations using AI with real weather
  /// 
  /// Considers:
  /// - Plant type and health status
  /// - Real current weather conditions from user's location
  /// - User location from profile
  /// 
  /// Returns comprehensive care advice for watering, fertilizing, pruning, etc.
  static Future<Map<String, dynamic>> getMaintenanceRecommendations({
    required Plant plant,
    required BuildContext context,
    WeatherData? weatherOverride,
    String? locationOverride,
  }) async {
    try {
      print('🤖 Generating maintenance recommendations for ${plant.plantName}');

      // Get real weather data
      final weather = weatherOverride ?? await getCurrentWeather(context);
      if (weather == null) {
        throw Exception('Unable to get weather data');
      }

      // Get user location
      final authProvider = context.read<AuthProvider>();
      final location = locationOverride ?? authProvider.user?.location ?? weather.cityName ?? 'Unknown';

      print('🌍 Using weather from: ${weather.cityName}');
      print('🌡️ Temperature: ${weather.temperature}°C, Humidity: ${weather.humidity}%');

      // Build the prompt for the AI
      final prompt = _buildMaintenancePrompt(plant, weather, location);

      // Call Groq API
      final response = await _callGroqAPI(prompt);

      // Parse and structure the response
      final recommendations = _parseRecommendations(response);

      print('✅ Maintenance recommendations generated with real weather data');
      return recommendations;
    } catch (e) {
      print('❌ Maintenance Service Error: $e');
      
      // Use demo weather as fallback
      final fallbackWeather = _getDemoWeatherData();
      return _getFallbackRecommendations(plant, fallbackWeather);
    }
  }

  /// Generate maintenance recommendations with provided weather data
  /// 
  /// Legacy method for backward compatibility
  static Future<Map<String, dynamic>> getMaintenanceRecommendationsWithWeather({
    required Plant plant,
    required WeatherData weather,
    required String location,
  }) async {
    try {
      print('🤖 Generating maintenance recommendations for ${plant.plantName}');

      // Build the prompt for the AI
      final prompt = _buildMaintenancePrompt(plant, weather, location);

      // Call Groq API
      final response = await _callGroqAPI(prompt);

      // Parse and structure the response
      final recommendations = _parseRecommendations(response);

      print('✅ Maintenance recommendations generated');
      return recommendations;
    } catch (e) {
      print('❌ Maintenance Service Error: $e');
      
      // Return fallback recommendations if API fails
      return _getFallbackRecommendations(plant, weather);
    }
  }

  /// Get weather-based plant alerts using real weather data
  /// 
  /// Compares current weather conditions with plant requirements
  static Future<List<WeatherAlert>> getWeatherBasedAlerts({
    required PlantMaintenance plantMaintenance,
    required BuildContext context,
    WeatherData? weatherOverride,
  }) async {
    try {
      // Get real weather data
      final weather = weatherOverride ?? await getCurrentWeather(context);
      if (weather == null) {
        print('⚠️ No weather data available for alerts');
        return [];
      }

      print('🌡️ Comparing plant requirements with current weather');
      print('📊 Weather: ${weather.temperature}°C, ${weather.humidity}% humidity, ${weather.windSpeed} km/h wind');
      
      return compareWithWeather(plantMaintenance, weather);
    } catch (e) {
      print('❌ Error getting weather alerts: $e');
      return [];
    }
  }

  /// Build AI prompt with plant and weather context
  static String _buildMaintenancePrompt(
    Plant plant,
    WeatherData weather,
    String location,
  ) {
    return '''
You are an expert agricultural advisor. Provide specific plant maintenance recommendations.

Plant Information:
- Name: ${plant.plantName}
- Scientific Name: ${plant.scientificName ?? 'Unknown'}
- Current Health: ${plant.healthStatus}
- Known Care:
  * Watering: ${plant.careWater ?? 'Not specified'}
  * Sunlight: ${plant.careSunlight ?? 'Not specified'}
  * Temperature: ${plant.careTemperature ?? 'Not specified'}

Current Weather ($location):
- Temperature: ${weather.temperature}°C
- Humidity: ${weather.humidity}%
- Condition: ${weather.condition}
- Rainfall: ${weather.rainfall}mm

Provide maintenance recommendations in this exact JSON format:
{
  "watering": {
    "frequency": "specific schedule (e.g., 'Every 2-3 days')",
    "amount": "amount in ml or description",
    "timing": "best time of day",
    "notes": "weather-specific advice"
  },
  "fertilizing": {
    "type": "NPK ratio or fertilizer type",
    "frequency": "how often",
    "amount": "quantity",
    "notes": "additional tips"
  },
  "pruning": {
    "needed": true or false,
    "frequency": "how often",
    "method": "how to prune",
    "notes": "what to look for"
  },
  "pest_control": {
    "common_pests": ["list of pests"],
    "prevention": "prevention methods",
    "treatment": "treatment if infected"
  },
  "weather_adjustments": "specific adjustments based on current weather",
  "health_tips": "tips to improve plant health",
  "urgent_actions": ["any urgent care needed based on weather"]
}

Provide only the JSON response, no additional text.
''';
  }

  /// Call Groq API with the prompt
  static Future<String> _callGroqAPI(String prompt) async {
    final url = Uri.parse('$_groqBaseUrl/chat/completions');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_groqApiKey',
    };

    final body = json.encode({
      'model': 'llama-3.3-70b-versatile', // Updated model
      'messages': [
        {
          'role': 'system',
          'content':
              'You are an expert agricultural advisor. Respond only with valid JSON.',
        },
        {
          'role': 'user',
          'content': prompt,
        },
      ],
      'temperature': 0.7,
      'max_tokens': 2000,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final content = data['choices'][0]['message']['content'];
        return content;
      } else if (response.statusCode == 401) {
        throw Exception(
          'Invalid Groq API key. Get free key from: https://console.groq.com',
        );
      } else {
        throw Exception(
          'Groq API error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('❌ Groq API call failed: $e');
      rethrow;
    }
  }

  /// Parse AI response into structured recommendations
  static Map<String, dynamic> _parseRecommendations(String aiResponse) {
    try {
      // Remove markdown code blocks if present
      String cleanedResponse = aiResponse
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      // Parse JSON
      final recommendations = json.decode(cleanedResponse);
      return recommendations;
    } catch (e) {
      print('❌ Failed to parse AI response: $e');
      print('Response was: $aiResponse');
      throw Exception('Failed to parse recommendations');
    }
  }

  /// Fallback recommendations if API fails
  static Map<String, dynamic> _getFallbackRecommendations(
    Plant plant,
    WeatherData weather,
  ) {
    // Adjust watering based on weather
    String wateringFrequency = 'Every 2-3 days';
    String weatherNote = '';

    if (weather.temperature > 30) {
      wateringFrequency = 'Daily';
      weatherNote = 'Hot weather requires more frequent watering.';
    } else if (weather.temperature < 15) {
      wateringFrequency = 'Every 4-5 days';
      weatherNote = 'Cool weather requires less water.';
    } else if (weather.rainfall > 5) {
      wateringFrequency = 'Skip watering for 2-3 days';
      weatherNote = 'Recent rainfall has provided moisture.';
    }

    return {
      'watering': {
        'frequency': wateringFrequency,
        'amount': '200-300ml per plant',
        'timing': 'Early morning (6-8 AM) or evening (5-7 PM)',
        'notes': weatherNote.isNotEmpty
            ? weatherNote
            : plant.careWater ?? 'Water when soil is dry to touch.',
      },
      'fertilizing': {
        'type': 'Balanced NPK 10-10-10',
        'frequency': 'Every 2-4 weeks during growing season',
        'amount': 'Follow package instructions',
        'notes': 'Reduce in winter months',
      },
      'pruning': {
        'needed': true,
        'frequency': 'Monthly or as needed',
        'method': 'Remove dead or yellowing leaves',
        'notes': 'Prune to encourage bushier growth',
      },
      'pest_control': {
        'common_pests': ['Aphids', 'Spider mites', 'Mealybugs'],
        'prevention': 'Regular inspection, neem oil spray',
        'treatment': 'Insecticidal soap or neem oil',
      },
      'weather_adjustments':
          'Temperature: ${weather.temperature}°C, Humidity: ${weather.humidity}%. '
          'Adjust watering based on conditions.',
      'health_tips': plant.healthStatus == 'healthy'
          ? 'Plant is in good condition. Maintain current care routine.'
          : 'Monitor plant closely and adjust care as needed.',
      'urgent_actions': _getUrgentActions(plant, weather),
    };
  }

  /// Determine urgent actions based on weather
  static List<String> _getUrgentActions(Plant plant, WeatherData weather) {
    List<String> actions = [];

    if (weather.temperature > 35) {
      actions.add('Provide shade during peak sun hours');
      actions.add('Increase watering frequency');
    }

    if (weather.temperature < 10) {
      actions.add('Move plant indoors if possible');
      actions.add('Cover with frost cloth overnight');
    }

    if (weather.rainfall > 20) {
      actions.add('Ensure proper drainage to prevent root rot');
      actions.add('Check for waterlogging');
    }

    if (weather.humidity > 85) {
      actions.add('Watch for fungal diseases');
      actions.add('Ensure good air circulation');
    }

    if (plant.healthStatus != 'healthy') {
      actions.add('Check for pests or diseases');
      actions.add('Consider adjusting care routine');
    }

    return actions.isEmpty ? ['No urgent actions needed'] : actions;
  }

  /// Generate quick maintenance summary
  static String generateQuickSummary(
    Plant plant,
    WeatherData weather,
  ) {
    final temp = weather.temperature;
    String summary = '';

    if (temp > 30) {
      summary = '🌡️ Hot day! Water your ${plant.plantName} more frequently. ';
    } else if (temp < 15) {
      summary = '❄️ Cool weather. Reduce watering for ${plant.plantName}. ';
    } else {
      summary = '✅ Good weather for ${plant.plantName}. ';
    }

    if (weather.rainfall > 5) {
      summary += 'Recent rain means you can skip watering today.';
    } else if (weather.condition.toLowerCase().contains('sun')) {
      summary += 'Sunny day - ensure adequate moisture.';
    } else {
      summary += 'Maintain regular care schedule.';
    }

    return summary;
  }
}
