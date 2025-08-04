// lib/presentation/screens/user/user_home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:girisim/data/presentation/providers/auth_provider.dart';
import 'package:girisim/data/presentation/providers/device_provider.dart';
import 'package:girisim/data/presentation/providers/site_provider.dart';
import 'package:girisim/data/presentation/widgets/app_driver.dart';
import 'package:girisim/data/presentation/widgets/door_control_card.dart';
import 'package:girisim/data/presentation/widgets/quick_access_card.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/device_model.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    // Kullanıcının sitelerini yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final siteProvider = context.read<SiteProvider>();
      siteProvider.loadSites().then((_) {
        // İlk siteyi seç ve cihazları yükle
        if (siteProvider.sites.isNotEmpty) {
          final firstSite = siteProvider.sites.first;
          siteProvider.selectSite(firstSite);
          context.read<DeviceProvider>().loadDevicesForSite(firstSite.id);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('GirişİM'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Bildirimler
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadUserData();
        },
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hoşgeldin bölümü
              _buildWelcomeSection(
                user?.fullName ?? 'Kullanıcı',
              ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2, end: 0),

              // Site seçici (birden fazla site varsa)
              _buildSiteSelector().animate().fadeIn(
                delay: 200.ms,
                duration: 600.ms,
              ),

              const SizedBox(height: 24),

              // Hızlı erişim
              _buildQuickAccess().animate().fadeIn(
                delay: 400.ms,
                duration: 600.ms,
              ),

              const SizedBox(height: 24),

              // Kapı kontrolleri
              _buildDoorControls().animate().fadeIn(
                delay: 600.ms,
                duration: 600.ms,
              ),

              const SizedBox(height: 24),

              // Son aktiviteler
              _buildRecentActivity().animate().fadeIn(
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
    IconData greetingIcon;

    if (hour < 6) {
      greeting = 'İyi geceler';
      greetingIcon = Icons.nightlight_round;
    } else if (hour < 12) {
      greeting = 'Günaydın';
      greetingIcon = Icons.wb_sunny;
    } else if (hour < 18) {
      greeting = 'İyi günler';
      greetingIcon = Icons.wb_sunny;
    } else {
      greeting = 'İyi akşamlar';
      greetingIcon = Icons.nights_stay;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
        ),
      ),
      child: Row(
        children: [
          Icon(greetingIcon, size: 40, color: Colors.white),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting,',
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSiteSelector() {
    final siteProvider = context.watch<SiteProvider>();
    final sites = siteProvider.sites;
    final selectedSite = siteProvider.selectedSite;

    if (sites.length <= 1) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButton<String>(
        isExpanded: true,
        underline: const SizedBox(),
        value: selectedSite?.id,
        hint: const Text('Site seçin'),
        items: sites.map((site) {
          return DropdownMenuItem(
            value: site.id,
            child: Row(
              children: [
                Icon(
                  Icons.business,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(site.name),
              ],
            ),
          );
        }).toList(),
        onChanged: (siteId) {
          if (siteId != null) {
            final site = sites.firstWhere((s) => s.id == siteId);
            siteProvider.selectSite(site);
            context.read<DeviceProvider>().loadDevicesForSite(siteId);
          }
        },
      ),
    );
  }

  Widget _buildQuickAccess() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hızlı Erişim',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: QuickAccessCard(
                  icon: Icons.qr_code_scanner,
                  title: 'QR Oku',
                  subtitle: 'Hızlı giriş',
                  color: Colors.blue,
                  onTap: () {
                    // TODO: QR okuyucu
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: QuickAccessCard(
                  icon: Icons.person_add,
                  title: 'Misafir QR',
                  subtitle: 'Davet oluştur',
                  color: Colors.green,
                  onTap: () => context.pushNamed('guestQR'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: QuickAccessCard(
                  icon: Icons.history,
                  title: 'Girişlerim',
                  subtitle: 'Son 7 gün',
                  color: Colors.orange,
                  onTap: () {
                    // TODO: Kişisel loglar
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: QuickAccessCard(
                  icon: Icons.emergency,
                  title: 'Acil Durum',
                  subtitle: 'Hızlı arama',
                  color: Colors.red,
                  onTap: _showEmergencyDialog,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDoorControls() {
    final deviceProvider = context.watch<DeviceProvider>();
    final devices = deviceProvider.devices
        .where((d) => d.isActive && d.type == DeviceType.door)
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Kapı Kontrolleri',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => context.pushNamed('doorControl'),
                child: const Text('Tümü'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (devices.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.door_front_door,
                    size: 48,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.3),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kontrol edilebilir kapı yok',
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
            ...devices.take(3).map((device) {
              return DoorControlCard(
                device: device,
                onControl: () => _controlDevice(device),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    // TODO: Gerçek aktivite verilerini çek
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Son Aktivitelerim',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                _ActivityTile(
                  icon: Icons.login,
                  title: 'Ana Kapı açıldı',
                  time: '10 dakika önce',
                  success: true,
                ),
                const Divider(height: 1),
                _ActivityTile(
                  icon: Icons.qr_code,
                  title: 'Misafir QR kullanıldı',
                  subtitle: 'Ali Veli',
                  time: '2 saat önce',
                  success: true,
                ),
                const Divider(height: 1),
                _ActivityTile(
                  icon: Icons.logout,
                  title: 'Otopark çıkışı',
                  time: 'Dün 18:30',
                  success: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _controlDevice(DeviceModel device) async {
    final deviceProvider = context.read<DeviceProvider>();

    // Loading dialog göster
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

    // Loading dialog'u kapat
    Navigator.pop(context);

    // Sonuç mesajı
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

  void _showEmergencyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.emergency, color: Colors.red),
            SizedBox(width: 8),
            Text('Acil Durum'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.local_fire_department,
                color: Colors.red,
              ),
              title: const Text('İtfaiye'),
              subtitle: const Text('110'),
              onTap: () {
                // TODO: Telefon arama
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_hospital, color: Colors.red),
              title: const Text('Ambulans'),
              subtitle: const Text('112'),
              onTap: () {
                // TODO: Telefon arama
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_police, color: Colors.blue),
              title: const Text('Polis'),
              subtitle: const Text('155'),
              onTap: () {
                // TODO: Telefon arama
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.security, color: Colors.orange),
              title: const Text('Site Güvenlik'),
              subtitle: const Text('0555 555 55 55'),
              onTap: () {
                // TODO: Telefon arama
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }
}

// Aktivite satırı
class _ActivityTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String time;
  final bool success;

  const _ActivityTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.time,
    required this.success,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: success
              ? Colors.green.withOpacity(0.1)
              : Colors.red.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: success ? Colors.green : Colors.red),
      ),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: Text(time, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}
