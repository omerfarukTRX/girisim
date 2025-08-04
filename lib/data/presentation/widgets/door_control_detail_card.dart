// lib/presentation/widgets/cards/door_control_detail_card.dart

import 'package:flutter/material.dart';
import '../../../data/models/device_model.dart';

class DoorControlDetailCard extends StatelessWidget {
  final DeviceModel device;
  final VoidCallback onControl;
  final VoidCallback onFavorite;
  final bool isFavorite;

  const DoorControlDetailCard({
    super.key,
    required this.device,
    required this.onControl,
    required this.onFavorite,
    this.isFavorite = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOnline = device.status == DeviceStatus.online;
    final isOpen = device.isOpen ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: isOnline ? onControl : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: isOnline
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.surface,
                      theme.colorScheme.primary.withOpacity(0.02),
                    ],
                  )
                : null,
          ),
          child: Row(
            children: [
              // Cihaz durumu göstergesi
              _buildStatusIndicator(theme, isOnline, isOpen),
              const SizedBox(width: 16),

              // Cihaz bilgileri
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            device.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isOnline ? null : Colors.grey,
                            ),
                          ),
                        ),
                        // Favori butonu
                        IconButton(
                          onPressed: onFavorite,
                          icon: Icon(
                            isFavorite ? Icons.star : Icons.star_border,
                            color: isFavorite ? Colors.amber : null,
                          ),
                          iconSize: 20,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Durum
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isOnline
                                ? Colors.green.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.circle,
                                size: 6,
                                color: isOnline ? Colors.green : Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isOnline ? 'Çevrimiçi' : 'Çevrimdışı',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isOnline ? Colors.green : Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (isOnline) ...[
                          const SizedBox(width: 8),
                          // Kapı durumu
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isOpen
                                  ? Colors.orange.withOpacity(0.1)
                                  : Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isOpen ? Icons.lock_open : Icons.lock,
                                  size: 12,
                                  color: isOpen ? Colors.orange : Colors.blue,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isOpen ? 'Açık' : 'Kapalı',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isOpen ? Colors.orange : Colors.blue,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),

                    // Ek bilgiler
                    if (device.batteryLevel != null ||
                        device.signalStrength != null ||
                        device.lastSeenAt != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (device.batteryLevel != null) ...[
                            _InfoItem(
                              icon: Icons.battery_full,
                              value: '${device.batteryLevel}%',
                              color: _getBatteryColor(device.batteryLevel!),
                            ),
                            const SizedBox(width: 12),
                          ],
                          if (device.signalStrength != null) ...[
                            _InfoItem(
                              icon: Icons.signal_wifi_4_bar,
                              value: '${device.signalStrength!.toInt()}%',
                              color: _getSignalColor(device.signalStrength!),
                            ),
                            const SizedBox(width: 12),
                          ],
                          if (!isOnline && device.lastSeenAt != null) ...[
                            _InfoItem(
                              icon: Icons.access_time,
                              value: _getLastSeenText(device.lastSeenAt!),
                              color: Colors.grey,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Kontrol butonu
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isOnline
                      ? theme.colorScheme.primary
                      : Colors.grey.withOpacity(0.3),
                  shape: BoxShape.circle,
                  boxShadow: isOnline
                      ? [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  Icons.power_settings_new,
                  color: isOnline ? Colors.white : Colors.grey,
                  size: 28,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(ThemeData theme, bool isOnline, bool isOpen) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                (isOnline
                        ? (isOpen ? Colors.orange : Colors.green)
                        : Colors.grey)
                    .withOpacity(0.1),
                (isOnline
                        ? (isOpen ? Colors.orange : Colors.green)
                        : Colors.grey)
                    .withOpacity(0.0),
              ],
            ),
          ),
        ),
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: isOnline
                ? (isOpen ? Colors.orange : Colors.green).withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getIconForDeviceType(device.type),
            size: 28,
            color: isOnline
                ? (isOpen ? Colors.orange : Colors.green)
                : Colors.grey,
          ),
        ),
        if (isOnline)
          Positioned(
            right: 12,
            top: 12,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: theme.colorScheme.surface, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  IconData _getIconForDeviceType(DeviceType type) {
    switch (type) {
      case DeviceType.door:
        return Icons.door_front_door;
      case DeviceType.barrier:
        return Icons.block;
      case DeviceType.gate:
        return Icons.fence;
      case DeviceType.turnstile:
        return Icons.rotate_90_degrees_ccw;
    }
  }

  Color _getBatteryColor(int level) {
    if (level > 60) return Colors.green;
    if (level > 30) return Colors.orange;
    return Colors.red;
  }

  Color _getSignalColor(double strength) {
    if (strength > 70) return Colors.green;
    if (strength > 40) return Colors.orange;
    return Colors.red;
  }

  String _getLastSeenText(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}dk önce';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}s önce';
    } else {
      return '${difference.inDays}g önce';
    }
  }
}

// Bilgi öğesi
class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _InfoItem({
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
