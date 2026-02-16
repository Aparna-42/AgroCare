import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../config/theme.dart';
import '../widgets/custom_appbar.dart';
import '../services/weather_service.dart';
import '../services/location_service.dart';
import '../models/weather_data.dart';
import '../providers/auth_provider.dart';
import 'package:intl/intl.dart';

class WeatherAdvisoryScreen extends StatefulWidget {
  const WeatherAdvisoryScreen({super.key});

  @override
  State<WeatherAdvisoryScreen> createState() => _WeatherAdvisoryScreenState();
}

class _WeatherAdvisoryScreenState extends State<WeatherAdvisoryScreen> {
  WeatherData? _weatherData;
  List<WeatherData>? _forecast;
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedCity = '';
  final TextEditingController _cityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get user's location from profile
      final authProvider = context.read<AuthProvider>();
      final userLocation = authProvider.user?.location ?? 'London';
      _selectedCity = userLocation;
      _cityController.text = userLocation;

      print('🌤️ Loading weather for: $userLocation');

      // Fetch current weather and forecast
      final weather = await WeatherService.getWeatherByCity(userLocation);
      final forecast = await WeatherService.getForecast(userLocation);

      setState(() {
        _weatherData = weather;
        _forecast = forecast;
        _isLoading = false;
      });

      print('✅ Weather data loaded successfully');
    } catch (e) {
      print('❌ Weather loading failed: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _searchWeather() async {
    if (_cityController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final city = _cityController.text.trim();
      print('🔍 Searching weather for: $city');

      final weather = await WeatherService.getWeatherByCity(city);
      final forecast = await WeatherService.getForecast(city);

      // Save the location to user's profile for future sessions
      final authProvider = context.read<AuthProvider>();
      await authProvider.updateProfile(
        name: authProvider.user?.name ?? 'User',
        location: city,
      );
      print('💾 Saved location to profile: $city');

      setState(() {
        _weatherData = weather;
        _forecast = forecast;
        _selectedCity = city;
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📍 Location saved: $city'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Get weather using device GPS location
  Future<void> _useCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('📍 Requesting GPS location...');

      // Get current position
      Position? position = await LocationService.getCurrentLocation();

      if (position == null) {
        throw Exception(
          'Unable to get location. Please enable location services and grant permission.',
        );
      }

      print('✅ Location: ${position.latitude}, ${position.longitude}');

      // Fetch weather by coordinates
      final weather = await WeatherService.getWeatherByCoordinates(
        position.latitude,
        position.longitude,
      );
      final forecast = await WeatherService.getForecast(weather.cityName ?? 'Current Location');

      // Save the location to user's profile for future sessions
      final authProvider = context.read<AuthProvider>();
      final locationName = weather.cityName ?? 'Your Location';
      await authProvider.updateProfile(
        name: authProvider.user?.name ?? 'User',
        location: locationName,
      );
      print('💾 Saved location to profile: $locationName');

      setState(() {
        _weatherData = weather;
        _forecast = forecast;
        _selectedCity = locationName;
        _cityController.text = _selectedCity;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📍 Location saved: $locationName'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to get location: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  IconData _getWeatherIcon(String condition) {
    final lowerCondition = condition.toLowerCase();
    if (lowerCondition.contains('rain')) return Icons.water_drop;
    if (lowerCondition.contains('cloud')) return Icons.cloud;
    if (lowerCondition.contains('sun') || lowerCondition.contains('clear')) {
      return Icons.wb_sunny;
    }
    if (lowerCondition.contains('storm')) return Icons.thunderstorm;
    if (lowerCondition.contains('snow')) return Icons.ac_unit;
    if (lowerCondition.contains('fog') || lowerCondition.contains('mist')) {
      return Icons.foggy;
    }
    return Icons.wb_cloudy;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Weather Advisory',
        onLeadingPressed: () {
          if (context.canPop()) {
            context.pop();
          }
        },
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : _weatherData == null
                  ? _buildNoDataView()
                  : RefreshIndicator(
                      onRefresh: _loadWeather,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          children: [
                            // Location Options Section
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  // GPS Location Button
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: _useCurrentLocation,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryGreen,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      icon: const Icon(Icons.my_location, color: Colors.white),
                                      label: const Text(
                                        'Use Current Location (GPS)',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // Divider with "OR"
                                  Row(
                                    children: [
                                      const Expanded(child: Divider()),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        child: Text(
                                          'OR',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const Expanded(child: Divider()),
                                    ],
                                  ),

                                  const SizedBox(height: 16),

                                  // Manual City Search
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _cityController,
                                          decoration: InputDecoration(
                                            hintText: 'Enter city name manually',
                                            prefixIcon: const Icon(Icons.location_city),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            contentPadding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                          ),
                                          onSubmitted: (_) => _searchWeather(),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton(
                                        onPressed: _searchWeather,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: primaryGreen,
                                          padding: const EdgeInsets.all(16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: const Icon(Icons.search, color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Current Weather Card
                            _buildCurrentWeatherCard(),

                            const SizedBox(height: 16),

                            // Detailed Weather Info
                            _buildDetailedInfo(),

                            const SizedBox(height: 16),

                            // 5-Day Forecast
                            if (_forecast != null && _forecast!.isNotEmpty)
                              _buildForecastSection(),

                            const SizedBox(height: 16),

                            // Agricultural Advisory
                            _buildAgriAdvisory(),

                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildCurrentWeatherCard() {
    final weather = _weatherData!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryGreen, accentGreen],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            weather.cityName ?? _selectedCity,
            style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                  color: white,
                  fontWeight: FontWeight.w600,
                ),
          ),
          Text(
            DateFormat('EEEE, MMM d, y').format(weather.timestamp),
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: white.withOpacity(0.9),
                ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  Icon(
                    _getWeatherIcon(weather.condition),
                    size: 60,
                    color: white,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    weather.condition,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge!
                        .copyWith(color: white, fontWeight: FontWeight.w500),
                  ),
                  if (weather.description != null)
                    Text(
                      weather.description!,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall!
                          .copyWith(color: white.withOpacity(0.8)),
                    ),
                ],
              ),
              Column(
                children: [
                  Text(
                    '${weather.temperature.toStringAsFixed(1)}°C',
                    style: Theme.of(context).textTheme.displayLarge!.copyWith(
                          color: white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (weather.feelsLike != null)
                    Text(
                      'Feels like ${weather.feelsLike!.toStringAsFixed(1)}°C',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall!
                          .copyWith(color: white.withOpacity(0.9)),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            decoration: BoxDecoration(
              color: white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildWeatherStat(
                  Icons.water_drop,
                  '${weather.humidity.toStringAsFixed(0)}%',
                  'Humidity',
                ),
                _buildWeatherStat(
                  Icons.air,
                  '${weather.windSpeed.toStringAsFixed(1)} m/s',
                  'Wind',
                ),
                if (weather.rainfall > 0)
                  _buildWeatherStat(
                    Icons.umbrella,
                    '${weather.rainfall.toStringAsFixed(1)}mm',
                    'Rain',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: white, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                color: white,
                fontWeight: FontWeight.w600,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: white.withOpacity(0.9),
              ),
        ),
      ],
    );
  }

  Widget _buildDetailedInfo() {
    final weather = _weatherData!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detailed Information',
            style: Theme.of(context)
                .textTheme
                .titleLarge!
                .copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (weather.pressure != null)
            _buildInfoTile(
              'Pressure',
              '${weather.pressure} hPa',
              Icons.compress,
              Colors.purple,
            ),
          if (weather.visibility != null)
            _buildInfoTile(
              'Visibility',
              '${(weather.visibility! / 1000).toStringAsFixed(1)} km',
              Icons.visibility,
              Colors.blue,
            ),
          _buildInfoTile(
            'Wind Speed',
            '${weather.windSpeed.toStringAsFixed(1)} m/s',
            Icons.air,
            Colors.grey,
          ),
          if (weather.rainfall > 0)
            _buildInfoTile(
              'Rainfall',
              '${weather.rainfall.toStringAsFixed(1)} mm',
              Icons.water_drop,
              Colors.blue,
            ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: lightGray),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Forecast',
            style: Theme.of(context)
                .textTheme
                .titleLarge!
                .copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _forecast!.length > 8 ? 8 : _forecast!.length,
              itemBuilder: (context, index) {
                final forecastIndex = index * 3;
                if (forecastIndex >= _forecast!.length) return const SizedBox();
                final item = _forecast![forecastIndex];
                return _buildForecastCard(item);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastCard(WeatherData weather) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: lightGray),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(
            DateFormat('EEE').format(weather.timestamp),
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          Text(
            DateFormat('ha').format(weather.timestamp),
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: textGray,
                ),
          ),
          Icon(
            _getWeatherIcon(weather.condition),
            size: 36,
            color: primaryGreen,
          ),
          Text(
            '${weather.temperature.toStringAsFixed(0)}°C',
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgriAdvisory() {
    final weather = _weatherData!;
    final advice = WeatherService.getFarmingAdvice(weather);
    final adviceLines = advice.split('\n');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: warningOrange),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: warningOrange),
              const SizedBox(width: 8),
              Text(
                'Agricultural Advisory',
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.w600,
                      color: warningOrange,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...adviceLines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                line,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: textGray,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to Load Weather',
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: textGray,
                  ),
            ),
            const SizedBox(height: 16),
            if (_errorMessage?.contains('API key') == true) ...[
              Text(
                'Please check your OpenWeatherMap API key',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: warningOrange,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'See API_KEYS_SETUP.md for instructions',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: textGray,
                    ),
              ),
              const SizedBox(height: 16),
            ],
            ElevatedButton.icon(
              onPressed: _loadWeather,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.cloud_off,
            size: 60,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'No Weather Data',
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadWeather,
            icon: const Icon(Icons.refresh),
            label: const Text('Load Weather'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }
}
