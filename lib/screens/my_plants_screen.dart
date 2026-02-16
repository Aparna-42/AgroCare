import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../config/theme.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/plant_card.dart';
import '../providers/plant_provider.dart';

class MyPlantsScreen extends StatefulWidget {
  const MyPlantsScreen({super.key});

  @override
  State<MyPlantsScreen> createState() => _MyPlantsScreenState();
}

class _MyPlantsScreenState extends State<MyPlantsScreen> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // Fetch plants when screen loads
    Future.microtask(() {
      context.read<PlantProvider>().fetchPlants();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'My Plants',
        onLeadingPressed: () {
          if (context.canPop()) {
            context.pop();
          }
        },
      ),
      body: Consumer<PlantProvider>(
        builder: (context, plantProvider, _) {
          if (plantProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: primaryGreen),
            );
          }

          if (plantProvider.plants.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.eco,
                    size: 80,
                    color: lightGreen,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No Plants Yet',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall!
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add your first plant to get started!',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .copyWith(color: textGray),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/add-plant'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Plant'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            controller: _scrollController,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with plant count
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Collection',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge!
                                .copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${plantProvider.plants.length} plant${plantProvider.plants.length != 1 ? 's' : ''} total',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall!
                                .copyWith(color: textGray),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () => context.push('/add-plant'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                        ),
                        icon: const Icon(Icons.add, size: 20),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Stats row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatBox(
                        context,
                        '${plantProvider.plants.where((p) => p.healthStatus == 'healthy').length}',
                        'Healthy',
                        Icons.favorite,
                        successGreen,
                      ),
                      _buildStatBox(
                        context,
                        '${plantProvider.plants.where((p) => p.healthStatus == 'warning').length}',
                        'Warning',
                        Icons.warning,
                        warningOrange,
                      ),
                      _buildStatBox(
                        context,
                        '${plantProvider.plants.where((p) => p.healthStatus == 'critical').length}',
                        'Critical',
                        Icons.error,
                        Colors.red,
                      ),
                      _buildStatBox(
                        context,
                        '${plantProvider.plants.where((p) => p.confidence < 70).length}',
                        'Unconfirmed',
                        Icons.help_outline,
                        warningOrange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Plants grid
                  StaggeredGrid.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    children: [
                      ...plantProvider.plants.map((plant) => PlantCard(
                            plant: plant,
                            onTap: () => context.push('/plant/${plant.id}'),
                            onDelete: () {
                              // Refresh plants after deletion
                              context.read<PlantProvider>().fetchPlants();
                            },
                          )),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatBox(
    BuildContext context,
    String count,
    String label,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
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
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              count,
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
