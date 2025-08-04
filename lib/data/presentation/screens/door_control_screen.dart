// lib/presentation/screens/user/door_control_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:girisim/data/presentation/providers/device_provider.dart';
import 'package:girisim/data/presentation/providers/site_provider.dart';
import 'package:girisim/data/presentation/widgets/door_control_detail_card.dart';
import 'package:girisim/data/presentation/widgets/empty_state_widget.dart';
import 'package:girisim/data/presentation/widgets/search_field.dart';
import 'package:provider/provider.dart';
import '../../../data/models/device_model.dart';

class DoorControlScreen extends StatefulWidget {
  const DoorControlScreen({super.key});

  @override
  State<DoorControlScreen> createState() => _DoorControlScreenState();
}

class _DoorControlScreenState extends State<DoorControlScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  DeviceType? _filterType;
  bool _showOnlyOnline = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDevices();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadDevices() {
    final selectedSite = context.read<SiteProvider>().selectedSite;
    if (selectedSite != null) {
      context.read<DeviceProvider>().loadDevicesForSite(selectedSite.id);
    }
  }

  List<DeviceModel> _getFilteredDevices(List<DeviceModel> devices) {
    return devices.where((device) {
      // Sadece aktif cihazlar
      if (!device.isActive) return false;

      // Online filtresi
      if (_showOnlyOnline && device.status != DeviceStatus.online) return false;

      // Tip filtresi
      if (_filterType != null && device.type != _filterType) return false;

      // Arama filtresi
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return device.name.toLowerCase().contains(query);
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedSite = context.watch<SiteProvider>().selectedSite;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kapı Kontrolü'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tümü'),
            Tab(text: 'Favoriler'),
            Tab(text: 'Son Kullanılan'),
          ],
        ),
      ),
      body: selectedSite == null
          ? const Center(child: Text('Lütfen bir site seçin'))
          : Column(
              children: [
                // Arama ve filtre
                Container(
                  padding: const EdgeInsets.all(16),
                  color: theme.colorScheme.surface,
                  child: Column(
                    children: [
                      SearchField(
                        controller: _searchController,
                        hintText: 'Cihaz ara...',
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildFilterChips(),
                    ],
                  ),
                ),

                // İçerik
                Expanded(
                  child: Consumer<DeviceProvider>(
                    builder: (context, deviceProvider, child) {
                      if (deviceProvider.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      return TabBarView(
                        controller: _tabController,
                        children: [
                          _buildAllDevicesTab(deviceProvider.devices),
                          _buildFavoritesTab(deviceProvider.devices),
                          _buildRecentTab(deviceProvider.devices),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showQRScanner,
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('QR ile Aç'),
        backgroundColor: theme.colorScheme.secondary,
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          FilterChip(
            label: const Text('Sadece Çevrimiçi'),
            selected: _showOnlyOnline,
            onSelected: (selected) {
              setState(() {
                _showOnlyOnline = selected;
              });
            },
            avatar: Icon(
              Icons.circle,
              size: 12,
              color: _showOnlyOnline ? Colors.green : null,
            ),
          ),
          const SizedBox(width: 8),

          // Tip filtreleri
          ...DeviceType.values.map((type) {
            final isSelected = _filterType == type;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(_getTypeText(type)),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _filterType = selected ? type : null;
                  });
                },
                avatar: Icon(_getIconForType(type), size: 16),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAllDevicesTab(List<DeviceModel> allDevices) {
    final devices = _getFilteredDevices(allDevices);

    if (devices.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.door_front_door,
        title: 'Cihaz bulunamadı',
        message:
            _searchQuery.isNotEmpty || _filterType != null || _showOnlyOnline
            ? 'Arama kriterlerinize uygun cihaz yok'
            : 'Henüz kontrol edilebilir cihaz eklenmemiş',
        actionLabel:
            (_searchQuery.isNotEmpty || _filterType != null || _showOnlyOnline)
            ? 'Filtreleri Temizle'
            : null,
        onAction:
            (_searchQuery.isNotEmpty || _filterType != null || _showOnlyOnline)
            ? () {
                setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                  _filterType = null;
                  _showOnlyOnline = false;
                });
              }
            : null,
      );
    }

    // Cihazları tipe göre grupla
    final groupedDevices = <DeviceType, List<DeviceModel>>{};
    for (final device in devices) {
      groupedDevices.putIfAbsent(device.type, () => []).add(device);
    }

    return RefreshIndicator(
      onRefresh: () async {
        _loadDevices();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: groupedDevices.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      _getIconForType(entry.key),
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getTypeText(entry.key),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${entry.value.length}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ...entry.value.map((device) {
                return DoorControlDetailCard(
                  device: device,
                  onControl: () => _controlDevice(device),
                  onFavorite: () => _toggleFavorite(device),
                  isFavorite: false, // TODO: Favori durumu
                ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.2, end: 0);
              }),
              const SizedBox(height: 16),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFavoritesTab(List<DeviceModel> allDevices) {
    // TODO: Favori cihazları filtrele
    return const Center(
      child: EmptyStateWidget(
        icon: Icons.star_border,
        title: 'Favori cihaz yok',
        message: 'Sık kullandığınız cihazları favorilere ekleyin',
      ),
    );
  }

  Widget _buildRecentTab(List<DeviceModel> allDevices) {
    // TODO: Son kullanılan cihazları getir
    return const Center(
      child: EmptyStateWidget(
        icon: Icons.history,
        title: 'Henüz cihaz kullanmadınız',
        message: 'Kullandığınız cihazlar burada görünecek',
      ),
    );
  }

  Future<void> _controlDevice(DeviceModel device) async {
    final deviceProvider = context.read<DeviceProvider>();

    // Haptic feedback
    // HapticFeedback.mediumImpact();

    // Loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  '${device.name} kontrol ediliyor...',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Komutu gönder
    final command = device.isOpen ?? false ? 'close' : 'open';
    final success = await deviceProvider.controlDevice(device.id, command);

    if (!mounted) return;

    // Dialog'u kapat
    Navigator.pop(context);

    // Sonuç göster
    if (success) {
      _showSuccessAnimation(device, command);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('${device.name} kontrol edilemedi')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSuccessAnimation(DeviceModel device, String command) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Center(
        child:
            Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_circle,
                            size: 48,
                            color: Colors.green,
                          ),
                        ).animate().scale(
                          duration: 300.ms,
                          curve: Curves.elasticOut,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          device.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          command == 'open' ? 'Açıldı' : 'Kapandı',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.copyWith(color: Colors.green),
                        ),
                      ],
                    ),
                  ),
                )
                .animate()
                .fadeIn(duration: 200.ms)
                .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
      ),
    );

    // 1.5 saniye sonra otomatik kapat
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) Navigator.pop(context);
    });
  }

  void _toggleFavorite(DeviceModel device) {
    // TODO: Favori durumunu değiştir
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${device.name} favorilere eklendi'),
        action: SnackBarAction(
          label: 'Geri Al',
          onPressed: () {
            // TODO: Geri al
          },
        ),
      ),
    );
  }

  void _showQRScanner() {
    // TODO: QR okuyucu
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('QR okuyucu yakında eklenecek')),
    );
  }

  String _getTypeText(DeviceType type) {
    switch (type) {
      case DeviceType.door:
        return 'Kapılar';
      case DeviceType.barrier:
        return 'Bariyerler';
      case DeviceType.gate:
        return 'Bahçe Kapıları';
      case DeviceType.turnstile:
        return 'Turnikeler';
    }
  }

  IconData _getIconForType(DeviceType type) {
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
}
