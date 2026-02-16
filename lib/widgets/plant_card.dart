import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/plant.dart';
import '../utils/helpers.dart';
import '../providers/plant_provider.dart';

class PlantCard extends StatelessWidget {
  final Plant plant;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const PlantCard({
    super.key,
    required this.plant,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = getHealthStatusColor(plant.healthStatus);
    final statusBgColor = getHealthStatusBackgroundColor(plant.healthStatus);
    final statusIcon = getHealthStatusIcon(plant.healthStatus);
    final isLowConfidence = plant.confidence < 70.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: lightGreen,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    image: plant.imageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(plant.imageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: plant.imageUrl == null
                      ? const Center(
                          child: Icon(
                            Icons.eco,
                            size: 50,
                            color: primaryGreen,
                          ),
                        )
                      : null,
                ),
                // Delete button positioned at top-right
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => _showDeleteConfirmation(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plant.nickname ?? plant.plantName,
                              style:
                                  Theme.of(context).textTheme.titleLarge!.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            // Show scientific name if confidence >= 70%
                            if (isLowConfidence)
                              Text(
                                'Plant not identified',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall!
                                    .copyWith(
                                      color: warningOrange,
                                      fontStyle: FontStyle.italic,
                                    ),
                              )
                            else if (plant.scientificName != null)
                              Text(
                                plant.scientificName!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall!
                                    .copyWith(
                                      color: textGray,
                                      fontStyle: FontStyle.italic,
                                    ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusBgColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          statusIcon,
                          color: statusColor,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Show warning message if confidence < 70%
                  if (isLowConfidence)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: warningOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: warningOrange.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        'Try uploading a better image with improved clarity and lighting',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall!
                            .copyWith(
                              color: warningOrange,
                              height: 1.3,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  else
                    Row(
                      children: [
                        Icon(
                          Icons.verified,
                          size: 14,
                          color: textGray,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${plant.confidence.toStringAsFixed(1)}% confidence',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall!
                              .copyWith(color: textGray),
                        ),
                      ],
                    ),
                  // Show confidence for low confidence plants too
                  if (isLowConfidence)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 14,
                            color: textGray,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${plant.confidence.toStringAsFixed(1)}% confidence',
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
            ),
          ],
        ),
      ),
    );
  }

  /// Show delete confirmation dialog
  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Plant'),
        content: Text('Are you sure you want to delete ${plant.plantName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // Delete plant using provider
              final success = await context.read<PlantProvider>().removePlant(plant.id);
              if (context.mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${plant.plantName} deleted successfully'),
                      backgroundColor: successGreen,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  if (onDelete != null) {
                    onDelete!();
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to delete plant'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
