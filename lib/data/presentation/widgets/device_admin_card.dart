// lib/presentation/widgets/cards/device_admin_card.dart

import 'package:flutter/material.dart';
import '../../../data/models/device_model.dart';

class DeviceAdminCard extends StatelessWidget {
  final DeviceModel device;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleStatus;

  const DeviceAdminCard({
    super.key,
    required this.device,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Cihaz durumu ikonu
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: device.statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          _getIconForDeviceType(device.type),
                          size: 28,
                          color: device.statusColor,
                        ),
                        // Online göstergesi
                        if (device.status == DeviceStatus.online)
                          Positioned(
                            right: 4,
                            top: 4,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        // Hata veya bakım ikonu
                        if (device.status == DeviceStatus.error)
                          Positioned(
                            right: 4,
                            top: 4,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.priority_high,
                                size: 8,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        if (device.status == DeviceStatus.maintenance)
                          Positioned(
                            right: 4,
                            top: 4,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.orange,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.build,
                                size: 8,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
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
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!device.isActive)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Pasif',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            // Durum
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: device.statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.circle,
                                    size: 6,
                                    color: device.statusColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    device.statusDisplayName,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: device.statusColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Tip
                            Text(
                              device.typeDisplayName,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Ek bilgiler
                        Row(
                          children: [
                            if (device.isOpen != null) ...[
                              Icon(
                                device.isOpen! ? Icons.lock_open : Icons.lock,
                                size: 14,
                                color: device.isOpen!
                                    ? Colors.orange
                                    : Colors.green,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                device.isOpen! ? 'Açık' : 'Kapalı',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: device.isOpen!
                                      ? Colors.orange
                                      : Colors.green,
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            if (device.lastSeenAt != null) ...[
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.5,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getLastSeenText(device.lastSeenAt!),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.5),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // İşlem menüsü
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEdit?.call();
                          break;
                        case 'toggle':
                          onToggleStatus?.call();
                          break;
                        case 'maintenance':
                          // TODO: Bakım modu
                          break;
                        case 'delete':
                          onDelete?.call();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 12),
                            Text('Düzenle'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'toggle',
                        child: Row(
                          children: [
                            Icon(
                              device.isActive ? Icons.pause : Icons.play_arrow,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              device.isActive ? 'Pasifleştir' : 'Aktifleştir',
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'maintenance',
                        enabled: device.status != DeviceStatus.maintenance,
                        child: const Row(
                          children: [
                            Icon(Icons.build, size: 20),
                            SizedBox(width: 12),
                            Text('Bakım Modu'),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 12),
                            Text('Sil', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Alt bilgi çubuğu
            if (device.batteryLevel != null || device.signalStrength != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                    0.3,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    if (device.batteryLevel != null) ...[
                      Icon(
                        _getBatteryIcon(device.batteryLevel!),
                        size: 16,
                        color: _getBatteryColor(device.batteryLevel!),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${device.batteryLevel}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: _getBatteryColor(device.batteryLevel!),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    if (device.signalStrength != null) ...[
                      Icon(
                        _getSignalIcon(device.signalStrength!),
                        size: 16,
                        color: _getSignalColor(device.signalStrength!),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        device.signalLevel,
                        style: TextStyle(
                          fontSize: 12,
                          color: _getSignalColor(device.signalStrength!),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      'ID: ${device.id.substring(0, 8)}...',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(
                          0.5,
                        ),
                        fontFamily: 'monospace',
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

  IconData _getBatteryIcon(int level) {
    if (level > 80) return Icons.battery_full;
    if (level > 60) return Icons.battery_6_bar;
    if (level > 40) return Icons.battery_4_bar;
    if (level > 20) return Icons.battery_2_bar;
    return Icons.battery_alert;
  }

  Color _getBatteryColor(int level) {
    if (level > 60) return Colors.green;
    if (level > 30) return Colors.orange;
    return Colors.red;
  }

  IconData _getSignalIcon(double strength) {
    if (strength > 70) return Icons.signal_wifi_4_bar;
    if (strength > 50) return Icons.network_wifi_3_bar;
    if (strength > 30) return Icons.network_wifi_2_bar;
    return Icons.network_wifi_1_bar;
  }

  Color _getSignalColor(double strength) {
    if (strength > 70) return Colors.green;
    if (strength > 40) return Colors.orange;
    return Colors.red;
  }

  String _getLastSeenText(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inSeconds < 60) {
      return 'Az önce';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} dk önce';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} saat önce';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      return '${lastSeen.day}/${lastSeen.month}/${lastSeen.year}';
    }
  }
}
