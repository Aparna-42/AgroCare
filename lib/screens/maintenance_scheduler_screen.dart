import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../config/theme.dart';
import '../providers/maintenance_provider.dart';
import '../providers/plant_provider.dart';
import '../providers/weather_provider.dart';
import '../providers/auth_provider.dart';
import '../models/maintenance_task.dart';
import '../models/plant.dart';
import '../models/plant_maintenance.dart';
import '../models/user_settings.dart';
import '../models/weather_data.dart';
import '../services/plant_maintenance_service.dart';
import '../widgets/custom_appbar.dart';

/// MaintenanceSchedulerScreen
/// 
/// Displays plant maintenance information from the Supabase `plant_maintenance` table.
/// Features include:
/// - Plant selection with search functionality
/// - Display of optimal growing conditions
/// - Weather-based alerts and recommendations
/// - Weekly task scheduling
class MaintenanceSchedulerScreen extends StatefulWidget {
  const MaintenanceSchedulerScreen({super.key});

  @override
  State<MaintenanceSchedulerScreen> createState() =>
      _MaintenanceSchedulerScreenState();
}

class _MaintenanceSchedulerScreenState extends State<MaintenanceSchedulerScreen>
    with SingleTickerProviderStateMixin {
  bool _isInitialized = false;
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    final maintenanceProvider = context.read<MaintenanceProvider>();
    final weatherProvider = context.read<WeatherProvider>();
    final authProvider = context.read<AuthProvider>();
    final plantProvider = context.read<PlantProvider>();
    
    await maintenanceProvider.fetchUserSettings();
    await maintenanceProvider.fetchTasks();
    await maintenanceProvider.fetchAllPlantsFromDatabase();
    
    // Fetch user's plants for alert generation
    await plantProvider.fetchPlants();
    
    // Initialize with real weather data from user's location
    if (weatherProvider.currentWeather != null) {
      // Use cached weather data
      maintenanceProvider.updateWeatherData(weatherProvider.currentWeather!);
      print('✅ Using cached weather data: ${weatherProvider.currentWeather!.cityName}');
    } else {
      // Fetch fresh weather data for user's location
      final userLocation = authProvider.user?.location ?? 'London';
      print('🌍 Fetching weather for user location: $userLocation');
      
      try {
        await weatherProvider.fetchWeatherByCity(userLocation);
        if (weatherProvider.currentWeather != null) {
          maintenanceProvider.updateWeatherData(weatherProvider.currentWeather!);
          print('✅ Fresh weather data loaded for: $userLocation');
        } else {
          // Initialize with real weather through context
          await maintenanceProvider.initializeWithRealWeather(context);
        }
      } catch (e) {
        print('❌ Error fetching weather, using fallback: $e');
        await maintenanceProvider.initializeWithRealWeather(context);
      }
    }
    
    // Generate weather alerts for all user plants automatically
    await maintenanceProvider.generateAlertsForAllUserPlants(context);
    print('✅ Weather alerts generated for all plants');
    
    setState(() {
      _isInitialized = true;
    });
  }

  Future<void> _generateTasks() async {
    final maintenanceProvider = context.read<MaintenanceProvider>();
    final plantProvider = context.read<PlantProvider>();
    final weatherProvider = context.read<WeatherProvider>();
    final authProvider = context.read<AuthProvider>();

    if (plantProvider.plants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Add some plants first to generate tasks'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    await maintenanceProvider.clearAllTasks();

    // Use real location from user profile or weather data
    final location = authProvider.user?.location ?? 
                    weatherProvider.currentWeather?.cityName ?? 
                    'London';

    print('📍 Generating tasks for location: $location');

    // Ensure we have current weather data
    WeatherData? currentWeather = weatherProvider.currentWeather;
    if (currentWeather == null) {
      try {
        print('🔄 Fetching fresh weather data for task generation...');
        await weatherProvider.fetchWeatherByCity(location);
        currentWeather = weatherProvider.currentWeather;
        
        if (currentWeather != null) {
          maintenanceProvider.updateWeatherData(currentWeather);
          print('✅ Updated weather data: ${currentWeather.cityName}, ${currentWeather.temperature}°C');
        }
      } catch (e) {
        print('❌ Error fetching weather for task generation: $e');
      }
    }

    await maintenanceProvider.saveUserSettings(
      maintenanceProvider.userSettings?.copyWith(availableDaysPerWeek: 7) ??
      UserSettings(
        id: const Uuid().v4(),
        userId: maintenanceProvider.userId ?? '',
        availableDaysPerWeek: 7,
      ),
    );

    final success = await maintenanceProvider.generateMonthlyTasks(
      plants: plantProvider.plants,
      weatherData: currentWeather, // Use real weather data
      location: location,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Monthly tasks generated with real weather data from $location!'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(maintenanceProvider.errorMessage ?? 'Failed to generate tasks'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Group tasks by day number for the entire month (28 days)
  Map<int, List<MaintenanceTask>> _groupTasksByDay(List<MaintenanceTask> tasks) {
    final Map<int, List<MaintenanceTask>> grouped = {};
    final today = DateTime.now();
    final daysToMonday = today.weekday - 1;
    final startOfWeek = today.subtract(Duration(days: daysToMonday));

    // Initialize for 28 days (4 weeks)
    for (int i = 1; i <= 28; i++) {
      grouped[i] = [];
    }

    for (final task in tasks) {
      final daysDiff = task.scheduledDate.difference(startOfWeek).inDays + 1;
      if (daysDiff >= 1 && daysDiff <= 28) {
        grouped[daysDiff]!.add(task);
      }
    }

    return grouped;
  }

  // Group tasks by week (1-4)
  Map<int, Map<int, List<MaintenanceTask>>> _groupTasksByWeek(List<MaintenanceTask> tasks) {
    final tasksByDay = _groupTasksByDay(tasks);
    final Map<int, Map<int, List<MaintenanceTask>>> weeklyTasks = {};

    for (int week = 1; week <= 4; week++) {
      weeklyTasks[week] = {};
      for (int dayInWeek = 1; dayInWeek <= 7; dayInWeek++) {
        final dayNumber = (week - 1) * 7 + dayInWeek;
        weeklyTasks[week]![dayInWeek] = tasksByDay[dayNumber] ?? [];
      }
    }

    return weeklyTasks;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Plant Maintenance',
        onLeadingPressed: () {
          if (context.canPop()) {
            context.pop();
          }
        },
      ),
      body: !_isInitialized
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Tab Bar
                Container(
                  color: white,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: primaryGreen,
                    unselectedLabelColor: textGray,
                    indicatorColor: primaryGreen,
                    tabs: const [
                      Tab(icon: Icon(Icons.eco), text: 'Plant Guide'),
                      Tab(icon: Icon(Icons.schedule), text: 'Schedule'),
                      Tab(icon: Icon(Icons.notifications), text: 'Alerts'),
                    ],
                  ),
                ),
                // Tab Views
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPlantGuideTab(),
                      _buildScheduleTab(),
                      _buildAlertsTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // ============================================================
  // TAB 1: PLANT GUIDE (Search & View Plant Maintenance Data)
  // ============================================================
  Widget _buildPlantGuideTab() {
    return Consumer<MaintenanceProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            // Search Section
            _buildSearchSection(provider),
            
            // Content
            Expanded(
              child: provider.currentPlantMaintenance == null
                  ? _buildPlantSelectionView(provider)
                  : _buildPlantMaintenanceDetails(provider),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchSection(MaintenanceProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Search Plant Database',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Enter plant name (e.g., Tomato, Rose)',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        provider.clearPlantMaintenanceSelection();
                        setState(() {});
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) {
              setState(() {});
              if (value.length >= 2) {
                provider.searchPlantsInDatabase(value);
              }
            },
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                provider.fetchPlantMaintenanceByCommonName(value);
              }
            },
          ),
          
          // Search Results Dropdown
          if (provider.searchResults.isNotEmpty && _searchController.text.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: lightGray),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: provider.searchResults.length,
                itemBuilder: (context, index) {
                  final plant = provider.searchResults[index];
                  return ListTile(
                    leading: const Icon(Icons.eco, color: primaryGreen),
                    title: Text(plant.commonName),
                    subtitle: Text(
                      plant.scientificName,
                      style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                    onTap: () {
                      _searchController.text = plant.commonName;
                      provider.selectPlantMaintenance(plant);
                      FocusScope.of(context).unfocus();
                      setState(() {});
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlantSelectionView(MaintenanceProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Instructions Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primaryGreen, accentGreen],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.eco, size: 40, color: white),
                const SizedBox(height: 12),
                const Text(
                  'Plant Maintenance Guide',
                  style: TextStyle(
                    color: white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Search for a plant to view its optimal growing conditions, '
                  'maintenance schedule, and weather-based recommendations.',
                  style: TextStyle(color: white.withOpacity(0.9), fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // User's Plants Quick Selection
          Consumer<PlantProvider>(
            builder: (context, plantProvider, _) {
              if (plantProvider.plants.isEmpty) return const SizedBox.shrink();
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Plants',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: plantProvider.plants.length,
                      itemBuilder: (context, index) {
                        final plant = plantProvider.plants[index];
                        return GestureDetector(
                          onTap: () {
                            if (plant.scientificName != null) {
                              provider.fetchPlantMaintenance(plant.scientificName!);
                            } else {
                              provider.fetchPlantMaintenanceByCommonName(plant.plantName);
                            }
                            _searchController.text = plant.nickname ?? plant.plantName;
                          },
                          child: Container(
                            width: 90,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: lightGray),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.eco, color: primaryGreen, size: 30),
                                const SizedBox(height: 8),
                                Text(
                                  plant.nickname ?? plant.plantName,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              );
            },
          ),

          // Popular Plants from Database
          const Text(
            'Popular Plants',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          if (provider.allPlants.isEmpty)
            const Center(child: Text('Loading plants database...'))
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
              ),
              itemCount: provider.allPlants.length > 6 ? 6 : provider.allPlants.length,
              itemBuilder: (context, index) {
                final plant = provider.allPlants[index];
                return _buildPlantCard(plant, provider);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPlantCard(PlantMaintenance plant, MaintenanceProvider provider) {
    return GestureDetector(
      onTap: () {
        provider.selectPlantMaintenance(plant);
        _searchController.text = plant.commonName;
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: lightGray),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                const Icon(Icons.eco, color: primaryGreen, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    plant.commonName,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              plant.scientificName,
              style: const TextStyle(fontSize: 10, color: textGray, fontStyle: FontStyle.italic),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.thermostat, size: 12, color: textGray),
                const SizedBox(width: 4),
                Text(
                  '${plant.minTempC.toInt()}-${plant.maxTempC.toInt()}°C',
                  style: const TextStyle(fontSize: 10, color: textGray),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlantMaintenanceDetails(MaintenanceProvider provider) {
    final plant = provider.currentPlantMaintenance!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Plant Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [primaryGreen, accentGreen]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.eco, size: 35, color: white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plant.commonName,
                        style: const TextStyle(
                          color: white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        plant.scientificName,
                        style: TextStyle(
                          color: white.withOpacity(0.9),
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: white),
                  onPressed: () {
                    provider.clearPlantMaintenanceSelection();
                    _searchController.clear();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Weather Alert Preview
          if (provider.weatherAlerts.isNotEmpty)
            _buildAlertPreview(provider.weatherAlerts.first),
          
          const SizedBox(height: 16),

          // Optimal Conditions
          const Text(
            'Optimal Growing Conditions',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildConditionCard('Temperature', plant.temperatureRange, Icons.thermostat, Colors.red),
              _buildConditionCard('Humidity', plant.humidityRange, Icons.water_drop, Colors.blue),
              _buildConditionCard('Sunlight', plant.sunlightRequirement, Icons.wb_sunny, Colors.orange),
              _buildConditionCard('Soil Type', plant.soilType, Icons.grass, Colors.brown),
            ],
          ),
          const SizedBox(height: 20),

          // Care Summary
          const Text(
            'Care Summary',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          _buildCareItem('Watering', plant.wateringSchedule, Icons.opacity, Colors.blue),
          _buildCareItem('Fertilizing', plant.fertilizationSchedule, Icons.science, Colors.green),
          _buildCareItem('Pruning', plant.pruningSchedule, Icons.content_cut, Colors.purple),

          // Notes
          if (plant.maintenanceNotes != null && plant.maintenanceNotes!.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'Additional Notes',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: lightGray,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: primaryGreen),
                  const SizedBox(width: 12),
                  Expanded(child: Text(plant.maintenanceNotes!)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConditionCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: lightGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(title, style: const TextStyle(color: textGray, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildCareItem(String title, String description, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: lightGray),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text(description, style: const TextStyle(color: textGray, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertPreview(WeatherAlert alert) {
    Color alertColor;
    switch (alert.severity) {
      case AlertSeverity.success:
        alertColor = Colors.green;
        break;
      case AlertSeverity.info:
        alertColor = Colors.blue;
        break;
      case AlertSeverity.warning:
        alertColor = Colors.orange;
        break;
      case AlertSeverity.critical:
        alertColor = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: alertColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: alertColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(_getAlertIcon(alert.type), color: alertColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  style: TextStyle(fontWeight: FontWeight.w600, color: alertColor),
                ),
                Text(alert.message, style: const TextStyle(fontSize: 12, color: textGray)),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _tabController.animateTo(2),
            child: const Text('View'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TAB 2: SCHEDULE (Monthly Tasks - 4 Weeks)
  // ============================================================
  Widget _buildScheduleTab() {
    return Consumer<MaintenanceProvider>(
      builder: (context, maintenanceProvider, _) {
        final plantProvider = context.watch<PlantProvider>();
        final tasks = maintenanceProvider.tasks;
        final tasksByWeek = _groupTasksByWeek(tasks);

        return Column(
          children: [
            // Monthly Schedule Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryGreen.withOpacity(0.1), Colors.orange.withOpacity(0.1)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Monthly Care Schedule',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Based on your plants\' care requirements',
                    style: TextStyle(color: primaryGreen.withOpacity(0.8), fontSize: 13),
                  ),
                ],
              ),
            ),

            // Tasks List - 4 Weeks
            Expanded(
              child: maintenanceProvider.isLoading || maintenanceProvider.isGeneratingTasks
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Generating optimized schedule...'),
                        ],
                      ),
                    )
                  : tasks.isEmpty
                      ? _buildEmptySchedule(plantProvider)
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: 4, // 4 weeks
                          itemBuilder: (context, weekIndex) {
                            final weekNumber = weekIndex + 1;
                            final weekTasks = tasksByWeek[weekNumber] ?? {};
                            
                            return _buildWeekCard(
                              context,
                              weekNumber,
                              weekTasks,
                              plantProvider,
                              maintenanceProvider,
                            );
                          },
                        ),
            ),

            // Generate Tasks Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: maintenanceProvider.isGeneratingTasks ? null : _generateTasks,
                icon: maintenanceProvider.isGeneratingTasks 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.calendar_month),
                label: Text(maintenanceProvider.isGeneratingTasks 
                    ? 'Generating...' 
                    : 'Generate Monthly Schedule'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWeekCard(
    BuildContext context,
    int weekNumber,
    Map<int, List<MaintenanceTask>> weekTasks,
    PlantProvider plantProvider,
    MaintenanceProvider maintenanceProvider,
  ) {
    final today = DateTime.now();
    final daysToMonday = today.weekday - 1;
    final startOfMonth = today.subtract(Duration(days: daysToMonday));
    final weekStartDate = startOfMonth.add(Duration(days: (weekNumber - 1) * 7));
    final weekEndDate = weekStartDate.add(const Duration(days: 6));
    
    // Calculate total tasks for this week
    int totalTasks = 0;
    int completedTasks = 0;
    for (var dayTasks in weekTasks.values) {
      totalTasks += dayTasks.length;
      completedTasks += dayTasks.where((t) => t.isCompleted).length;
    }
    
    // Check if this is current week
    final isCurrentWeek = today.isAfter(weekStartDate.subtract(const Duration(days: 1))) &&
                          today.isBefore(weekEndDate.add(const Duration(days: 1)));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentWeek ? primaryGreen : Colors.grey.shade300,
          width: isCurrentWeek ? 2 : 1,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: isCurrentWeek,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.only(bottom: 16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isCurrentWeek ? primaryGreen : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Week $weekNumber',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isCurrentWeek ? white : textDark,
                    fontSize: 12,
                  ),
                ),
              ),
              if (isCurrentWeek) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'CURRENT',
                    style: TextStyle(color: white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Text(
                  '${DateFormat('MMM d').format(weekStartDate)} - ${DateFormat('MMM d').format(weekEndDate)}',
                  style: const TextStyle(fontSize: 12, color: textGray),
                ),
                const Spacer(),
                Text(
                  '$completedTasks/$totalTasks tasks',
                  style: TextStyle(
                    fontSize: 12,
                    color: completedTasks == totalTasks && totalTasks > 0 ? Colors.green : textGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          children: [
            for (int dayInWeek = 1; dayInWeek <= 7; dayInWeek++)
              _buildDayInWeek(
                context,
                weekNumber,
                dayInWeek,
                weekTasks[dayInWeek] ?? [],
                plantProvider,
                maintenanceProvider,
                startOfMonth,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayInWeek(
    BuildContext context,
    int weekNumber,
    int dayInWeek,
    List<MaintenanceTask> tasks,
    PlantProvider plantProvider,
    MaintenanceProvider maintenanceProvider,
    DateTime startOfMonth,
  ) {
    final dayIndex = (weekNumber - 1) * 7 + (dayInWeek - 1);
    final dayDate = startOfMonth.add(Duration(days: dayIndex));
    final today = DateTime.now();
    final isToday = DateFormat('yyyy-MM-dd').format(dayDate) == 
                    DateFormat('yyyy-MM-dd').format(today);
    final dayName = DateFormat('EEE').format(dayDate);
    final dateStr = DateFormat('d').format(dayDate);

    if (tasks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Container(
              width: 45,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isToday ? primaryGreen.withOpacity(0.1) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    dayName,
                    style: TextStyle(
                      fontSize: 10,
                      color: isToday ? primaryGreen : textGray,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isToday ? primaryGreen : textDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Text('No tasks', style: TextStyle(color: textGray, fontSize: 13)),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isToday ? primaryGreen.withOpacity(0.05) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: isToday ? Border.all(color: primaryGreen.withOpacity(0.3)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 45,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: isToday ? primaryGreen : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      dayName,
                      style: TextStyle(
                        fontSize: 10,
                        color: isToday ? white : textGray,
                      ),
                    ),
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isToday ? white : textDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${tasks.length} task${tasks.length > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isToday ? primaryGreen : textDark,
                  ),
                ),
              ),
              if (isToday)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: primaryGreen,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'TODAY',
                    style: TextStyle(color: white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ...tasks.map((task) {
            final plant = plantProvider.plants.firstWhere(
              (p) => p.id == task.plantId,
              orElse: () => plantProvider.plants.isNotEmpty 
                  ? plantProvider.plants.first 
                  : Plant(id: '', userId: '', plantName: 'Unknown', confidence: 0),
            );
            return _buildCompactTaskItem(task, plant, maintenanceProvider);
          }),
        ],
      ),
    );
  }

  Widget _buildCompactTaskItem(
    MaintenanceTask task,
    Plant plant,
    MaintenanceProvider provider,
  ) {
    IconData icon;
    Color iconColor;
    
    switch (task.taskType.toLowerCase()) {
      case 'watering':
        icon = Icons.water_drop;
        iconColor = Colors.blue;
        break;
      case 'fertilizing':
        icon = Icons.science;
        iconColor = Colors.green;
        break;
      case 'pruning':
        icon = Icons.content_cut;
        iconColor = Colors.purple;
        break;
      case 'pest_control':
        icon = Icons.bug_report;
        iconColor = Colors.orange;
        break;
      default:
        icon = Icons.check_circle_outline;
        iconColor = primaryGreen;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: task.isCompleted,
              activeColor: primaryGreen,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onChanged: (bool? value) {
                if (value != null) {
                  provider.completeTask(task.id, value);
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              task.description,
              style: TextStyle(
                fontSize: 13,
                decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                color: task.isCompleted ? textGray : textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySchedule(PlantProvider plantProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'No tasks scheduled yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              plantProvider.plants.isEmpty
                  ? 'Add some plants first to generate tasks'
                  : 'Tap the button below to generate weekly tasks',
              textAlign: TextAlign.center,
              style: const TextStyle(color: textGray),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayCard(
    BuildContext context,
    int dayNumber,
    DateTime dayDate,
    List<MaintenanceTask> tasks,
    PlantProvider plantProvider,
    MaintenanceProvider maintenanceProvider,
    bool isToday,
  ) {
    final dayName = DateFormat('EEEE').format(dayDate);
    final dateStr = DateFormat('MMM d').format(dayDate);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isToday ? primaryGreen : Colors.grey.shade300,
          width: isToday ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isToday 
                    ? [primaryGreen, primaryGreen.withOpacity(0.8)]
                    : [Colors.grey.shade100, Colors.grey.shade50],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isToday ? white : primaryGreen,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Day $dayNumber',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isToday ? primaryGreen : white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dayName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isToday ? white : textDark,
                          ),
                        ),
                        Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 12,
                            color: isToday ? white.withOpacity(0.9) : textGray,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (isToday)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'TODAY',
                      style: TextStyle(color: white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),

          // Tasks List
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: tasks.map((task) {
                final plant = plantProvider.plants.firstWhere(
                  (p) => p.id == task.plantId,
                  orElse: () => plantProvider.plants.first,
                );
                
                return _buildTaskItem(context, task, plant, maintenanceProvider);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(
    BuildContext context,
    MaintenanceTask task,
    dynamic plant,
    MaintenanceProvider provider,
  ) {
    IconData icon;
    Color iconColor;
    
    switch (task.taskType.toLowerCase()) {
      case 'watering':
        icon = Icons.water_drop;
        iconColor = Colors.blue;
        break;
      case 'fertilizing':
        icon = Icons.grass;
        iconColor = Colors.orange;
        break;
      case 'pruning':
        icon = Icons.content_cut;
        iconColor = Colors.purple;
        break;
      case 'pest_control':
        icon = Icons.bug_report;
        iconColor = Colors.red;
        break;
      default:
        icon = Icons.check_circle_outline;
        iconColor = primaryGreen;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Checkbox(
            value: task.isCompleted,
            activeColor: primaryGreen,
            onChanged: (bool? value) {
              if (value != null) {
                provider.completeTask(task.id, value);
              }
            },
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.description,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                    color: task.isCompleted ? textGray : textDark,
                  ),
                ),
                if (task.notes != null && task.notes!.isNotEmpty)
                  Text(
                    task.notes!,
                    style: const TextStyle(fontSize: 12, color: textGray),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TAB 3: ALERTS (Weather Comparison)
  // ============================================================
  Widget _buildAlertsTab() {
    return Consumer<MaintenanceProvider>(
      builder: (context, provider, _) {
        final alertsByPlant = provider.alertsByPlant;
        final weather = provider.currentWeather;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current Weather Card
              if (weather != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.blue.shade400, Colors.blue.shade600]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Weather',
                        style: TextStyle(color: white, fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildWeatherItem('${weather.temperature.toStringAsFixed(1)}°C', 'Temperature', Icons.thermostat),
                          _buildWeatherItem('${weather.humidity}%', 'Humidity', Icons.water_drop),
                          _buildWeatherItem('${weather.windSpeed.toStringAsFixed(1)} km/h', 'Wind', Icons.air),
                        ],
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),

              // Weather Alerts
              const Text(
                'Weather Alerts',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),

              // Show alerts for all plants
              if (alertsByPlant.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: lightGray,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'No plants added yet. Add plants to see weather alerts.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                // Display alerts grouped by plant
                ...alertsByPlant.entries.map((entry) {
                  final plantName = entry.key;
                  final alerts = entry.value;
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Plant name header
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8, top: 12),
                        child: Row(
                          children: [
                            const Icon(Icons.eco, color: accentGreen, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              plantName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Alerts for this plant
                      ...alerts.map((alert) => _buildAlertCard(alert)).toList(),
                      const SizedBox(height: 8),
                    ],
                  );
                }).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWeatherItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: white, size: 24),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: white, fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: TextStyle(color: white.withOpacity(0.8), fontSize: 12)),
      ],
    );
  }

  Widget _buildAlertCard(WeatherAlert alert) {
    Color alertColor;
    switch (alert.severity) {
      case AlertSeverity.success:
        alertColor = Colors.green;
        break;
      case AlertSeverity.info:
        alertColor = Colors.blue;
        break;
      case AlertSeverity.warning:
        alertColor = Colors.orange;
        break;
      case AlertSeverity.critical:
        alertColor = Colors.red;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: alertColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: alertColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_getAlertIcon(alert.type), color: alertColor, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  alert.title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: alertColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(alert.message, style: const TextStyle(color: textGray)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline, size: 18, color: alertColor),
                const SizedBox(width: 8),
                Expanded(child: Text(alert.recommendation, style: const TextStyle(fontSize: 13))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getAlertIcon(AlertType type) {
    switch (type) {
      case AlertType.optimal:
        return Icons.check_circle;
      case AlertType.tempHigh:
        return Icons.thermostat;
      case AlertType.tempLow:
        return Icons.ac_unit;
      case AlertType.humidityHigh:
        return Icons.water_drop;
      case AlertType.humidityLow:
        return Icons.water_drop_outlined;
      case AlertType.windHigh:
        return Icons.air;
    }
  }
}
