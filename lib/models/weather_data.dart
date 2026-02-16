class WeatherData {
  final double temperature;
  final double humidity;
  final double rainfall;
  final String condition; // sunny, rainy, cloudy, etc
  final double windSpeed;
  final DateTime timestamp;
  final String? uvIndex;
  final String? cityName;
  final String? description;
  final double? feelsLike;
  final int? pressure;
  final int? visibility;
  final String? icon;

  WeatherData({
    required this.temperature,
    required this.humidity,
    required this.rainfall,
    required this.condition,
    required this.windSpeed,
    required this.timestamp,
    this.uvIndex,
    this.cityName,
    this.description,
    this.feelsLike,
    this.pressure,
    this.visibility,
    this.icon,
  });

  /// Create WeatherData from OpenWeatherMap current weather API response
  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      temperature: (json['main']['temp'] as num).toDouble(),
      humidity: (json['main']['humidity'] as num).toDouble(),
      rainfall: json['rain'] != null 
          ? ((json['rain']['1h'] ?? 0) as num).toDouble() 
          : 0.0,
      condition: json['weather'][0]['main'] as String,
      windSpeed: (json['wind']['speed'] as num).toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (json['dt'] as int) * 1000,
      ),
      cityName: json['name'] as String?,
      description: json['weather'][0]['description'] as String?,
      feelsLike: (json['main']['feels_like'] as num?)?.toDouble(),
      pressure: json['main']['pressure'] as int?,
      visibility: json['visibility'] as int?,
      icon: json['weather'][0]['icon'] as String?,
    );
  }

  /// Create WeatherData from OpenWeatherMap forecast API response
  factory WeatherData.fromForecastJson(Map<String, dynamic> json) {
    return WeatherData(
      temperature: (json['main']['temp'] as num).toDouble(),
      humidity: (json['main']['humidity'] as num).toDouble(),
      rainfall: json['rain'] != null 
          ? ((json['rain']['3h'] ?? 0) as num).toDouble() 
          : 0.0,
      condition: json['weather'][0]['main'] as String,
      windSpeed: (json['wind']['speed'] as num).toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (json['dt'] as int) * 1000,
      ),
      description: json['weather'][0]['description'] as String?,
      feelsLike: (json['main']['feels_like'] as num?)?.toDouble(),
      pressure: json['main']['pressure'] as int?,
      visibility: json['visibility'] as int?,
      icon: json['weather'][0]['icon'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'humidity': humidity,
      'rainfall': rainfall,
      'condition': condition,
      'windSpeed': windSpeed,
      'timestamp': timestamp.toIso8601String(),
      'uvIndex': uvIndex,
      'cityName': cityName,
      'description': description,
      'feelsLike': feelsLike,
      'pressure': pressure,
      'visibility': visibility,
      'icon': icon,
    };
  }

  /// Get weather icon URL from OpenWeatherMap
  String getIconUrl() {
    if (icon != null) {
      return 'https://openweathermap.org/img/wn/$icon@2x.png';
    }
    return '';
  }
}
