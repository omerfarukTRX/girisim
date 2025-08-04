// lib/presentation/widgets/cards/door_control_card.dart

import 'package:flutter/material.dart';
import '../../../data/models/device_model.dart';

class DoorControlCard extends StatelessWidget {
  final DeviceModel device;
  final VoidCallback onControl;

  const DoorControlCard({
    super.key,
    required this.device,
    required this.onControl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOnline = device.status == DeviceStatus.online;
    final isOpen = device.isOpen ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: isOnline ? onControl : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Cihaz durumu
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isOnline
                      ? (isOpen ? Colors.orange : Colors.green).withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(
                  isOpen ? Icons.lock_open : Icons.lock,
                  size: 28,
                  color: isOnline
                      ? (isOpen ? Colors.orange : Colors.green)
                      : Colors.grey,
                ),
              ),
              const SizedBox(width: 16),

              // Cihaz bilgileri
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 8,
                          color: isOnline ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isOnline ? 'Çevrimiçi' : 'Çevrimdışı',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isOnline ? Colors.green : Colors.grey,
                          ),
                        ),
                        if (isOnline) ...[
                          const SizedBox(width: 12),
                          Text(
                            '• ${isOpen ? "Açık" : "Kapalı"}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isOpen ? Colors.orange : Colors.green,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Kontrol butonu
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isOnline
                      ? theme.colorScheme.primary.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.power_settings_new,
                  color: isOnline ? theme.colorScheme.primary : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
