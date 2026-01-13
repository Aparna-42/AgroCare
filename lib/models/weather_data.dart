class WeatherData {
  final double temperature;
  final double humidity;
  final double rainfall;
  final String condition; // sunny, rainy, cloudy, etc
  final double windSpeed;
  final DateTime timestamp;
  final String? uvIndex;

  WeatherData({
    required this.temperature,
    required this.humidity,
    required this.rainfall,
    required this.condition,
    required this.windSpeed,
    required this.timestamp,
    this.uvIndex,
  });
}
