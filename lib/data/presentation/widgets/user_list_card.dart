// lib/presentation/widgets/cards/user_list_card.dart

import 'package:flutter/material.dart';
import '../../../data/models/user_model.dart';

class UserListCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onToggleStatus;
  final VoidCallback? onResetPassword;
  final VoidCallback? onRemove;

  const UserListCard({
    super.key,
    required this.user,
    this.onTap,
    this.onEdit,
    this.onToggleStatus,
    this.onResetPassword,
    this.onRemove,
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
                  // Profil avatarı
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: user.profilePhotoUrl != null
                            ? Colors.transparent
                            : _getRoleColor(user.role).withOpacity(0.2),
                        backgroundImage: user.profilePhotoUrl != null
                            ? NetworkImage(user.profilePhotoUrl!)
                            : null,
                        child: user.profilePhotoUrl == null
                            ? Text(
                                user.fullName.substring(0, 2).toUpperCase(),
                                style: TextStyle(
                                  color: _getRoleColor(user.role),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              )
                            : null,
                      ),
                      // Online göstergesi
                      if (user.lastLoginAt != null &&
                          DateTime.now()
                                  .difference(user.lastLoginAt!)
                                  .inMinutes <
                              5)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.colorScheme.surface,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),

                  // Kullanıcı bilgileri
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                user.fullName,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!user.isActive)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Pasif',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            // Rol etiketi
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getRoleColor(
                                  user.role,
                                ).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getRoleIcon(user.role),
                                    size: 14,
                                    color: _getRoleColor(user.role),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _getRoleText(user.role),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: _getRoleColor(user.role),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Son giriş
                            if (user.lastLoginAt != null) ...[
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.5,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getLastLoginText(user.lastLoginAt!),
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
                        case 'reset':
                          onResetPassword?.call();
                          break;
                        case 'remove':
                          onRemove?.call();
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
                              user.isActive ? Icons.block : Icons.check_circle,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(user.isActive ? 'Pasifleştir' : 'Aktifleştir'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'reset',
                        child: Row(
                          children: [
                            Icon(Icons.lock_reset, size: 20),
                            SizedBox(width: 12),
                            Text('Şifre Sıfırla'),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'remove',
                        child: Row(
                          children: [
                            Icon(
                              Icons.remove_circle,
                              size: 20,
                              color: Colors.red,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Siteden Kaldır',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Alt bilgi çubuğu
            if (user.phoneNumber != null || user.siteIds.isNotEmpty)
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
                    if (user.phoneNumber != null) ...[
                      Icon(
                        Icons.phone,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        user.phoneNumber!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    const Spacer(),
                    Icon(
                      Icons.business,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${user.siteIds.length} site',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
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

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.globalAdmin:
        return Colors.red;
      case UserRole.siteAdmin:
        return Colors.orange;
      case UserRole.user:
        return Colors.blue;
    }
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.globalAdmin:
        return Icons.shield;
      case UserRole.siteAdmin:
        return Icons.admin_panel_settings;
      case UserRole.user:
        return Icons.person;
    }
  }

  String _getRoleText(UserRole role) {
    switch (role) {
      case UserRole.globalAdmin:
        return 'Global Admin';
      case UserRole.siteAdmin:
        return 'Site Admin';
      case UserRole.user:
        return 'Kullanıcı';
    }
  }

  String _getLastLoginText(DateTime lastLogin) {
    final now = DateTime.now();
    final difference = now.difference(lastLogin);

    if (difference.inMinutes < 5) {
      return 'Çevrimiçi';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} dk önce';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} saat önce';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks hafta önce';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ay önce';
    } else {
      return '${lastLogin.day}/${lastLogin.month}/${lastLogin.year}';
    }
  }
}
