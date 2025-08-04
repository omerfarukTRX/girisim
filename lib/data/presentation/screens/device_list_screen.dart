// lib/presentation/screens/global_admin/devices/device_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:girisim/data/presentation/providers/device_provider.dart';
import 'package:girisim/data/presentation/widgets/device_admin_card.dart';
import 'package:girisim/data/presentation/widgets/empty_state_widget.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/models/device_model.dart';

class DeviceListScreen extends StatefulWidget {
  final String siteId;

  const DeviceListScreen({super.key, required this.siteId});

  @override
  State<DeviceListScreen> createState() => _DeviceListScreenState();
}

class _DeviceListScreenState extends State<DeviceListScreen> {
  DeviceStatus? _filterStatus;
  DeviceType? _filterType;
  String _sortBy = 'name'; // name, status, lastSeen

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  void _loadDevices() {
    context.read<DeviceProvider>().loadDevicesForSite(widget.siteId);
  }

  List<DeviceModel> _getSortedAndFilteredDevices(List<DeviceModel> devices) {
    // Filtreleme
    var filtered = devices.where((device) {
      if (_filterStatus != null && device.status != _filterStatus) return false;
      if (_filterType != null && device.type != _filterType) return false;
      return true;
    }).toList();

    // Sıralama
    switch (_sortBy) {
      case 'name':
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'status':
        filtered.sort((a, b) => a.status.index.compareTo(b.status.index));
        break;
      case 'lastSeen':
        filtered.sort((a, b) {
          if (a.lastSeenAt == null) return 1;
          if (b.lastSeenAt == null) return -1;
          return b.lastSeenAt!.compareTo(a.lastSeenAt!);
        });
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cihaz Yönetimi'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                _sortBy = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'name',
                child: Row(
                  children: [
                    Icon(Icons.sort_by_alpha, size: 20),
                    SizedBox(width: 12),
                    Text('İsme göre'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'status',
                child: Row(
                  children: [
                    Icon(Icons.signal_cellular_alt, size: 20),
                    SizedBox(width: 12),
                    Text('Duruma göre'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'lastSeen',
                child: Row(
                  children: [
                    Icon(Icons.access_time, size: 20),
                    SizedBox(width: 12),
                    Text('Son görülmeye göre'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Consumer<DeviceProvider>(
        builder: (context, deviceProvider, child) {
          if (deviceProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final devices = _getSortedAndFilteredDevices(deviceProvider.devices);

          if (devices.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.devices_other,
              title: 'Cihaz bulunamadı',
              message: _filterStatus != null || _filterType != null
                  ? 'Filtrelere uygun cihaz yok'
                  : 'Bu siteye henüz cihaz eklenmemiş',
              actionLabel: _filterStatus != null || _filterType != null
                  ? 'Filtreleri Temizle'
                  : 'Cihaz Ekle',
              onAction: () {
                if (_filterStatus != null || _filterType != null) {
                  setState(() {
                    _filterStatus = null;
                    _filterType = null;
                  });
                } else {
                  context.pushNamed(
                    'addDevice',
                    pathParameters: {'siteId': widget.siteId},
                  );
                }
              },
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await deviceProvider.loadDevicesForSite(widget.siteId);
            },
            child: Column(
              children: [
                // İstatistik kartları
                _buildStatistics(devices),

                // Filtre bilgisi
                if (_filterStatus != null || _filterType != null)
                  _buildActiveFilters(),

                // Cihaz listesi
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: devices.length,
                    itemBuilder: (context, index) {
                      final device = devices[index];
                      return DeviceAdminCard(
                        device: device,
                        onTap: () => _showDeviceDetails(device),
                        onEdit: () => _editDevice(device),
                        onDelete: () => _deleteDevice(device),
                        onToggleStatus: () => _toggleDeviceStatus(device),
                      ).animate().fadeIn(
                        delay: Duration(milliseconds: 50 * index),
                        duration: 300.ms,
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed(
          'addDevice',
          pathParameters: {'siteId': widget.siteId},
        ),
        icon: const Icon(Icons.add),
        label: const Text('Cihaz Ekle'),
      ),
    );
  }

  Widget _buildStatistics(List<DeviceModel> devices) {
    final onlineCount = devices
        .where((d) => d.status == DeviceStatus.online)
        .length;
    final offlineCount = devices
        .where((d) => d.status == DeviceStatus.offline)
        .length;
    final errorCount = devices
        .where((d) => d.status == DeviceStatus.error)
        .length;
    final maintenanceCount = devices
        .where((d) => d.status == DeviceStatus.maintenance)
        .length;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              label: 'Çevrimiçi',
              count: onlineCount,
              color: Colors.green,
              icon: Icons.check_circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatCard(
              label: 'Çevrimdışı',
              count: offlineCount,
              color: Colors.grey,
              icon: Icons.cancel,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatCard(
              label: 'Hata',
              count: errorCount,
              color: Colors.red,
              icon: Icons.error,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatCard(
              label: 'Bakım',
              count: maintenanceCount,
              color: Colors.orange,
              icon: Icons.build,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 40,
      child: Row(
        children: [
          const Text(
            'Filtreler:',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                if (_filterStatus != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Chip(
                      label: Text(_getStatusText(_filterStatus!)),
                      onDeleted: () {
                        setState(() {
                          _filterStatus = null;
                        });
                      },
                    ),
                  ),
                if (_filterType != null)
                  Chip(
                    label: Text(_getTypeText(_filterType!)),
                    onDeleted: () {
                      setState(() {
                        _filterType = null;
                      });
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _FilterBottomSheet(
        selectedStatus: _filterStatus,
        selectedType: _filterType,
        onApply: (status, type) {
          setState(() {
            _filterStatus = status;
            _filterType = type;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showDeviceDetails(DeviceModel device) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _DeviceDetailsSheet(device: device),
    );
  }

  void _editDevice(DeviceModel device) {
    // TODO: Cihaz düzenleme sayfası
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Düzenleme özelliği yakında')));
  }

  void _toggleDeviceStatus(DeviceModel device) {
    // TODO: Cihaz durumunu değiştir
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${device.name} durumu değiştirildi')),
    );
  }

  void _deleteDevice(DeviceModel device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cihazı Sil'),
        content: Text(
          '${device.name} cihazını silmek istediğinize emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Cihaz silme
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cihaz silindi'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  String _getStatusText(DeviceStatus status) {
    switch (status) {
      case DeviceStatus.online:
        return 'Çevrimiçi';
      case DeviceStatus.offline:
        return 'Çevrimdışı';
      case DeviceStatus.error:
        return 'Hata';
      case DeviceStatus.maintenance:
        return 'Bakımda';
    }
  }

  String _getTypeText(DeviceType type) {
    switch (type) {
      case DeviceType.door:
        return 'Kapı';
      case DeviceType.barrier:
        return 'Bariyer';
      case DeviceType.gate:
        return 'Bahçe Kapısı';
      case DeviceType.turnstile:
        return 'Turnike';
    }
  }
}

// İstatistik kartı
class _StatCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 11, color: color)),
        ],
      ),
    );
  }
}

// Filtre bottom sheet
class _FilterBottomSheet extends StatefulWidget {
  final DeviceStatus? selectedStatus;
  final DeviceType? selectedType;
  final Function(DeviceStatus?, DeviceType?) onApply;

  const _FilterBottomSheet({
    required this.selectedStatus,
    required this.selectedType,
    required this.onApply,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  DeviceStatus? _selectedStatus;
  DeviceType? _selectedType;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.selectedStatus;
    _selectedType = widget.selectedType;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Filtrele', style: Theme.of(context).textTheme.titleLarge),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Durum filtreleri
            Text(
              'Cihaz Durumu',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('Tümü'),
                  selected: _selectedStatus == null,
                  onSelected: (selected) {
                    setState(() {
                      _selectedStatus = null;
                    });
                  },
                ),
                ...DeviceStatus.values.map((status) {
                  return FilterChip(
                    label: Text(_getStatusText(status)),
                    selected: _selectedStatus == status,
                    onSelected: (selected) {
                      setState(() {
                        _selectedStatus = selected ? status : null;
                      });
                    },
                  );
                }),
              ],
            ),
            const SizedBox(height: 24),

            // Tip filtreleri
            Text('Cihaz Tipi', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('Tümü'),
                  selected: _selectedType == null,
                  onSelected: (selected) {
                    setState(() {
                      _selectedType = null;
                    });
                  },
                ),
                ...DeviceType.values.map((type) {
                  return FilterChip(
                    label: Text(_getTypeText(type)),
                    selected: _selectedType == type,
                    onSelected: (selected) {
                      setState(() {
                        _selectedType = selected ? type : null;
                      });
                    },
                  );
                }),
              ],
            ),
            const SizedBox(height: 24),

            // Butonlar
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      widget.onApply(null, null);
                    },
                    child: const Text('Sıfırla'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      widget.onApply(_selectedStatus, _selectedType);
                    },
                    child: const Text('Uygula'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText(DeviceStatus status) {
    switch (status) {
      case DeviceStatus.online:
        return 'Çevrimiçi';
      case DeviceStatus.offline:
        return 'Çevrimdışı';
      case DeviceStatus.error:
        return 'Hata';
      case DeviceStatus.maintenance:
        return 'Bakımda';
    }
  }

  String _getTypeText(DeviceType type) {
    switch (type) {
      case DeviceType.door:
        return 'Kapı';
      case DeviceType.barrier:
        return 'Bariyer';
      case DeviceType.gate:
        return 'Bahçe Kapısı';
      case DeviceType.turnstile:
        return 'Turnike';
    }
  }
}

// Cihaz detayları sheet
class _DeviceDetailsSheet extends StatelessWidget {
  final DeviceModel device;

  const _DeviceDetailsSheet({required this.device});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Başlık
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: device.statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.door_front_door,
                      color: device.statusColor,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          device.typeDisplayName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Durum bilgileri
              _DetailSection(
                title: 'Durum Bilgileri',
                children: [
                  _DetailItem(
                    label: 'Durum',
                    value: device.statusDisplayName,
                    valueColor: device.statusColor,
                  ),
                  if (device.isOpen != null)
                    _DetailItem(
                      label: 'Kapı Durumu',
                      value: device.isOpen! ? 'Açık' : 'Kapalı',
                      valueColor: device.isOpen! ? Colors.orange : Colors.green,
                    ),
                  if (device.lastSeenAt != null)
                    _DetailItem(
                      label: 'Son Görülme',
                      value: _formatDateTime(device.lastSeenAt!),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Teknik bilgiler
              _DetailSection(
                title: 'Teknik Bilgiler',
                children: [
                  _DetailItem(
                    label: 'Cihaz ID',
                    value: device.id,
                    isMonospace: true,
                  ),
                  _DetailItem(
                    label: 'Tuya ID',
                    value: device.tuyaDeviceId,
                    isMonospace: true,
                  ),
                  if (device.batteryLevel != null)
                    _DetailItem(
                      label: 'Batarya',
                      value: '${device.batteryLevel}%',
                    ),
                  if (device.signalStrength != null)
                    _DetailItem(
                      label: 'Sinyal Gücü',
                      value: device.signalLevel,
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Sistem bilgileri
              _DetailSection(
                title: 'Sistem Bilgileri',
                children: [
                  _DetailItem(
                    label: 'Oluşturulma',
                    value: _formatDateTime(device.createdAt),
                  ),
                  _DetailItem(
                    label: 'Aktif',
                    value: device.isActive ? 'Evet' : 'Hayır',
                    valueColor: device.isActive ? Colors.green : Colors.red,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

// Detay bölümü
class _DetailSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _DetailSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }
}

// Detay öğesi
class _DetailItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isMonospace;

  const _DetailItem({
    required this.label,
    required this.value,
    this.valueColor,
    this.isMonospace = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: valueColor,
                fontFamily: isMonospace ? 'monospace' : null,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
