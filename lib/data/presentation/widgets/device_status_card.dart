import 'package:flutter/material.dart';
import '../../../data/models/device_model.dart';

class DeviceStatusCard extends StatelessWidget {
  final DeviceModel device;
  final VoidCallback? onTap;
  final VoidCallback? onControl;

  const DeviceStatusCard({
    super.key,
    required this.device,
    this.onTap,
    this.onControl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Cihaz ikonu ve durum
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
                            border: Border.all(color: Colors.white, width: 2),
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
                    Text(
                      device.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.circle, size: 8, color: device.statusColor),
                        const SizedBox(width: 4),
                        Text(
                          device.statusDisplayName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: device.statusColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (device.isOpen != null) ...[
                          Icon(
                            device.isOpen! ? Icons.lock_open : Icons.lock,
                            size: 16,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            device.isOpen! ? 'Açık' : 'Kapalı',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (device.batteryLevel != null) ...[
                          _InfoChip(
                            icon: Icons.battery_full,
                            label: '${device.batteryLevel}%',
                            color: _getBatteryColor(device.batteryLevel!),
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (device.signalStrength != null) ...[
                          _InfoChip(
                            icon: Icons.wifi,
                            label: device.signalLevel,
                            color: _getSignalColor(device.signalStrength!),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Kontrol butonu
              if (onControl != null && device.status == DeviceStatus.online)
                IconButton(
                  onPressed: onControl,
                  icon: Icon(
                    device.isOpen ?? false
                        ? Icons.lock_outline
                        : Icons.lock_open_outlined,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    foregroundColor: theme.colorScheme.primary,
                  ),
                ),
            ],
          ),
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
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
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
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
