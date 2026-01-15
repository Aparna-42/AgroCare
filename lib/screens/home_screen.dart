import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/plant_provider.dart';
import '../providers/maintenance_provider.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/plant_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Fetch plants when home screen loads
    Future.microtask(() {
      context.read<PlantProvider>().fetchPlants();
      context.read<MaintenanceProvider>().fetchTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return Consumer2<PlantProvider, MaintenanceProvider>(
            builder: (context, plantProvider, maintenanceProvider, _) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    DashboardHeader(userName: authProvider.user?.name),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Quick Stats Section
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  context,
                                  'Total Plants',
                                  '${plantProvider.plants.length}',
                                  Icons.eco,
                                  accentGreen,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  context,
                                  'Tasks Today',
                                  '${maintenanceProvider.pendingTasks.length}',
                                  Icons.assignment,
                                  warningOrange,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  context,
                                  'Healthy',
                                  '${plantProvider.plants.where((p) => p.healthStatus == 'healthy').length}',
                                  Icons.favorite,
                                  successGreen,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),

                          // Feature Quick Access
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildFeatureButton(
                                context,
                                'Add Plant',
                                Icons.add_circle,
                                () => context.push('/add-plant'),
                              ),
                              _buildFeatureButton(
                                context,
                                'Plant Health',
                                Icons.image_search,
                                () => context.push('/plant-health'),
                              ),
                              _buildFeatureButton(
                                context,
                                'Maintenance',
                                Icons.schedule,
                                () => context.push('/maintenance'),
                              ),
                              _buildFeatureButton(
                                context,
                                'Weather',
                                Icons.cloud,
                                () => context.push('/weather'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),

                          // My Plants Section
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'My Plants',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall!
                                    .copyWith(fontWeight: FontWeight.bold),
                              ),
                              TextButton(
                                onPressed: () {},
                                child: const Text('See All'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          StaggeredGrid.count(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            children: [
                              ...plantProvider.plants.take(4).map((plant) =>
                                  PlantCard(
                                    plant: plant,
                                    onTap: () =>
                                        context.push('/plant/${plant.id}'),
                                  )),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Upcoming Tasks Section
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Upcoming Tasks',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall!
                                    .copyWith(fontWeight: FontWeight.bold),
                              ),
                              TextButton(
                                onPressed: () =>
                                    context.go('/maintenance'),
                                child: const Text('See All'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...maintenanceProvider.pendingTasks.take(3).map(
                              (task) => _buildTaskTile(context, task)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          switch (index) {
            case 0:
              context.go('/home');
              break;
            case 1:
              context.push('/plant-health');
              break;
            case 2:
              context.push('/weather');
              break;
            case 3:
              context.push('/profile');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.eco_outlined),
            label: 'Plants',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.cloud_outlined),
            label: 'Weather',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodySmall!
                .copyWith(color: textGray),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: lightGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: primaryGreen,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodySmall!
                .copyWith(fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTaskTile(BuildContext context, dynamic task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: lightGray),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: lightGreen,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.assignment_outlined,
              color: primaryGreen,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.taskType.toString().toUpperCase(),
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        fontWeight: FontWeight.w600,
                        color: primaryGreen,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  task.description,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall!
                      .copyWith(color: textGray),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16, color: textGray),
        ],
      ),
    );
  }
}
