// lib/presentation/screens/global_admin/sites/site_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:girisim/data/models/repositories/site_repository.dart';
import 'package:girisim/data/presentation/providers/device_provider.dart';
import 'package:girisim/data/presentation/providers/site_provider.dart';
import 'package:girisim/data/presentation/widgets/device_status_card.dart';
import 'package:girisim/data/presentation/widgets/loading_widget.dart';
import 'package:girisim/data/presentation/widgets/recent_activity_card.dart';
import 'package:girisim/data/presentation/widgets/stat_card.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/models/site_model.dart';
import '../../../../data/models/device_model.dart';

class SiteDetailScreen extends StatefulWidget {
  final String siteId;

  const SiteDetailScreen({super.key, required this.siteId});

  @override
  State<SiteDetailScreen> createState() => _SiteDetailScreenState();
}

class _SiteDetailScreenState extends State<SiteDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SiteRepository _siteRepository = SiteRepository();
  Map<String, dynamic>? _statistics;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    // Cihazları yükle
    context.read<DeviceProvider>().loadDevicesForSite(widget.siteId);

    // İstatistikleri yükle
    try {
      final stats = await _siteRepository.getSiteStatistics(widget.siteId);
      if (mounted) {
        setState(() {
          _statistics = stats;
          _isLoadingStats = false;
        });
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
    final siteProvider = context.watch<SiteProvider>();
    final site = siteProvider.sites.firstWhere(
      (s) => s.id == widget.siteId,
      orElse: () => SiteModel(
        id: '',
        name: 'Yükleniyor...',
        address: '',
        type: SiteType.residential,
        adminId: '',
        deviceIds: [],
        userIds: [],
        isActive: false,
        createdAt: DateTime.now(),
      ),
    );

    if (site.id.isEmpty) {
      return Scaffold(appBar: AppBar(), body: const LoadingWidget());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(site.name),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  _editSite();
                  break;
                case 'settings':
                  _openSettings();
                  break;
                case 'delete':
                  _deleteSite();
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
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, size: 20),
                    SizedBox(width: 12),
                    Text('Ayarlar'),
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
      body: Column(
        children: [
          // Site başlık kartı
          _buildHeaderCard(
            site,
            theme,
          ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2, end: 0),

          // Tab bar
          Container(
            color: theme.colorScheme.surface,
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Genel Bakış'),
                Tab(text: 'Cihazlar'),
                Tab(text: 'Kullanıcılar'),
                Tab(text: 'Aktivite'),
              ],
            ),
          ),

          // Tab içerikleri
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(site),
                _buildDevicesTab(),
                _buildUsersTab(),
                _buildActivityTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(SiteModel site, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Site ikonu
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: site.isActive
                  ? theme.colorScheme.primary.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getIconForSiteType(site.type),
              color: site.isActive ? theme.colorScheme.primary : Colors.grey,
              size: 30,
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
                    Text(
                      site.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: site.isActive
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        site.isActive ? 'Aktif' : 'Pasif',
                        style: TextStyle(
                          color: site.isActive ? Colors.green : Colors.orange,
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
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  site.typeDisplayName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(SiteModel site) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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

            // Cihaz durumları özeti
            _buildDeviceSummary().animate().fadeIn(
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
        ),
        StatCard(
          title: 'Haftalık Giriş',
          value: (_statistics?['weeklyAccessCount'] ?? 0).toString(),
          icon: Icons.calendar_today,
          color: Colors.orange,
        ),
        StatCard(
          title: 'Aktif Cihaz',
          value: (_statistics?['activeDeviceCount'] ?? 0).toString(),
          icon: Icons.device_hub,
          color: Colors.green,
        ),
        StatCard(
          title: 'Toplam Kullanıcı',
          value: (_statistics?['totalUserCount'] ?? 0).toString(),
          icon: Icons.people,
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
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionButton(
                icon: Icons.person_add,
                label: 'Kullanıcı Ekle',
                onTap: () => context.pushNamed(
                  'addSiteUser',
                  pathParameters: {'siteId': widget.siteId},
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.add_circle,
                label: 'Cihaz Ekle',
                onTap: () => context.pushNamed(
                  'addDevice',
                  pathParameters: {'siteId': widget.siteId},
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.history,
                label: 'Loglar',
                onTap: () => context.pushNamed(
                  'siteLogs',
                  pathParameters: {'siteId': widget.siteId},
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDeviceSummary() {
    final devices = context.watch<DeviceProvider>().devices;
    final onlineCount = devices
        .where((d) => d.status == DeviceStatus.online)
        .length;
    final offlineCount = devices
        .where((d) => d.status == DeviceStatus.offline)
        .length;
    final errorCount = devices
        .where((d) => d.status == DeviceStatus.error)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cihaz Durumu',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _DeviceStatusItem(
                  label: 'Çevrimiçi',
                  count: onlineCount,
                  color: Colors.green,
                  icon: Icons.check_circle,
                ),
                _DeviceStatusItem(
                  label: 'Çevrimdışı',
                  count: offlineCount,
                  color: Colors.grey,
                  icon: Icons.cancel,
                ),
                _DeviceStatusItem(
                  label: 'Hata',
                  count: errorCount,
                  color: Colors.red,
                  icon: Icons.error,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivities() {
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
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () => _tabController.animateTo(3),
              child: const Text('Tümünü Gör'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // TODO: Gerçek aktivite verilerini çek
        ...[1, 2, 3].map(
          (i) => RecentActivityCard(
            userName: 'Kullanıcı $i',
            action: i % 2 == 0 ? 'açtı' : 'kapattı',
            deviceName: 'Ana Kapı',
            time: '${i * 5} dakika önce',
            success: i != 2,
          ),
        ),
      ],
    );
  }

  Widget _buildDevicesTab() {
    return Consumer<DeviceProvider>(
      builder: (context, deviceProvider, child) {
        if (deviceProvider.isLoading) {
          return const LoadingWidget();
        }

        final devices = deviceProvider.devices;

        if (devices.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.devices_other,
                  size: 64,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'Henüz cihaz eklenmemiş',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => context.pushNamed(
                    'addDevice',
                    pathParameters: {'siteId': widget.siteId},
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Cihaz Ekle'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await deviceProvider.loadDevicesForSite(widget.siteId);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final device = devices[index];
              return DeviceStatusCard(
                device: device,
                onTap: () {
                  // TODO: Cihaz detay sayfası
                },
                onControl: () async {
                  final success = await deviceProvider.controlDevice(
                    device.id,
                    'toggle',
                  );

                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success ? 'Komut gönderildi' : 'Komut gönderilemedi',
                      ),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                },
              ).animate().fadeIn(
                delay: Duration(milliseconds: 100 * index),
                duration: 300.ms,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildUsersTab() {
    // TODO: Kullanıcılar listesi
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Kullanıcılar listesi yakında eklenecek'),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => context.pushNamed(
              'siteUsers',
              pathParameters: {'siteId': widget.siteId},
            ),
            icon: const Icon(Icons.people),
            label: const Text('Kullanıcıları Yönet'),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTab() {
    // TODO: Aktivite logları
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Aktivite logları yakında eklenecek'),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => context.pushNamed(
              'siteLogs',
              pathParameters: {'siteId': widget.siteId},
            ),
            icon: const Icon(Icons.history),
            label: const Text('Tüm Logları Gör'),
          ),
        ],
      ),
    );
  }

  void _editSite() {
    // TODO: Site düzenleme
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Düzenleme özelliği yakında')));
  }

  void _openSettings() {
    // TODO: Site ayarları
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Ayarlar yakında')));
  }

  void _deleteSite() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Site Sil'),
        content: const Text('Bu siteyi silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Site silme
              context.go('/admin/sites');
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
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

// Hızlı işlem butonu
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Cihaz durum göstergesi
class _DeviceStatusItem extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _DeviceStatusItem({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          count.toString(),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
