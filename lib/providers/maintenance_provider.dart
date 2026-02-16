import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/maintenance_task.dart';
import '../models/plant_maintenance.dart';
import '../models/user_settings.dart';
import '../models/plant.dart';
import '../models/weather_data.dart';
import '../services/plant_maintenance_service.dart';
import '../services/weather_service.dart';
import 'weather_provider.dart';
import 'auth_provider.dart';
import 'plant_provider.dart';
import 'package:uuid/uuid.dart';

/// MaintenanceProvider
/// 
/// State management for plant maintenance features including:
/// - Task management (CRUD operations)
/// - Plant maintenance data from Supabase plant_maintenance table
/// - Weather-based alerts and recommendations
class MaintenanceProvider with ChangeNotifier {
  // Task management state
  List<MaintenanceTask> _tasks = [];
  bool _isLoading = false;
  String? _errorMessage;
  UserSettings? _userSettings;
  bool _isGeneratingTasks = false;

  // Plant maintenance state (from plant_maintenance table)
  PlantMaintenance? _currentPlantMaintenance;
  List<PlantMaintenance> _allPlants = [];
  List<PlantMaintenance> _searchResults = [];
  List<WeatherAlert> _weatherAlerts = [];
  Map<String, List<WeatherAlert>> _alertsByPlant = {}; // Alerts grouped by plant name
  Map<String, String> _recommendations = {};
  
  // Current weather data (for comparison)
  WeatherData? _currentWeather;

  final _supabase = Supabase.instance.client;

  // Task getters
  List<MaintenanceTask> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserSettings? get userSettings => _userSettings;
  bool get isGeneratingTasks => _isGeneratingTasks;
  String? get userId => _supabase.auth.currentUser?.id;

  List<MaintenanceTask> get pendingTasks =>
      _tasks.where((t) => !t.isCompleted).toList();

  // Plant maintenance getters
  PlantMaintenance? get currentPlantMaintenance => _currentPlantMaintenance;
  List<PlantMaintenance> get allPlants => _allPlants;
  List<PlantMaintenance> get searchResults => _searchResults;
  List<WeatherAlert> get weatherAlerts => _weatherAlerts;
  Map<String, List<WeatherAlert>> get alertsByPlant => _alertsByPlant; // Getter for alerts grouped by plant
  Map<String, String> get recommendations => _recommendations;
  WeatherData? get currentWeather => _currentWeather;

  // Get today's tasks
  List<MaintenanceTask> get todaysTasks {
    final today = DateTime.now();
    return _tasks.where((t) {
      return t.scheduledDate.year == today.year &&
          t.scheduledDate.month == today.month &&
          t.scheduledDate.day == today.day;
    }).toList();
  }

  // Get tasks for a specific date
  List<MaintenanceTask> getTasksForDate(DateTime date) {
    return _tasks.where((t) {
      return t.scheduledDate.year == date.year &&
          t.scheduledDate.month == date.month &&
          t.scheduledDate.day == date.day;
    }).toList();
  }

  Future<void> fetchTasks() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        _tasks = [];
        _isLoading = false;
        notifyListeners();
        return;
      }

      final data = await _supabase
          .from('maintenance_tasks')
          .select()
          .eq('user_id', userId);

      _tasks = (data as List).map((item) => MaintenanceTask.fromJson(item)).toList();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      print('Error fetching tasks: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addTask(MaintenanceTask task) async {
    try {
      _errorMessage = null;
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        _errorMessage = 'User not authenticated';
        return false;
      }

      final taskData = task.toJson();
      taskData['user_id'] = userId;

      await _supabase.from('maintenance_tasks').insert(taskData);
      await fetchTasks();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      print('Error adding task: $e');
      return false;
    }
  }

  Future<bool> updateTask(String taskId, MaintenanceTask task) async {
    try {
      _errorMessage = null;
      final taskData = task.toJson();
      await _supabase.from('maintenance_tasks').update(taskData).eq('id', taskId);
      await fetchTasks();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      print('Error updating task: $e');
      return false;
    }
  }

  Future<bool> removeTask(String taskId) async {
    try {
      _errorMessage = null;
      await _supabase.from('maintenance_tasks').delete().eq('id', taskId);
      _tasks.removeWhere((t) => t.id == taskId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      print('Error removing task: $e');
      return false;
    }
  }

  Future<bool> completeTask(String taskId, bool isCompleted) async {
    try {
      _errorMessage = null;
      await _supabase
          .from('maintenance_tasks')
          .update({
            'is_completed': isCompleted,
            'completed_date': isCompleted ? DateTime.now().toIso8601String() : null,
          })
          .eq('id', taskId);
      await fetchTasks();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      print('Error completing task: $e');
      return false;
    }
  }

  List<MaintenanceTask> getTasksByPlantId(String plantId) {
    return _tasks.where((t) => t.plantId == plantId).toList();
  }

  // Clear all tasks for current user
  Future<bool> clearAllTasks() async {
    try {
      _errorMessage = null;
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        _errorMessage = 'User not authenticated';
        return false;
      }

      await _supabase
          .from('maintenance_tasks')
          .delete()
          .eq('user_id', userId);
      
      await fetchTasks();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      print('Error clearing tasks: $e');
      return false;
    }
  }

  // Fetch user settings
  Future<void> fetchUserSettings() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final data = await _supabase
          .from('user_settings')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (data != null) {
        _userSettings = UserSettings.fromJson(data);
      } else {
        // Create default settings if none exist
        _userSettings = UserSettings(
          id: const Uuid().v4(),
          userId: userId,
          availableDaysPerWeek: 3,
          preferredDays: ['Monday', 'Wednesday', 'Friday'],
        );
        await saveUserSettings(_userSettings!);
      }
      notifyListeners();
    } catch (e) {
      print('Error fetching user settings: $e');
    }
  }

  // Save user settings
  Future<bool> saveUserSettings(UserSettings settings) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final settingsData = settings.toJson();
      settingsData['user_id'] = userId;
      settingsData['updated_at'] = DateTime.now().toIso8601String();

      await _supabase
          .from('user_settings')
          .upsert(settingsData);

      _userSettings = settings;
      notifyListeners();
      return true;
    } catch (e) {
      print('Error saving user settings: $e');
      return false;
    }
  }

  // Generate monthly tasks based on plant_maintenance data (no AI)
  Future<bool> generateMonthlyTasks({
    required List<Plant> plants,
    WeatherData? weatherData,
    String? location,
  }) async {
    try {
      _isGeneratingTasks = true;
      _errorMessage = null;
      notifyListeners();

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        _errorMessage = 'User not authenticated';
        return false;
      }

      if (plants.isEmpty) {
        _errorMessage = 'No plants found. Add plants first.';
        return false;
      }

      // Ensure user settings exist
      if (_userSettings == null) {
        await fetchUserSettings();
      }

      final generatedTasks = <MaintenanceTask>[];

      // Generate tasks for entire month (28 days / 4 weeks)
      final today = DateTime.now();
      // Get start of current week (Monday)
      final daysToMonday = today.weekday - 1;
      final startOfWeek = today.subtract(Duration(days: daysToMonday));
      
      // Generate all 28 days (4 weeks)
      final allDays = <DateTime>[];
      for (int i = 0; i < 28; i++) {
        allDays.add(startOfWeek.add(Duration(days: i)));
      }

      // GENERATE TASKS FOR EACH PLANT BASED ON plant_maintenance TABLE DATA
      for (final plant in plants) {
        // Try to fetch maintenance data for this plant from database
        PlantMaintenance? maintenance;
        
        // Try scientific name first, then common name
        if (plant.scientificName != null && plant.scientificName!.isNotEmpty) {
          maintenance = await PlantMaintenanceService.getPlantMaintenanceByScientificName(
            plant.scientificName!,
          );
        }
        
        if (maintenance == null) {
          maintenance = await PlantMaintenanceService.getPlantMaintenanceByCommonName(
            plant.plantName,
          );
        }

        // Use fetched data or defaults
        final wateringFrequency = maintenance?.wateringFrequencyDays ?? 3;
        final wateringAmount = maintenance?.wateringAmountLiters ?? 1.0;
        final fertilizerIntervalDays = maintenance?.fertilizerIntervalDays ?? 30;
        final fertilizerType = maintenance?.fertilizerType ?? 'Balanced NPK';
        final pruningFrequencyDays = maintenance?.pruningFrequencyDays ?? 60;
        final plantName = maintenance?.commonName ?? plant.plantName;
        final notes = maintenance?.maintenanceNotes;

        print('📋 Generating tasks for $plantName:');
        print('   Watering: every $wateringFrequency days, ${wateringAmount}L');
        print('   Fertilizing: $fertilizerType every $fertilizerIntervalDays days');
        print('   Pruning: every $pruningFrequencyDays days');

        // WATERING TASKS - Based on watering_frequency_days
        for (int dayIndex = 0; dayIndex < 28; dayIndex++) {
          if (dayIndex % wateringFrequency == 0) {
            generatedTasks.add(MaintenanceTask(
              id: const Uuid().v4(),
              userId: userId,
              plantId: plant.id,
              taskType: 'watering',
              description: 'Water $plantName',
              scheduledDate: allDays[dayIndex],
              isCompleted: false,
              notes: 'Water ${wateringAmount}L. ${_getWateringNotes(weatherData)}',
            ));
          }
        }

        // FERTILIZING TASKS - Based on fertilizer_interval_days
        // Only add if interval falls within month
        for (int dayIndex = 0; dayIndex < 28; dayIndex++) {
          if (dayIndex % fertilizerIntervalDays == 0 && dayIndex > 0) {
            generatedTasks.add(MaintenanceTask(
              id: const Uuid().v4(),
              userId: userId,
              plantId: plant.id,
              taskType: 'fertilizing',
              description: 'Fertilize $plantName',
              scheduledDate: allDays[dayIndex],
              isCompleted: false,
              notes: 'Apply $fertilizerType fertilizer',
            ));
          }
        }
        // Add one fertilizer task if interval > 28 days (schedule for middle of month)
        if (fertilizerIntervalDays >= 28) {
          generatedTasks.add(MaintenanceTask(
            id: const Uuid().v4(),
            userId: userId,
            plantId: plant.id,
            taskType: 'fertilizing',
            description: 'Fertilize $plantName',
            scheduledDate: allDays[14], // Middle of month
            isCompleted: false,
            notes: 'Apply $fertilizerType fertilizer',
          ));
        }

        // PRUNING TASKS - Based on pruning_frequency_days
        // Only add if pruning is needed within the month
        for (int dayIndex = 0; dayIndex < 28; dayIndex++) {
          if (dayIndex % pruningFrequencyDays == 0 && dayIndex > 0) {
            generatedTasks.add(MaintenanceTask(
              id: const Uuid().v4(),
              userId: userId,
              plantId: plant.id,
              taskType: 'pruning',
              description: 'Prune $plantName',
              scheduledDate: allDays[dayIndex],
              isCompleted: false,
              notes: notes ?? 'Remove dead leaves and shape plant',
            ));
          }
        }
        // Add one pruning task if interval > 28 days (schedule for end of month)
        if (pruningFrequencyDays >= 28) {
          generatedTasks.add(MaintenanceTask(
            id: const Uuid().v4(),
            userId: userId,
            plantId: plant.id,
            taskType: 'pruning',
            description: 'Prune $plantName',
            scheduledDate: allDays[21], // Week 4
            isCompleted: false,
            notes: notes ?? 'Remove dead leaves and shape plant',
          ));
        }

        // PEST CONTROL - Weekly check (every 7 days)
        for (int weekNum = 0; weekNum < 4; weekNum++) {
          final checkDay = allDays[weekNum * 7 + 6]; // Last day of each week
          generatedTasks.add(MaintenanceTask(
            id: const Uuid().v4(),
            userId: userId,
            plantId: plant.id,
            taskType: 'pest_control',
            description: 'Check $plantName for pests',
            scheduledDate: checkDay,
            isCompleted: false,
            notes: 'Inspect leaves for insects and diseases',
          ));
        }
      }

      // Save all generated tasks to database
      for (final task in generatedTasks) {
        await addTask(task);
      }

      await fetchTasks();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      print('Error generating weekly tasks: $e');
      return false;
    } finally {
      _isGeneratingTasks = false;
      notifyListeners();
    }
  }

  // Helper: Get common names for plants
  List<String> _getCommonNames(List<Plant> plants) {
    return plants.map((plant) {
      // Extract common name from scientific name or use plant name
      final name = plant.plantName.toLowerCase();
      
      // Map common scientific names to user-friendly names
      if (name.contains('hibiscus')) return 'Hibiscus';
      if (name.contains('rosa')) return 'Rose';
      if (name.contains('ficus')) return 'Rubber Plant';
      if (name.contains('dracaena')) return 'Snake Plant';
      if (name.contains('monstera')) return 'Monstera';
      if (name.contains('pothos')) return 'Pothos';
      if (name.contains('orchid') || name.contains('cymbidium')) return 'Orchid';
      if (name.contains('kalanchoe')) return 'Kalanchoe';
      if (name.contains('aloe')) return 'Aloe';
      if (name.contains('succulent')) return 'Succulent';
      if (name.contains('tomato')) return 'Tomato';
      if (name.contains('lettuce')) return 'Lettuce';
      if (name.contains('basil')) return 'Basil';
      if (name.contains('mint')) return 'Mint';
      
      // Capitalize first letter of plant name
      return plant.plantName.split(' ')[0].substring(0, 1).toUpperCase() + 
             plant.plantName.split(' ')[0].substring(1).toLowerCase();
    }).toList();
  }

  // Helper: Check if plant needs regular pruning
  bool _needsPruning(String commonName) {
    final prunePlants = ['Hibiscus', 'Rose', 'Tomato', 'Basil', 'Mint'];
    return prunePlants.contains(commonName);
  }

  // Helper: Get weather-specific watering notes
  String _getWateringNotes(WeatherData? weather) {
    if (weather == null) return 'Check soil moisture before watering';
    
    if (weather.temperature > 30) {
      return 'Hot weather - water more frequently';
    } else if (weather.rainfall > 5) {
      return 'Recent rainfall - reduce watering';
    } else if (weather.humidity > 80) {
      return 'High humidity - water less';
    }
    
    return 'Check soil moisture before watering';
  }

  // ============================================================
  // PLANT MAINTENANCE DATA METHODS (from plant_maintenance table)
  // ============================================================

  /// Set current weather data for comparison
  /// 
  /// Call this method to update weather conditions.
  /// Weather data is used to generate alerts and recommendations.
  void setWeatherData(WeatherData weather) {
    _currentWeather = weather;
    // Re-compare with plant maintenance if available
    if (_currentPlantMaintenance != null) {
      _weatherAlerts = PlantMaintenanceService.compareWithWeather(
        _currentPlantMaintenance!,
        weather,
      );
      _recommendations = PlantMaintenanceService.getPlantMaintenanceRecommendations(
        _currentPlantMaintenance!,
        weather,
      );
    }
    notifyListeners();
  }

  /// Fetch plant maintenance data by scientific name from plant_maintenance table
  /// 
  /// Queries the `plant_maintenance` table and updates state.
  /// Also generates weather alerts if weather data is available.
  Future<PlantMaintenance?> fetchPlantMaintenance(String scientificName) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      print('🔍 Fetching maintenance for: $scientificName');

      // Fetch from Supabase plant_maintenance table
      _currentPlantMaintenance = await PlantMaintenanceService.getPlantMaintenanceByScientificName(
        scientificName,
      );

      if (_currentPlantMaintenance == null) {
        _errorMessage = 'No maintenance data found for this plant';
        print('⚠️ No data found for: $scientificName');
      } else {
        print('✅ Found maintenance data: ${_currentPlantMaintenance!.commonName}');
        
        // Generate weather alerts if weather data is available
        if (_currentWeather != null) {
          _weatherAlerts = PlantMaintenanceService.compareWithWeather(
            _currentPlantMaintenance!,
            _currentWeather!,
          );
        }

        // Generate recommendations
        _recommendations = PlantMaintenanceService.getPlantMaintenanceRecommendations(
          _currentPlantMaintenance!,
          _currentWeather,
        );
      }

      return _currentPlantMaintenance;
    } catch (e) {
      _errorMessage = 'Error fetching plant maintenance: $e';
      print('❌ Error: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch plant maintenance data by common name from plant_maintenance table
  Future<PlantMaintenance?> fetchPlantMaintenanceByCommonName(String commonName) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _currentPlantMaintenance = await PlantMaintenanceService.getPlantMaintenanceByCommonName(
        commonName,
      );

      if (_currentPlantMaintenance != null && _currentWeather != null) {
        _weatherAlerts = PlantMaintenanceService.compareWithWeather(
          _currentPlantMaintenance!,
          _currentWeather!,
        );
        _recommendations = PlantMaintenanceService.getPlantMaintenanceRecommendations(
          _currentPlantMaintenance!,
          _currentWeather,
        );
      }

      return _currentPlantMaintenance;
    } catch (e) {
      _errorMessage = 'Error fetching plant maintenance: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Search plants by name from plant_maintenance table
  /// 
  /// Returns matching plants from the maintenance database.
  /// Results are stored in `searchResults` getter.
  Future<void> searchPlantsInDatabase(String query) async {
    try {
      if (query.isEmpty) {
        _searchResults = [];
        notifyListeners();
        return;
      }

      _isLoading = true;
      notifyListeners();

      _searchResults = await PlantMaintenanceService.searchPlants(query);
    } catch (e) {
      _errorMessage = 'Error searching plants: $e';
      _searchResults = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch all available plants from the plant_maintenance database
  /// 
  /// Results are stored in `allPlants` getter.
  Future<void> fetchAllPlantsFromDatabase() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _allPlants = await PlantMaintenanceService.getAllPlants();
      print('✅ Loaded ${_allPlants.length} plants from database');
    } catch (e) {
      _errorMessage = 'Error fetching all plants: $e';
      _allPlants = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Select a plant from search results or list
  /// 
  /// Sets the current plant maintenance and generates alerts.
  void selectPlantMaintenance(PlantMaintenance plant) {
    _currentPlantMaintenance = plant;
    
    if (_currentWeather != null) {
      _weatherAlerts = PlantMaintenanceService.compareWithWeather(
        plant,
        _currentWeather!,
      );
    }

    _recommendations = PlantMaintenanceService.getPlantMaintenanceRecommendations(
      plant,
      _currentWeather,
    );

    notifyListeners();
  }

  /// Clear current plant selection
  void clearPlantMaintenanceSelection() {
    _currentPlantMaintenance = null;
    _weatherAlerts = [];
    _recommendations = {};
    notifyListeners();
  }

  /// Get weather comparison alerts for current plant
  /// 
  /// Returns empty list if no plant is selected or no weather data.
  List<WeatherAlert> getWeatherAlertsForPlant() {
    if (_currentPlantMaintenance == null || _currentWeather == null) {
      return [];
    }
    return PlantMaintenanceService.compareWithWeather(
      _currentPlantMaintenance!,
      _currentWeather!,
    );
  }

  /// Initialize with real weather data from user's location
  /// 
  /// Fetches current weather from WeatherProvider or user's saved location
  Future<void> initializeWithRealWeather(BuildContext context) async {
    try {
      print('🌍 Initializing with real weather data...');
      
      final weatherProvider = context.read<WeatherProvider>();
      final authProvider = context.read<AuthProvider>();
      
      // Try to use cached weather data first
      if (weatherProvider.currentWeather != null) {
        _currentWeather = weatherProvider.currentWeather!;
        print('✅ Using cached weather from provider: ${_currentWeather!.cityName}');
      } else {
        // Fetch fresh weather data
        final userLocation = authProvider.user?.location ?? 'London';
        await weatherProvider.fetchWeatherByCity(userLocation);
        
        if (weatherProvider.currentWeather != null) {
          _currentWeather = weatherProvider.currentWeather!;
          print('✅ Fetched fresh weather data: ${_currentWeather!.cityName}');
        } else {
          // Fallback to demo weather if API fails
          _initializeWithDemoWeather();
        }
      }
      
      notifyListeners();
    } catch (e) {
      print('❌ Error initializing real weather: $e');
      _initializeWithDemoWeather();
    }
  }

  /// Initialize with demo weather data as fallback
  /// 
  /// Call this when weather API is not available.
  void _initializeWithDemoWeather() {
    print('🎆 Using demo weather data as fallback');
    _currentWeather = WeatherData(
      cityName: 'Demo Location',
      temperature: 28.0,
      humidity: 65,
      rainfall: 0.0,
      condition: 'Partly Cloudy',
      windSpeed: 12.0,
      timestamp: DateTime.now(),
      description: 'Partly cloudy sky',
      feelsLike: 30.0,
      pressure: 1013,
      visibility: 10000,
      icon: '02d',
    );
    notifyListeners();
  }

  /// Update weather data manually
  /// 
  /// Use this to sync with WeatherProvider updates
  void updateWeatherData(WeatherData weather) {
    _currentWeather = weather;
    print('🔄 Weather data updated: ${weather.cityName}, ${weather.temperature}°C');
    notifyListeners();
  }

  /// Refresh weather data
  /// 
  /// Fetches latest weather data from API
  Future<void> refreshWeatherData(BuildContext context) async {
    try {
      final authProvider = context.read<AuthProvider>();
      final userLocation = authProvider.user?.location ?? 'London';
      
      final freshWeather = await WeatherService.getWeatherByCity(userLocation);
      _currentWeather = freshWeather;
      
      print('♾️ Weather data refreshed: ${freshWeather.cityName}');
      notifyListeners();
    } catch (e) {
      print('❌ Error refreshing weather: $e');
    }
  }

  /// Generate weather alerts for all user's plants
  /// 
  /// Fetches all user plants from 'plants' table, gets their maintenance data 
  /// from 'plant_maintenance' table, and generates weather alerts by comparing
  /// current weather with each plant's ideal conditions.
  /// Returns a map of plant name/nickname to list of alerts.
  Future<Map<String, List<WeatherAlert>>> generateAlertsForAllUserPlants(BuildContext context) async {
    final Map<String, List<WeatherAlert>> plantsWithAlerts = {};
    
    if (_currentWeather == null) {
      print('⚠️ No weather data available for generating alerts');
      return plantsWithAlerts;
    }

    try {
      // Get current user's plants from PlantProvider
      final plantProvider = context.read<PlantProvider>();
      final userPlants = plantProvider.plants;

      if (userPlants.isEmpty) {
        print('ℹ️ User has no plants added yet');
        _alertsByPlant = {};
        _weatherAlerts = [];
        notifyListeners();
        return plantsWithAlerts;
      }

      print('🔍 Checking weather alerts for ${userPlants.length} user plants...');

      // For each user plant, get maintenance data and generate alerts
      for (final plant in userPlants) {
        final scientificName = plant.scientificName;
        
        if (scientificName == null || scientificName.isEmpty) {
          print('⚠️ Skipping ${plant.plantName} - no scientific name');
          continue;
        }

        // Fetch maintenance data for this plant
        final maintenance = await PlantMaintenanceService.getPlantMaintenanceByScientificName(scientificName);
        
        if (maintenance != null) {
          // Generate weather alerts for this plant
          final alerts = PlantMaintenanceService.compareWithWeather(maintenance, _currentWeather!);
          
          // Store all alerts including optimal ones
          final displayName = plant.nickname ?? plant.plantName;
          plantsWithAlerts[displayName] = alerts;
          
          // Log non-optimal alerts
          final nonOptimalAlerts = alerts.where((alert) => alert.severity != AlertSeverity.success).toList();
          if (nonOptimalAlerts.isNotEmpty) {
            print('⚠️ Found ${nonOptimalAlerts.length} alert(s) for $displayName');
          }
        }
      }

      // Store grouped alerts and flatten for backward compatibility
      _alertsByPlant = plantsWithAlerts;
      _weatherAlerts = plantsWithAlerts.values.expand((alerts) => alerts).toList();
      
      print('✅ Generated alerts for ${plantsWithAlerts.length} plants');
      notifyListeners();
      
    } catch (e) {
      print('❌ Error generating alerts for all plants: $e');
    }

    return plantsWithAlerts;
  }

  /// Get all weather alerts as a flat list
  /// 
  /// Returns all weather alerts for all user plants
  List<WeatherAlert> getAllWeatherAlerts() {
    return _weatherAlerts;
  }

  /// Get critical and warning alerts only
  /// 
  /// Filters alerts to show only severe conditions
  List<WeatherAlert> getCriticalAlerts() {
    return _weatherAlerts.where((alert) => 
      alert.severity == AlertSeverity.critical || 
      alert.severity == AlertSeverity.warning
    ).toList();
  }
}
