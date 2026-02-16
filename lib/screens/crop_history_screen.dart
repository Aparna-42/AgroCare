import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/plant_provider.dart';
import '../widgets/custom_appbar.dart';
import '../utils/helpers.dart';

class CropHistoryScreen extends StatelessWidget {
  const CropHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Crop History',
        onLeadingPressed: () {
          if (context.canPop()) {
            context.pop();
          }
        },
      ),
      body: Consumer<PlantProvider>(
        builder: (context, plantProvider, _) {
          final plants = plantProvider.plants;

          return plants.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history_outlined,
                        size: 60,
                        color: textGray.withOpacity(0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No crop history',
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge!
                            .copyWith(color: textGray),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: plants.length,
                  itemBuilder: (context, index) {
                    final plant = plants[index];
                    return _buildHistoryCard(context, plant);
                  },
                );
        },
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, dynamic plant) {
    Color statusColor;
    Color statusBgColor;

    switch (plant.healthStatus.toLowerCase()) {
      case 'healthy':
        statusColor = successGreen;
        statusBgColor = const Color(0xFFE8F5E9);
        break;
      case 'warning':
        statusColor = warningOrange;
        statusBgColor = const Color(0xFFFFF3E0);
        break;
      case 'critical':
        statusColor = errorRed;
        statusBgColor = const Color(0xFFFFEBEE);
        break;
      default:
        statusColor = textGray;
        statusBgColor = lightGray;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plant.name,
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    plant.type,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall!
                        .copyWith(color: textGray),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  plant.healthStatus.replaceFirst(
                    plant.healthStatus[0],
                    plant.healthStatus[0].toUpperCase(),
                  ),
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: lightGray),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildHistoryInfo(
                  'Planted',
                  formatDate(plant.plantedDate),
                  Icons.calendar_today_outlined,
                ),
              ),
              Expanded(
                child: _buildHistoryInfo(
                  'Days',
                  '${plant.daysGrown}',
                  Icons.date_range_outlined,
                ),
              ),
              Expanded(
                child: _buildHistoryInfo(
                  'Location',
                  plant.location ?? 'N/A',
                  Icons.location_on_outlined,
                ),
              ),
            ],
          ),
          if (plant.disease != null) ...[
            const SizedBox(height: 12),
            Divider(color: lightGray),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Detected Issue',
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          fontWeight: FontWeight.w600,
                          color: errorRed,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    plant.disease,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall!
                        .copyWith(color: textGray),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryInfo(
    String label,
    String value,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: primaryGreen),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textDark,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w400,
              color: textGray,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
