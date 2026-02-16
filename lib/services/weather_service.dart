import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_data.dart';

class WeatherService {
  // OpenWeatherMap API key
  // Get free API key from: https://openweathermap.org/api
  static const String _apiKey = '6300a482238b9f294ea64ebc09ded19f';
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';
  
  // Demo mode flag - set to true to use mock data
  static const bool _useDemoMode = false;

  /// Fetch weather data by city name
  /// 
  /// Example:
  /// ```dart
  /// final weather = await WeatherService.getWeatherByCity('London');
  /// ```
  static Future<WeatherData> getWeatherByCity(String cityName) async {
    // Use demo mode if enabled
    if (_useDemoMode) {
      print('🎭 Demo Mode: Using mock weather data for $cityName');
      return _getDemoWeatherData(cityName);
    }

    try {
      final url = Uri.parse(
        '$_baseUrl/weather?q=$cityName&appid=$_apiKey&units=metric',
      );

      print('🌤️ Fetching weather for: $cityName');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Weather data received: ${data['weather'][0]['main']}');
        return WeatherData.fromJson(data);
      } else if (response.statusCode == 401) {
        print('⚠️ API key invalid, switching to demo mode');
        return _getDemoWeatherData(cityName);
      } else if (response.statusCode == 404) {
        throw Exception('City not found: $cityName');
      } else {
        print('⚠️ API error, switching to demo mode');
        return _getDemoWeatherData(cityName);
      }
    } catch (e) {
      print('❌ Weather API Error: $e');
      print('🎭 Falling back to demo mode');
      return _getDemoWeatherData(cityName);
    }
  }

  /// Fetch weather data by coordinates (latitude, longitude)
  /// 
  /// Example:
  /// ```dart
  /// final weather = await WeatherService.getWeatherByCoordinates(51.5074, -0.1278);
  /// ```
  static Future<WeatherData> getWeatherByCoordinates(
    double latitude,
    double longitude,
  ) async {
    // Use demo mode if enabled
    if (_useDemoMode) {
      print('🎭 Demo Mode: Using mock weather data for coordinates ($latitude, $longitude)');
      return _getDemoWeatherData('Location');
    }

    try {
      final url = Uri.parse(
        '$_baseUrl/weather?lat=$latitude&lon=$longitude&appid=$_apiKey&units=metric',
      );

      print('🌤️ Fetching weather for coordinates: $latitude, $longitude');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Weather data received');
        return WeatherData.fromJson(data);
      } else if (response.statusCode == 401) {
        print('⚠️ API key invalid, switching to demo mode');
        return _getDemoWeatherData('Location');
      } else {
        print('⚠️ API error, switching to demo mode');
        return _getDemoWeatherData('Location');
      }
    } catch (e) {
      print('❌ Weather API Error: $e');
      print('🎭 Falling back to demo mode');
      return _getDemoWeatherData('Location');
    }
  }

  /// Get 5-day weather forecast
  /// 
  /// Example:
  /// ```dart
  /// final forecast = await WeatherService.getForecast('London');
  /// ```
  static Future<List<WeatherData>> getForecast(String cityName) async {
    // Use demo mode if enabled
    if (_useDemoMode) {
      print('🎭 Demo Mode: Using mock forecast data for $cityName');
      return _getDemoForecastData(cityName);
    }

    try {
      final url = Uri.parse(
        '$_baseUrl/forecast?q=$cityName&appid=$_apiKey&units=metric',
      );

      print('🌤️ Fetching 5-day forecast for: $cityName');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> forecastList = data['list'];

        print('✅ Forecast data received: ${forecastList.length} entries');

        return forecastList
            .map((item) => WeatherData.fromForecastJson(item))
            .toList();
      } else if (response.statusCode == 401) {
        print('⚠️ API key invalid, switching to demo mode');
        return _getDemoForecastData(cityName);
      } else if (response.statusCode == 404) {
        throw Exception('City not found: $cityName');
      } else {
        print('⚠️ API error, switching to demo mode');
        return _getDemoForecastData(cityName);
      }
    } catch (e) {
      print('❌ Forecast API Error: $e');
      print('🎭 Falling back to demo mode');
      return _getDemoForecastData(cityName);
    }
  }

  /// Get farming recommendations based on weather
  static String getFarmingAdvice(WeatherData weather) {
    final temp = weather.temperature;
    final humidity = weather.humidity;
    final rainfall = weather.rainfall;
    final condition = weather.condition.toLowerCase();

    List<String> advice = [];

    // Temperature-based advice
    if (temp > 35) {
      advice.add('🌡️ Very hot! Increase watering frequency.');
      advice.add('🌿 Provide shade for sensitive plants.');
    } else if (temp > 30) {
      advice.add('☀️ Hot weather. Water plants early morning or evening.');
    } else if (temp < 10) {
      advice.add('❄️ Cold weather. Protect plants from frost.');
      advice.add('🛡️ Cover sensitive crops overnight.');
    } else if (temp < 15) {
      advice.add('🌤️ Cool weather. Reduce watering frequency.');
    } else {
      advice.add('✅ Ideal temperature for most crops.');
    }

    // Humidity-based advice
    if (humidity > 80) {
      advice.add('💧 High humidity. Watch for fungal diseases.');
      advice.add('🔍 Ensure good air circulation.');
    } else if (humidity < 30) {
      advice.add('🌵 Low humidity. Consider misting plants.');
    }

    // Rainfall/Condition-based advice
    if (condition.contains('rain') || rainfall > 0) {
      advice.add('🌧️ Rain expected. Skip watering today.');
      advice.add('☔ Check drainage to prevent waterlogging.');
    } else if (condition.contains('sun') || condition.contains('clear')) {
      advice.add('☀️ Sunny day. Good for photosynthesis!');
      advice.add('💦 Ensure adequate soil moisture.');
    } else if (condition.contains('cloud')) {
      advice.add('☁️ Cloudy. Reduce watering slightly.');
    }

    return advice.join('\n');
  }

  /// Convert temperature units
  static double celsiusToFahrenheit(double celsius) {
    return (celsius * 9 / 5) + 32;
  }

  static double fahrenheitToCelsius(double fahrenheit) {
    return (fahrenheit - 32) * 5 / 9;
  }

  // ========== DEMO MODE FUNCTIONS ==========

  /// Generate realistic demo weather data for testing
  static WeatherData _getDemoWeatherData(String cityName) {
    final now = DateTime.now();
    
    // Generate realistic random values
    final random = now.millisecondsSinceEpoch % 100;
    final temp = 20 + (random % 15).toDouble(); // 20-35°C
    final humidity = (50 + (random % 40)).toDouble(); // 50-90%
    final windSpeed = 2 + (random % 8).toDouble(); // 2-10 m/s
    
    // Vary weather conditions
    final conditions = ['Clear', 'Partly Cloudy', 'Sunny', 'Cloudy', 'Light Rain'];
    final descriptions = ['clear sky', 'few clouds', 'sunny weather', 'overcast clouds', 'light rain'];
    final icons = ['01d', '02d', '01d', '04d', '10d'];
    final index = random % conditions.length;

    return WeatherData(
      temperature: temp,
      humidity: humidity,
      rainfall: index == 4 ? 2.5 : 0.0, // Rain only for 'Light Rain'
      condition: conditions[index],
      windSpeed: windSpeed,
      timestamp: now,
      cityName: cityName,
      description: descriptions[index],
      feelsLike: temp - 1,
      pressure: 1013 + (random % 20),
      visibility: 10000,
      icon: icons[index],
    );
  }

  /// Generate realistic demo forecast data
  static List<WeatherData> _getDemoForecastData(String cityName) {
    final now = DateTime.now();
    final forecasts = <WeatherData>[];
    
    for (int i = 1; i <= 5; i++) {
      final forecastDate = now.add(Duration(days: i));
      final random = (now.millisecondsSinceEpoch + i * 1000) % 100;
      
      final temp = 18 + (random % 18).toDouble(); // 18-36°C
      final humidity = (45 + (random % 45)).toDouble(); // 45-90%
      final windSpeed = 2 + (random % 10).toDouble(); // 2-12 m/s
      
      final conditions = ['Clear', 'Partly Cloudy', 'Sunny', 'Cloudy', 'Rain', 'Scattered Clouds'];
      final descriptions = ['clear sky', 'few clouds', 'sunny weather', 'overcast', 'moderate rain', 'scattered clouds'];
      final icons = ['01d', '02d', '01d', '04d', '10d', '03d'];
      final index = (random + i) % conditions.length;
      
      forecasts.add(WeatherData(
        temperature: temp,
        humidity: humidity,
        rainfall: index == 4 ? 5.0 : 0.0,
        condition: conditions[index],
        windSpeed: windSpeed,
        timestamp: forecastDate,
        cityName: cityName,
        description: descriptions[index],
        feelsLike: temp - 1.5,
        pressure: 1010 + (random % 25),
        visibility: 10000,
        icon: icons[index],
      ));
    }
    
    return forecasts;
  }
}
