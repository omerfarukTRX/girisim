// lib/presentation/widgets/cards/recent_activity_card.dart

import 'package:flutter/material.dart';

class RecentActivityCard extends StatelessWidget {
  final String userName;
  final String action;
  final String deviceName;
  final String time;
  final bool success;

  const RecentActivityCard({
    super.key,
    required this.userName,
    required this.action,
    required this.deviceName,
    required this.time,
    this.success = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: success
              ? Colors.green.withOpacity(0.1)
              : Colors.red.withOpacity(0.1),
          child: Icon(
            success ? Icons.check : Icons.close,
            color: success ? Colors.green : Colors.red,
            size: 20,
          ),
        ),
        title: RichText(
          text: TextSpan(
            style: theme.textTheme.bodyMedium,
            children: [
              TextSpan(
                text: userName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              TextSpan(text: ' $deviceName '),
              TextSpan(
                text: action,
                style: TextStyle(
                  color: success ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        subtitle: Text(time),
        trailing: Icon(
          Icons.chevron_right,
          color: theme.colorScheme.onSurface.withOpacity(0.3),
        ),
      ),
    );
  }
}
