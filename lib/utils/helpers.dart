import 'package:flutter/material.dart';
import '../config/theme.dart';

Color getHealthStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'healthy':
      return successGreen;
    case 'warning':
      return warningOrange;
    case 'critical':
      return errorRed;
    default:
      return textGray;
  }
}

Color getHealthStatusBackgroundColor(String status) {
  switch (status.toLowerCase()) {
    case 'healthy':
      return const Color(0xFFE8F5E9);
    case 'warning':
      return const Color(0xFFFFF3E0);
    case 'critical':
      return const Color(0xFFFFEBEE);
    default:
      return lightGray;
  }
}

String getHealthStatusMessage(String status) {
  switch (status.toLowerCase()) {
    case 'healthy':
      return 'Your plant is healthy!';
    case 'warning':
      return 'Needs attention soon';
    case 'critical':
      return 'Immediate action required!';
    default:
      return 'Unknown status';
  }
}

IconData getHealthStatusIcon(String status) {
  switch (status.toLowerCase()) {
    case 'healthy':
      return Icons.check_circle;
    case 'warning':
      return Icons.warning;
    case 'critical':
      return Icons.error;
    default:
      return Icons.help;
  }
}

String formatDate(DateTime date) {
  return '${date.day}/${date.month}/${date.year}';
}

String formatDateWithTime(DateTime date) {
  return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
}

String getRelativeTime(DateTime date) {
  final now = DateTime.now();
  final difference = now.difference(date);

  if (difference.inDays > 0) {
    return '${difference.inDays}d ago';
  } else if (difference.inHours > 0) {
    return '${difference.inHours}h ago';
  } else if (difference.inMinutes > 0) {
    return '${difference.inMinutes}m ago';
  } else {
    return 'just now';
  }
}

/// Calculate days remaining until a scheduled date
String getDaysUntil(DateTime targetDate) {
  final now = DateTime.now();
  final difference = targetDate.difference(now);
  
  if (difference.inDays == 0) {
    return 'Today';
  } else if (difference.inDays == 1) {
    return 'Tomorrow';
  } else if (difference.inDays < 0) {
    return 'Overdue';
  } else {
    return 'In ${difference.inDays} days';
  }
}

/// Format confidence score as percentage string
String formatConfidence(double confidence) {
  return '${confidence.toStringAsFixed(1)}%';
}
