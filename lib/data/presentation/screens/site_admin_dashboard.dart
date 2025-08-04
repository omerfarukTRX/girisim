// lib/presentation/screens/site_admin/site_admin_dashboard.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:girisim/data/models/repositories/site_repository.dart';
import 'package:girisim/data/presentation/providers/auth_provider.dart';
import 'package:girisim/data/presentation/providers/device_provider.dart';
import 'package:girisim/data/presentation/providers/site_provider.dart';
import 'package:girisim/data/presentation/widgets/app_driver.dart';
import 'package:girisim/data/presentation/widgets/device_status_card.dart';
import 'package:girisim/data/presentation/widgets/recent_activity_card.dart';
import 'package:girisim/data/presentation/widgets/stat_card.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/site_model.dart';
import '../../../data/models/device_model.dart';

class SiteAdminDashboard extends StatefulWidget {
  const SiteAdminDashboard({super.key});

  @override
  State<SiteAdminDashboard> createState() => _SiteAdminDashboardState();
}

class _SiteAdminDashboardState extends State<SiteAdminDashboard> {
  final SiteRepository _siteRepository = SiteRepository();
  SiteModel? _adminSite;
  Map<String, dynamic>? _statistics;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;

    if (user == null) return;

    try {
      // Site admininin yönettiği siteyi bul
      final sites = await _siteRepository.getSitesForUser(user);
      if (sites.isNotEmpty) {
        setState(() {
          try {
            // Önce admin olduğu siteyi bul
            _adminSite = sites.firstWhere((site) => site.adminId == user.id);
          } catch (e) {
            // Bulamazsa ilk siteyi seç
            _adminSite = sites.first;
          }
        });

        if (_adminSite != null) {
          // Site seç
          context.read<SiteProvider>().selectSite(_adminSite!);

          // Cihazları yükle
          context.read<DeviceProvider>().loadDevicesForSite(_adminSite!.id);

          // İstatistikleri yükle
          final stats = await _siteRepository.getSiteStatistics(_adminSite!.id);
          if (mounted) {
            setState(() {
              _statistics = stats;
              _isLoadingStats = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    if (_adminSite == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Site Yönetimi')),
        drawer: const AppDrawer(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_adminSite!.name),
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
                case 'settings':
                  // TODO: Site ayarları
                  break;
                case 'profile':
                  context.pushNamed('profile');
                  break;
                case 'logout':
                  authProvider.signOut();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined, size: 20),
                    SizedBox(width: 12),
                    Text('Site Ayarları'),
                  ],
                ),
              ),
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
        onRefresh: _loadData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hoşgeldin mesajı
              _buildWelcomeSection(
                user?.fullName ?? 'Yönetici',
              ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.2, end: 0),

              const SizedBox(height: 24),

              // İstatistikler
              _buildStatistics().animate().fadeIn(
                delay: 200.ms,
                duration: 600.ms,
              ),

              const SizedBox(height: 24),

              // Hızlı işlemler
              _buildQuickActions().animate().fadeIn(
                delay: 400.ms,
                duration: 600.ms,
              ),

              const SizedBox(height: 24),

              // Cihaz durumları
              _buildDeviceStatus().animate().fadeIn(
                delay: 600.ms,
                duration: 600.ms,
              ),

              const SizedBox(height: 24),

              // Son aktiviteler
              _buildRecentActivities().animate().fadeIn(
                delay: 800.ms,
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
        Row(
          children: [
            Icon(
              Icons.location_on,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                _adminSite!.address,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatistics() {
    if (_isLoadingStats) {
      return const Center(child: CircularProgressIndicator());
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        StatCard(
          title: 'Bugünkü Giriş',
          value: (_statistics?['todayAccessCount'] ?? 0).toString(),
          icon: Icons.login,
          color: Colors.blue,
          onTap: () => context.goNamed('viewLogs', extra: _adminSite!.id),
        ),
        StatCard(
          title: 'Aktif Kullanıcı',
          value: (_statistics?['totalUserCount'] ?? 0).toString(),
          icon: Icons.people,
          color: Colors.green,
          onTap: () => context.goNamed('manageUsers', extra: _adminSite!.id),
        ),
        StatCard(
          title: 'Aktif Cihaz',
          value: (_statistics?['activeDeviceCount'] ?? 0).toString(),
          icon: Icons.device_hub,
          color: Colors.orange,
        ),
        StatCard(
          title: 'Haftalık Giriş',
          value: (_statistics?['weeklyAccessCount'] ?? 0).toString(),
          icon: Icons.calendar_today,
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
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
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1,
          children: [
            _QuickActionCard(
              icon: Icons.person_add,
              label: 'Kullanıcı\nEkle',
              color: Colors.blue,
              onTap: () => context.goNamed('addUser', extra: _adminSite!.id),
            ),
            _QuickActionCard(
              icon: Icons.qr_code,
              label: 'QR\nOluştur',
              color: Colors.green,
              onTap: () {
                // TODO: QR oluştur
              },
            ),
            _QuickActionCard(
              icon: Icons.history,
              label: 'Erişim\nLogları',
              color: Colors.orange,
              onTap: () => context.goNamed('viewLogs', extra: _adminSite!.id),
            ),
            _QuickActionCard(
              icon: Icons.door_front_door,
              label: 'Kapı\nKontrol',
              color: Colors.purple,
              onTap: () => context.pushNamed('doorControl'),
            ),
            _QuickActionCard(
              icon: Icons.group,
              label: 'Kullanıcı\nListesi',
              color: Colors.teal,
              onTap: () =>
                  context.goNamed('manageUsers', extra: _adminSite!.id),
            ),
            _QuickActionCard(
              icon: Icons.settings,
              label: 'Site\nAyarları',
              color: Colors.grey,
              onTap: () {
                // TODO: Site ayarları
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDeviceStatus() {
    final devices = context.watch<DeviceProvider>().devices;
    final onlineDevices = devices
        .where((d) => d.status == DeviceStatus.online && d.isActive)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Cihaz Durumları',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                // TODO: Cihaz listesi
              },
              child: const Text('Tümü'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (onlineDevices.isEmpty)
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.device_hub,
                  size: 48,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.3),
                ),
                const SizedBox(height: 8),
                Text(
                  'Çevrimiçi cihaz yok',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          )
        else
          ...onlineDevices.take(3).map((device) {
            return DeviceStatusCard(
              device: device,
              onControl: () => _controlDevice(device),
            );
          }),
      ],
    );
  }

  Widget _buildRecentActivities() {
    // TODO: Gerçek aktivite verilerini çek
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Son Aktiviteler',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () =>
                  context.goNamed('viewLogs', extra: _adminSite!.id),
              child: const Text('Tümü'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...[1, 2, 3, 4, 5].map(
          (i) => RecentActivityCard(
            userName: 'Kullanıcı $i',
            action: i % 2 == 0 ? 'açtı' : 'kapattı',
            deviceName: 'Ana Kapı',
            time: '${i * 5} dakika önce',
            success: i != 3,
          ),
        ),
      ],
    );
  }

  Future<void> _controlDevice(DeviceModel device) async {
    final deviceProvider = context.read<DeviceProvider>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );

    final success = await deviceProvider.controlDevice(
      device.id,
      device.isOpen ?? false ? 'close' : 'open',
    );

    if (!mounted) return;

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? '${device.name} ${device.isOpen ?? false ? "kapandı" : "açıldı"}'
              : 'İşlem başarısız',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
