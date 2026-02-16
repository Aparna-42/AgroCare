import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/plant_provider.dart';
import '../providers/maintenance_provider.dart';
import '../widgets/custom_appbar.dart';
import '../utils/helpers.dart';

class PlantDetailScreen extends StatefulWidget {
  final String plantId;

  const PlantDetailScreen({super.key, required this.plantId});

  @override
  State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Plant Details',
        onLeadingPressed: () {
          if (context.canPop()) {
            context.pop();
          }
        },
      ),
      body: Consumer2<PlantProvider, MaintenanceProvider>(
        builder: (context, plantProvider, maintenanceProvider, _) {
          final plant = plantProvider.getPlantById(widget.plantId);

          if (plant == null) {
            return const Center(child: Text('Plant not found'));
          }

          final tasks = maintenanceProvider.getTasksByPlantId(widget.plantId);

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Plant Image Section
                Container(
                  height: 250,
                  width: double.infinity,
                  color: lightGreen,
                  child: plant.imageUrl != null
                      ? Image.network(plant.imageUrl!, fit: BoxFit.cover)
                      : const Icon(Icons.eco, size: 100, color: primaryGreen),
                ),

                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Plant Name and Type
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                plant.nickname ?? plant.plantName,
                                style: Theme.of(context)
                                    .textTheme
                                    .displaySmall!
                                    .copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                plant.scientificName ?? 'Unknown species',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge!
                                    .copyWith(
                                      color: textGray,
                                      fontStyle: FontStyle.italic,
                                    ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.favorite_border),
                            onPressed: () {},
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Health Status
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: plant.healthStatus == 'healthy'
                              ? Colors.green.withOpacity(0.1)
                              : Colors.yellow.withOpacity(0.1),
                          border: Border.all(
                            color: plant.healthStatus == 'healthy'
                                ? Colors.green
                                : Colors.yellow,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              plant.healthStatus == 'healthy'
                                  ? Icons.check_circle
                                  : Icons.warning,
                              color: plant.healthStatus == 'healthy'
                                  ? Colors.green
                                  : Colors.yellow,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${plant.healthStatus.toUpperCase()} Plant',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Plant Info Grid
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        children: [
                          _buildInfoTile(
                            context,
                            'Confidence',
                            '${plant.confidence.toStringAsFixed(1)}%',
                            Icons.verified,
                          ),
                          _buildInfoTile(
                            context,
                            'Added',
                            formatDate(plant.createdAt ?? DateTime.now()),
                            Icons.date_range_outlined,
                          ),
                          if (plant.careWater != null)
                            _buildInfoTile(
                              context,
                              'Watering',
                              plant.careWater ?? 'Not specified',
                              Icons.opacity,
                            ),
                          _buildInfoTile(
                            context,
                            'Status',
                            plant.healthStatus,
                            Icons.health_and_safety_outlined,
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Maintenance Tasks
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Maintenance Tasks',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall!
                                .copyWith(fontWeight: FontWeight.bold),
                          ),
                          TextButton(
                            onPressed: () => context.go('/maintenance'),
                            child: const Text('View All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (tasks.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: lightGray,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.assignment_outlined,
                                size: 40,
                                color: textGray,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No tasks assigned',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .copyWith(color: textGray),
                              ),
                            ],
                          ),
                        )
                      else
                        ...tasks.map((task) => _buildTaskCard(context, task)),
                      const SizedBox(height: 20),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {},
                              child: const Text('Edit'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {},
                              child: const Text('Add Task'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoTile(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: lightGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primaryGreen, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: textGray,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.w600,
                  color: textDark,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, dynamic task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: lightGray),
      ),
      child: Row(
        children: [
          Checkbox(
            value: task.isCompleted,
            onChanged: (value) {
              if (value != null) {
                context.read<MaintenanceProvider>().completeTask(task.id, value);
              }
            },
          ),
          const SizedBox(width: 8),
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
        ],
      ),
    );
  }
}
