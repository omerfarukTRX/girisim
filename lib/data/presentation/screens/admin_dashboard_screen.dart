// lib/presentation/screens/global_admin/admin_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:girisim/data/presentation/providers/auth_provider.dart';
import 'package:girisim/data/presentation/providers/site_provider.dart';
import 'package:girisim/data/presentation/widgets/app_driver.dart';
import 'package:girisim/data/presentation/widgets/site_summary_card.dart';
import 'package:girisim/data/presentation/widgets/stat_card.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/site_model.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Siteleri yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SiteProvider>().loadSites();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yönetim Paneli'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Bildirimler
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  context.pushNamed('profile');
                  break;
                case 'settings':
                  context.pushNamed('settings');
                  break;
                case 'logout':
                  authProvider.signOut();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline, size: 20),
                    SizedBox(width: 12),
                    Text('Profil'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined, size: 20),
                    SizedBox(width: 12),
                    Text('Ayarlar'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Çıkış Yap', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<SiteProvider>().loadSites();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hoşgeldin mesajı
              _buildWelcomeSection(
                user?.fullName ?? 'Admin',
              ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.2, end: 0),

              const SizedBox(height: 24),

              // İstatistikler
              _buildStatistics().animate().fadeIn(
                delay: 200.ms,
                duration: 600.ms,
              ),

              const SizedBox(height: 24),

              // Hızlı işlemler
              _buildQuickActions(
                context,
              ).animate().fadeIn(delay: 400.ms, duration: 600.ms),

              const SizedBox(height: 24),

              // Son eklenen siteler
              _buildRecentSites().animate().fadeIn(
                delay: 600.ms,
                duration: 600.ms,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(String userName) {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Günaydın';
    } else if (hour < 18) {
      greeting = 'İyi günler';
    } else {
      greeting = 'İyi akşamlar';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting, $userName',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Sistemde ${context.watch<SiteProvider>().sites.length} aktif site bulunuyor.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildStatistics() {
    final siteProvider = context.watch<SiteProvider>();
    final sites = siteProvider.sites;

    // İstatistikleri hesapla
    final totalUsers = sites.fold<int>(
      0,
      (sum, site) => sum + (site.totalUsers ?? site.userIds.length),
    );
    final totalDevices = sites.fold<int>(
      0,
      (sum, site) => sum + (site.totalDevices ?? site.deviceIds.length),
    );
    final todayAccess = sites.fold<int>(
      0,
      (sum, site) => sum + (site.todayAccessCount ?? 0),
    );

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        StatCard(
          title: 'Toplam Site',
          value: sites.length.toString(),
          icon: Icons.business,
          color: Theme.of(context).colorScheme.primary,
          onTap: () => context.pushNamed('sitesList'),
        ),
        StatCard(
          title: 'Aktif Kullanıcı',
          value: totalUsers.toString(),
          icon: Icons.people,
          color: Theme.of(context).colorScheme.secondary,
        ),
        StatCard(
          title: 'Toplam Cihaz',
          value: totalDevices.toString(),
          icon: Icons.door_front_door,
          color: Colors.green,
        ),
        StatCard(
          title: 'Bugünkü Giriş',
          value: todayAccess.toString(),
          icon: Icons.login,
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hızlı İşlemler',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.add_business,
                label: 'Yeni Site',
                color: Colors.blue,
                onTap: () => context.pushNamed('addSite'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.person_add,
                label: 'Kullanıcı Ekle',
                color: Colors.green,
                onTap: () {
                  // TODO: Kullanıcı ekleme
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.analytics,
                label: 'Raporlar',
                color: Colors.orange,
                onTap: () {
                  // TODO: Raporlar
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentSites() {
    final sites = context.watch<SiteProvider>().sites;
    final recentSites = sites.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Son Eklenen Siteler',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () => context.pushNamed('sitesList'),
              child: const Text('Tümünü Gör'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (recentSites.isEmpty)
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.business_outlined,
                  size: 64,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'Henüz site eklenmemiş',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => context.pushNamed('addSite'),
                  icon: const Icon(Icons.add),
                  label: const Text('İlk Siteyi Ekle'),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentSites.length,
            itemBuilder: (context, index) {
              final site = recentSites[index];
              return SiteSummaryCard(
                site: site,
                onTap: () => context.pushNamed(
                  'siteDetail',
                  pathParameters: {'siteId': site.id},
                ),
              ).animate().fadeIn(
                delay: Duration(milliseconds: 100 * index),
                duration: 600.ms,
              );
            },
          ),
      ],
    );
  }
}

// Hızlı işlem kartı
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
