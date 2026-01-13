import 'package:flutter/material.dart';
import '../config/theme.dart';

class HealthStatusIndicator extends StatelessWidget {
  final String status;
  final String? disease;
  final List<String> symptoms;

  const HealthStatusIndicator({
    super.key,
    required this.status,
    this.disease,
    required this.symptoms,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    Color bgColor;
    IconData icon;
    String message;

    switch (status.toLowerCase()) {
      case 'healthy':
        statusColor = successGreen;
        bgColor = const Color(0xFFE8F5E9);
        icon = Icons.check_circle;
        message = 'Your plant is healthy!';
        break;
      case 'warning':
        statusColor = warningOrange;
        bgColor = const Color(0xFFFFF3E0);
        icon = Icons.warning;
        message = 'Needs attention soon';
        break;
      case 'critical':
        statusColor = errorRed;
        bgColor = const Color(0xFFFFEBEE);
        icon = Icons.error;
        message = 'Immediate action required!';
        break;
      default:
        statusColor = textGray;
        bgColor = lightGray;
        icon = Icons.help;
        message = 'Unknown status';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: statusColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message,
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (disease != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        disease!,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall!
                            .copyWith(color: textGray),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (symptoms.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Symptoms:',
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          fontWeight: FontWeight.w600,
                          color: textDark,
                        ),
                  ),
                  const SizedBox(height: 6),
                  ...symptoms.map((symptom) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.circle,
                              size: 6,
                              color: textGray,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              symptom,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall!
                                  .copyWith(color: textGray),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
