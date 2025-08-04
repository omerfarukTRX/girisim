// lib/presentation/widgets/common/app_drawer.dart

import 'package:flutter/material.dart';
import 'package:girisim/data/presentation/providers/auth_provider.dart';
import 'package:girisim/data/presentation/providers/theme_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../data/models/user_model.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    return Drawer(
      child: Column(
        children: [
          // Drawer Header
          DrawerHeader(
            decoration: BoxDecoration(color: theme.colorScheme.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Text(
                    user?.fullName.substring(0, 2).toUpperCase() ?? 'U',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user?.fullName ?? 'Kullanıcı',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getRoleText(user?.role),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Global Admin menüsü
                if (user?.isGlobalAdmin ?? false) ...[
                  _DrawerItem(
                    icon: Icons.dashboard,
                    title: 'Yönetim Paneli',
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/admin');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.business,
                    title: 'Siteler',
                    onTap: () {
                      Navigator.pop(context);
                      context.goNamed('sitesList');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.people,
                    title: 'Tüm Kullanıcılar',
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Tüm kullanıcılar sayfası
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.analytics,
                    title: 'Raporlar',
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Raporlar sayfası
                    },
                  ),
                  const Divider(),
                ],

                // Site Admin menüsü
                if (user?.isSiteAdmin ?? false) ...[
                  _DrawerItem(
                    icon: Icons.space_dashboard,
                    title: 'Site Yönetimi',
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/site-admin');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.group,
                    title: 'Kullanıcılar',
                    onTap: () {
                      Navigator.pop(context);
                      context.goNamed('manageUsers');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.history,
                    title: 'Erişim Logları',
                    onTap: () {
                      Navigator.pop(context);
                      context.goNamed('viewLogs');
                    },
                  ),
                  const Divider(),
                ],

                // Ortak menü öğeleri
                _DrawerItem(
                  icon: Icons.home,
                  title: 'Ana Sayfa',
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/home');
                  },
                ),
                _DrawerItem(
                  icon: Icons.door_front_door,
                  title: 'Kapı Kontrolü',
                  onTap: () {
                    Navigator.pop(context);
                    context.goNamed('doorControl');
                  },
                ),
                _DrawerItem(
                  icon: Icons.qr_code,
                  title: 'Misafir QR',
                  onTap: () {
                    Navigator.pop(context);
                    context.goNamed('guestQR');
                  },
                ),
                const Divider(),

                _DrawerItem(
                  icon: Icons.person,
                  title: 'Profil',
                  onTap: () {
                    Navigator.pop(context);
                    context.goNamed('profile');
                  },
                ),
                _DrawerItem(
                  icon: Icons.settings,
                  title: 'Ayarlar',
                  onTap: () {
                    Navigator.pop(context);
                    context.goNamed('settings');
                  },
                ),

                // Tema değiştirici
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, _) {
                    return SwitchListTile(
                      secondary: Icon(
                        themeProvider.isDarkMode
                            ? Icons.dark_mode
                            : Icons.light_mode,
                      ),
                      title: const Text('Karanlık Tema'),
                      value: themeProvider.isDarkMode,
                      onChanged: (value) {
                        themeProvider.toggleTheme();
                      },
                    );
                  },
                ),
              ],
            ),
          ),

          // Logout
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Çıkış Yap', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              authProvider.signOut();
            },
          ),

          // Version info
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'v1.0.0',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getRoleText(UserRole? role) {
    if (role == null) return '';
    switch (role) {
      case UserRole.globalAdmin:
        return 'Global Yönetici';
      case UserRole.siteAdmin:
        return 'Site Yöneticisi';
      case UserRole.user:
        return 'Kullanıcı';
    }
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(leading: Icon(icon), title: Text(title), onTap: onTap);
  }
}
