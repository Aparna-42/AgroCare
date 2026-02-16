import 'package:flutter/foundation.dart';
import '../models/weather_data.dart';
import '../services/weather_service.dart';

class WeatherProvider with ChangeNotifier {
  WeatherData? _currentWeather;
  List<WeatherData>? _forecast;
  String? _errorMessage;
  bool _isLoading = false;

  WeatherData? get currentWeather => _currentWeather;
  List<WeatherData>? get forecast => _forecast;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  Future<void> fetchWeatherByCity(String city) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentWeather = await WeatherService.getWeatherByCity(city);
      _forecast = await WeatherService.getForecast(city);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _currentWeather = null;
      _forecast = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchWeatherByCoordinates(double lat, double lon) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentWeather = await WeatherService.getWeatherByCoordinates(lat, lon);
      // Fetch forecast for the city if we have a name
      if (_currentWeather?.cityName != null) {
        _forecast = await WeatherService.getForecast(_currentWeather!.cityName!);
      }
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _currentWeather = null;
      _forecast = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearWeather() {
    _currentWeather = null;
    _forecast = null;
    _errorMessage = null;
    notifyListeners();
  }
}
