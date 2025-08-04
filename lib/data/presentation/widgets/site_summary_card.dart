// ------------------------------
// lib/presentation/widgets/cards/site_summary_card.dart

import 'package:flutter/material.dart';
import '../../../data/models/site_model.dart';

class SiteSummaryCard extends StatelessWidget {
  final SiteModel site;
  final VoidCallback? onTap;

  const SiteSummaryCard({super.key, required this.site, this.onTap});

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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Site ikonu
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: site.isActive
                      ? theme.colorScheme.primary.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getIconForSiteType(site.type),
                  color: site.isActive
                      ? theme.colorScheme.primary
                      : Colors.grey,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),

              // Site bilgileri
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            site.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!site.isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Pasif',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      site.address,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _InfoChip(
                          icon: Icons.people,
                          label: '${site.totalUsers ?? site.userIds.length}',
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 12),
                        _InfoChip(
                          icon: Icons.door_front_door,
                          label:
                              '${site.totalDevices ?? site.deviceIds.length}',
                          color: Colors.green,
                        ),
                        const SizedBox(width: 12),
                        _InfoChip(
                          icon: Icons.category,
                          label: site.typeDisplayName,
                          color: Colors.purple,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Ok ikonu
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForSiteType(SiteType type) {
    switch (type) {
      case SiteType.residential:
        return Icons.home;
      case SiteType.business:
        return Icons.business;
      case SiteType.mixed:
        return Icons.location_city;
      case SiteType.factory:
        return Icons.factory;
    }
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
