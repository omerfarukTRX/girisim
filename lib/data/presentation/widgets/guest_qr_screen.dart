// lib/presentation/screens/user/guest_qr_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:girisim/data/presentation/providers/auth_provider.dart';
import 'package:girisim/data/presentation/providers/site_provider.dart';
import 'package:girisim/data/presentation/widgets/loading_overlay.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/auth_provider.dart';
import '../../providers/site_provider.dart';
import '../../../widgets/common/loading_overlay.dart';
import '../../../../core/utils/validators.dart';

class GuestQRScreen extends StatefulWidget {
  const GuestQRScreen({super.key});

  @override
  State<GuestQRScreen> createState() => _GuestQRScreenState();
}

class _GuestQRScreenState extends State<GuestQRScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Form kontrolleri
  final _guestNameController = TextEditingController();
  final _guestPhoneController = TextEditingController();
  final _noteController = TextEditingController();

  // QR ayarları
  bool _singleUse = true;
  DateTime _validFrom = DateTime.now();
  DateTime _validUntil = DateTime.now().add(const Duration(hours: 24));
  final List<String> _selectedDoors = [];

  // Oluşturulan QR
  String? _generatedQRData;
  bool _isGenerating = false;

  // Aktif QR'lar
  final List<_GuestQR> _activeQRs = []; // TODO: Firebase'den çek

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadActiveQRs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _guestNameController.dispose();
    _guestPhoneController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _loadActiveQRs() {
    // TODO: Firebase'den aktif QR'ları çek
    setState(() {
      _activeQRs.addAll([
        _GuestQR(
          id: '1',
          guestName: 'Ali Veli',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          validUntil: DateTime.now().add(const Duration(hours: 22)),
          isUsed: false,
          singleUse: true,
        ),
        _GuestQR(
          id: '2',
          guestName: 'Ayşe Kaya',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          validUntil: DateTime.now().add(const Duration(days: 6)),
          isUsed: true,
          usedAt: DateTime.now().subtract(const Duration(hours: 18)),
          singleUse: false,
        ),
      ]);
    });
  }

  Future<void> _generateQR() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isGenerating = true;
    });

    try {
      final user = context.read<AuthProvider>().currentUser;
      final site = context.read<SiteProvider>().selectedSite;

      if (user == null || site == null) {
        throw Exception('Kullanıcı veya site bilgisi bulunamadı');
      }

      // QR verisi oluştur
      final qrData = {
        'type': 'guest',
        'siteId': site.id,
        'createdBy': user.id,
        'guestName': _guestNameController.text.trim(),
        'guestPhone': _guestPhoneController.text.trim(),
        'validFrom': _validFrom.toIso8601String(),
        'validUntil': _validUntil.toIso8601String(),
        'singleUse': _singleUse,
        'doors': _selectedDoors,
        'note': _noteController.text.trim(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      // TODO: Firebase'e kaydet ve unique ID al
      final qrId = DateTime.now().millisecondsSinceEpoch.toString();

      setState(() {
        _generatedQRData = qrId; // Gerçek uygulamada encrypted data
        _tabController.animateTo(1); // QR görüntüleme tabına geç
      });

      // Formu temizle
      _guestNameController.clear();
      _guestPhoneController.clear();
      _noteController.clear();
      setState(() {
        _singleUse = true;
        _validFrom = DateTime.now();
        _validUntil = DateTime.now().add(const Duration(hours: 24));
        _selectedDoors.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Misafir QR Kodu'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Yeni QR Oluştur'),
            Tab(text: 'Aktif QR\'lar'),
          ],
        ),
      ),
      body: LoadingOverlay(
        isLoading: _isGenerating,
        message: 'QR kodu oluşturuluyor...',
        child: TabBarView(
          controller: _tabController,
          children: [_buildCreateTab(), _buildActiveQRsTab()],
        ),
      ),
    );
  }

  Widget _buildCreateTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Misafir bilgileri
            _buildGuestInfo().animate().fadeIn(duration: 300.ms),

            const SizedBox(height: 24),

            // Geçerlilik ayarları
            _buildValiditySettings().animate().fadeIn(
              delay: 100.ms,
              duration: 300.ms,
            ),

            const SizedBox(height: 24),

            // Kapı izinleri
            _buildDoorPermissions().animate().fadeIn(
              delay: 200.ms,
              duration: 300.ms,
            ),

            const SizedBox(height: 24),

            // Not
            _buildNote().animate().fadeIn(delay: 300.ms, duration: 300.ms),

            const SizedBox(height: 32),

            // Oluştur butonu
            FilledButton(
                  onPressed: _generateQR,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'QR Kodu Oluştur',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                )
                .animate()
                .fadeIn(delay: 400.ms, duration: 300.ms)
                .slideY(begin: 0.2, end: 0),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Misafir Bilgileri',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _guestNameController,
          decoration: InputDecoration(
            labelText: 'Misafir Adı',
            prefixIcon: const Icon(Icons.person),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (value) =>
              Validators.required(value, fieldName: 'Misafir adı'),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _guestPhoneController,
          decoration: InputDecoration(
            labelText: 'Telefon (Opsiyonel)',
            hintText: '0555 555 55 55',
            prefixIcon: const Icon(Icons.phone),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _buildValiditySettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Geçerlilik Ayarları',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Tek kullanımlık
        SwitchListTile(
          title: const Text('Tek Kullanımlık'),
          subtitle: const Text(
            'QR kod bir kez kullanıldıktan sonra geçersiz olur',
          ),
          value: _singleUse,
          onChanged: (value) {
            setState(() {
              _singleUse = value;
            });
          },
          secondary: const Icon(Icons.looks_one),
        ),
        const SizedBox(height: 16),

        // Başlangıç zamanı
        ListTile(
          leading: const Icon(Icons.play_arrow),
          title: const Text('Başlangıç'),
          subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(_validFrom)),
          trailing: const Icon(Icons.edit),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _validFrom,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );

            if (date != null && mounted) {
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(_validFrom),
              );

              if (time != null && mounted) {
                setState(() {
                  _validFrom = DateTime(
                    date.year,
                    date.month,
                    date.day,
                    time.hour,
                    time.minute,
                  );
                });
              }
            }
          },
        ),
        const Divider(),

        // Bitiş zamanı
        ListTile(
          leading: const Icon(Icons.stop),
          title: const Text('Bitiş'),
          subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(_validUntil)),
          trailing: const Icon(Icons.edit),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _validUntil,
              firstDate: _validFrom,
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );

            if (date != null && mounted) {
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(_validUntil),
              );

              if (time != null && mounted) {
                setState(() {
                  _validUntil = DateTime(
                    date.year,
                    date.month,
                    date.day,
                    time.hour,
                    time.minute,
                  );
                });
              }
            }
          },
        ),
        const SizedBox(height: 8),

        // Hızlı seçimler
        Wrap(
          spacing: 8,
          children: [
            ActionChip(
              label: const Text('1 Saat'),
              onPressed: () {
                setState(() {
                  _validFrom = DateTime.now();
                  _validUntil = DateTime.now().add(const Duration(hours: 1));
                });
              },
            ),
            ActionChip(
              label: const Text('4 Saat'),
              onPressed: () {
                setState(() {
                  _validFrom = DateTime.now();
                  _validUntil = DateTime.now().add(const Duration(hours: 4));
                });
              },
            ),
            ActionChip(
              label: const Text('1 Gün'),
              onPressed: () {
                setState(() {
                  _validFrom = DateTime.now();
                  _validUntil = DateTime.now().add(const Duration(days: 1));
                });
              },
            ),
            ActionChip(
              label: const Text('1 Hafta'),
              onPressed: () {
                setState(() {
                  _validFrom = DateTime.now();
                  _validUntil = DateTime.now().add(const Duration(days: 7));
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDoorPermissions() {
    // TODO: Site'daki kapıları getir
    final doors = [
      {'id': '1', 'name': 'Ana Giriş'},
      {'id': '2', 'name': 'Otopark'},
      {'id': '3', 'name': 'Bahçe Kapısı'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kapı İzinleri',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Misafirin hangi kapıları açabileceğini seçin',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),

        Card(
          child: Column(
            children: doors.map((door) {
              final isSelected = _selectedDoors.contains(door['id']);
              return CheckboxListTile(
                title: Text(door['name']!),
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedDoors.add(door['id']!);
                    } else {
                      _selectedDoors.remove(door['id']);
                    }
                  });
                },
                secondary: const Icon(Icons.door_front_door),
              );
            }).toList(),
          ),
        ),

        if (_selectedDoors.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Icon(Icons.warning, size: 16, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'En az bir kapı seçilmelidir',
                    style: TextStyle(color: Colors.orange, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildNote() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Not (Opsiyonel)',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _noteController,
          decoration: InputDecoration(
            hintText: 'Örn: Toplantı için gelecek',
            prefixIcon: const Icon(Icons.note),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildActiveQRsTab() {
    if (_generatedQRData != null) {
      return _buildGeneratedQR();
    }

    if (_activeQRs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.qr_code_2,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Aktif QR kodunuz yok',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Yeni bir QR kodu oluşturun',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _activeQRs.length,
      itemBuilder: (context, index) {
        final qr = _activeQRs[index];
        return _ActiveQRCard(
          qr: qr,
          onTap: () {
            setState(() {
              _generatedQRData = qr.id;
            });
          },
          onDelete: () {
            // TODO: QR'ı iptal et
            setState(() {
              _activeQRs.removeAt(index);
            });
          },
        );
      },
    );
  }

  Widget _buildGeneratedQR() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // QR kod
          Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: _generatedQRData!,
                  version: QrVersions.auto,
                  size: 250,
                  backgroundColor: Colors.white,
                ),
              )
              .animate()
              .fadeIn(duration: 600.ms)
              .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),

          const SizedBox(height: 24),

          // QR bilgileri
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('Misafir'),
                    subtitle: Text(_guestNameController.text),
                  ),
                  ListTile(
                    leading: const Icon(Icons.access_time),
                    title: const Text('Geçerlilik'),
                    subtitle: Text(
                      '${DateFormat('dd/MM HH:mm').format(_validFrom)} - ${DateFormat('dd/MM HH:mm').format(_validUntil)}',
                    ),
                  ),
                  if (_singleUse)
                    const ListTile(
                      leading: Icon(Icons.looks_one),
                      title: Text('Tek kullanımlık'),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // İşlemler
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Share.share(
                      'GirişİM - Misafir QR Kodu\n\n'
                      'Misafir: ${_guestNameController.text}\n'
                      'Geçerlilik: ${DateFormat('dd/MM/yyyy HH:mm').format(_validFrom)} - ${DateFormat('dd/MM/yyyy HH:mm').format(_validUntil)}\n\n'
                      'QR Kod: $_generatedQRData',
                    );
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('Paylaş'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    setState(() {
                      _generatedQRData = null;
                      _tabController.animateTo(0);
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Yeni QR'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Aktif QR modeli
class _GuestQR {
  final String id;
  final String guestName;
  final DateTime createdAt;
  final DateTime validUntil;
  final bool singleUse;
  final bool isUsed;
  final DateTime? usedAt;

  _GuestQR({
    required this.id,
    required this.guestName,
    required this.createdAt,
    required this.validUntil,
    required this.singleUse,
    required this.isUsed,
    this.usedAt,
  });
}

// Aktif QR kartı
class _ActiveQRCard extends StatelessWidget {
  final _GuestQR qr;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ActiveQRCard({
    required this.qr,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final isExpired = qr.validUntil.isBefore(now);
    final isActive = !isExpired && !qr.isUsed;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: isActive ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Durum ikonu
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.green.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.qr_code,
                  color: isActive ? Colors.green : Colors.grey,
                ),
              ),
              const SizedBox(width: 16),

              // QR bilgileri
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      qr.guestName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Bitiş: ${DateFormat('dd/MM HH:mm').format(qr.validUntil)}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (qr.singleUse)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Tek kullanımlık',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                        if (qr.isUsed) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Kullanıldı',
                              style: TextStyle(fontSize: 11, color: Colors.red),
                            ),
                          ),
                        ],
                        if (isExpired) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Süresi doldu',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // İptal butonu
              if (isActive)
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete, color: Colors.red),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
