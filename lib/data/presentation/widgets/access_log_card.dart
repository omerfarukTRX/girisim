// lib/presentation/widgets/cards/access_log_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/access_log_model.dart';

class AccessLogCard extends StatelessWidget {
  final AccessLogModel log;
  final VoidCallback? onTap;

  const AccessLogCard({super.key, required this.log, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: log.success
              ? Colors.green.withOpacity(0.2)
              : Colors.red.withOpacity(0.2),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Durum ikonu
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: log.success
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getActionIcon(log.action),
                  size: 20,
                  color: log.success ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(width: 12),

              // Log bilgileri
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Kullanıcı ve aksiyon
                    Row(
                      children: [
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: theme.textTheme.bodyMedium,
                              children: [
                                TextSpan(
                                  text: log.userName ?? 'Bilinmeyen',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const TextSpan(text: ' '),
                                TextSpan(
                                  text: log.deviceName ?? 'cihazı',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.7),
                                  ),
                                ),
                                const TextSpan(text: ' '),
                                TextSpan(
                                  text: log.actionDisplayName.toLowerCase(),
                                  style: TextStyle(
                                    color: log.success
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Zaman ve ek bilgiler
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(log.timestamp),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                        if (!log.success && log.errorMessage != null) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 14,
                                  color: Colors.red.withOpacity(0.7),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    log.errorMessage!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.red.withOpacity(0.7),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Detay oku
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurface.withOpacity(0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getActionIcon(String action) {
    switch (action.toLowerCase()) {
      case 'open':
      case 'açıldı':
        return Icons.lock_open;
      case 'close':
      case 'kapandı':
        return Icons.lock;
      case 'toggle':
      case 'değiştirildi':
        return Icons.sync;
      default:
        return Icons.touch_app;
    }
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final logDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (logDate == today) {
      // Bugün - sadece saat göster
      return DateFormat('HH:mm').format(timestamp);
    } else {
      // Farklı gün - tarih ve saat göster
      return DateFormat('dd/MM HH:mm').format(timestamp);
    }
  }
}
