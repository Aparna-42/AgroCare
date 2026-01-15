import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/plant.dart';
import '../utils/helpers.dart';

class PlantCard extends StatelessWidget {
  final Plant plant;
  final VoidCallback onTap;

  const PlantCard({
    super.key,
    required this.plant,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = getHealthStatusColor(plant.healthStatus);
    final statusBgColor = getHealthStatusBackgroundColor(plant.healthStatus);
    final statusIcon = getHealthStatusIcon(plant.healthStatus);

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
                              plant.plantName,
                              style:
                                  Theme.of(context).textTheme.titleLarge!.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              plant.scientificName ?? 'Unknown species',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall!
                                  .copyWith(color: textGray),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
