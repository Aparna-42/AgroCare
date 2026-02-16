// API Keys Configuration Template
// 
// IMPORTANT: DO NOT commit actual API keys to version control!
// This file shows the structure. Create actual keys by:
// 1. Copy this file to a new file: env_config.dart
// 2. Add your actual API keys there
// 3. Add env_config.dart to .gitignore
// 4. Import from env_config.dart in services

/// Plant.id API Configuration
/// Get API key from: https://plant.id
/// Sign up for free account and get your API key
class PlantIdConfig {
  static const String apiKey = String.fromEnvironment(
    'PLANT_ID_API_KEY',
    defaultValue: 'YOUR_PLANT_ID_API_KEY_HERE',
  );
  
  static const String baseUrl = 'https://plant.id/api/v3';
  
  /// Validate if API key is configured
  static bool get isConfigured {
    return apiKey.isNotEmpty && 
           !apiKey.contains('YOUR_PLANT_ID_API_KEY');
  }
}

/// OpenWeatherMap API Configuration
/// Get API key from: https://openweathermap.org/api
/// Free tier available with limited requests
class WeatherConfig {
  static const String apiKey = String.fromEnvironment(
    'OPENWEATHER_API_KEY',
    defaultValue: 'YOUR_OPENWEATHER_API_KEY_HERE',
  );
  
  static const String baseUrl = 'https://api.openweathermap.org/data/2.5';
  
  /// Validate if API key is configured
  static bool get isConfigured {
    return apiKey.isNotEmpty && 
           !apiKey.contains('YOUR_OPENWEATHER_API_KEY');
  }
}

/// Groq AI API Configuration (for future use)
/// Get API from: https://groq.com
/// Free tier available for development
class GroqConfig {
  static const String apiKey = String.fromEnvironment(
    'GROQ_API_KEY',
    defaultValue: 'YOUR_GROQ_API_KEY_HERE',
  );
  
  static const String baseUrl = 'https://api.groq.com/openai/v1';
  
  /// Validate if API key is configured
  static bool get isConfigured {
    return apiKey.isNotEmpty && 
           !apiKey.contains('YOUR_GROQ_API_KEY');
  }
}
