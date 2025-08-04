// lib/presentation/screens/global_admin/devices/add_device_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:girisim/data/models/repositories/device_repository.dart';
import 'package:girisim/data/presentation/providers/device_provider.dart';
import 'package:girisim/data/presentation/widgets/loading_overlay.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/validators.dart';
import '../../../../data/models/device_model.dart';

class AddDeviceScreen extends StatefulWidget {
  final String siteId;

  const AddDeviceScreen({super.key, required this.siteId});

  @override
  State<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends State<AddDeviceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _tuyaIdController = TextEditingController();
  final _tuyaProductIdController = TextEditingController();

  DeviceType _selectedType = DeviceType.door;
  bool _isLoading = false;
  bool _isTesting = false;
  bool _testSuccess = false;

  // Gelişmiş ayarlar
  bool _showAdvancedSettings = false;
  final Map<String, dynamic> _configuration = {
    'autoClose': false,
    'autoCloseDelay': 5,
    'emergencyOpen': true,
    'notifyOnUse': false,
  };

  @override
  void dispose() {
    _nameController.dispose();
    _tuyaIdController.dispose();
    _tuyaProductIdController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    if (_tuyaIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen Tuya Cihaz ID girin'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isTesting = true;
      _testSuccess = false;
    });

    // TODO: Gerçek Tuya API testi
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isTesting = false;
      _testSuccess = true; // Simülasyon için true
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _testSuccess ? Icons.check_circle : Icons.error,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Text(
              _testSuccess ? 'Cihaz bağlantısı başarılı!' : 'Cihaz bulunamadı',
            ),
          ],
        ),
        backgroundColor: _testSuccess ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_testSuccess) {
      final shouldContinue = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Uyarı'),
          content: const Text(
            'Cihaz bağlantısı test edilmedi. Yine de devam etmek istiyor musunuz?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Devam Et'),
            ),
          ],
        ),
      );

      if (shouldContinue != true) return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final deviceRepository = DeviceRepository();

      await deviceRepository.addDevice(
        siteId: widget.siteId,
        name: _nameController.text.trim(),
        type: _selectedType,
        tuyaDeviceId: _tuyaIdController.text.trim(),
        tuyaProductId: _tuyaProductIdController.text.trim().isEmpty
            ? null
            : _tuyaProductIdController.text.trim(),
        configuration: _showAdvancedSettings ? _configuration : null,
      );

      if (!mounted) return;

      // Cihaz listesini yenile
      await context.read<DeviceProvider>().loadDevicesForSite(widget.siteId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cihaz başarıyla eklendi!'),
          backgroundColor: Colors.green,
        ),
      );

      // Geri dön
      context.pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Yeni Cihaz Ekle')),
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: 'Cihaz ekleniyor...',
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Bilgi kartı
                _buildInfoCard().animate().fadeIn(duration: 300.ms),

                const SizedBox(height: 24),

                // Temel bilgiler
                _buildBasicInfo().animate().fadeIn(
                  delay: 100.ms,
                  duration: 300.ms,
                ),

                const SizedBox(height: 24),

                // Tuya entegrasyonu
                _buildTuyaIntegration().animate().fadeIn(
                  delay: 200.ms,
                  duration: 300.ms,
                ),

                const SizedBox(height: 24),

                // Gelişmiş ayarlar
                _buildAdvancedSettings().animate().fadeIn(
                  delay: 300.ms,
                  duration: 300.ms,
                ),

                const SizedBox(height: 32),

                // Kaydet butonu
                FilledButton(
                      onPressed: _handleSubmit,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cihazı Ekle',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 300.ms)
                    .slideY(begin: 0.2, end: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Cihazı eklemeden önce Tuya uygulamasında kayıtlı olduğundan emin olun.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Temel Bilgiler',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Cihaz Adı',
            hintText: 'Örn: Ana Giriş Kapısı',
            prefixIcon: const Icon(Icons.door_front_door),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (value) =>
              Validators.required(value, fieldName: 'Cihaz adı'),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),

        DropdownButtonFormField<DeviceType>(
          value: _selectedType,
          decoration: InputDecoration(
            labelText: 'Cihaz Tipi',
            prefixIcon: const Icon(Icons.category),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: DeviceType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Row(
                children: [
                  Icon(_getIconForType(type), size: 20),
                  const SizedBox(width: 8),
                  Text(_getTypeText(type)),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedType = value;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildTuyaIntegration() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Tuya Entegrasyonu',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Tuya Cihaz ID Nasıl Bulunur?'),
                    content: const SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('1. Tuya Smart uygulamasını açın'),
                          SizedBox(height: 8),
                          Text('2. Cihazınızı seçin'),
                          SizedBox(height: 8),
                          Text('3. Sağ üstteki ayarlar ikonuna tıklayın'),
                          SizedBox(height: 8),
                          Text('4. "Cihaz Bilgileri" bölümüne girin'),
                          SizedBox(height: 8),
                          Text('5. "Sanal ID" değerini kopyalayın'),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Anladım'),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.help_outline),
              iconSize: 20,
            ),
          ],
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _tuyaIdController,
          decoration: InputDecoration(
            labelText: 'Tuya Cihaz ID',
            hintText: 'Tuya uygulamasından kopyalayın',
            prefixIcon: const Icon(Icons.fingerprint),
            suffixIcon: _isTesting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    onPressed: _testConnection,
                    icon: Icon(
                      _testSuccess ? Icons.check_circle : Icons.refresh,
                      color: _testSuccess ? Colors.green : null,
                    ),
                    tooltip: 'Bağlantıyı Test Et',
                  ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (value) =>
              Validators.required(value, fieldName: 'Tuya ID'),
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _tuyaProductIdController,
          decoration: InputDecoration(
            labelText: 'Tuya Ürün ID (Opsiyonel)',
            hintText: 'Gelişmiş özellikler için',
            prefixIcon: const Icon(Icons.qr_code),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildAdvancedSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _showAdvancedSettings = !_showAdvancedSettings;
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(
                  _showAdvancedSettings ? Icons.expand_less : Icons.expand_more,
                ),
                const SizedBox(width: 8),
                Text(
                  'Gelişmiş Ayarlar',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),

        if (_showAdvancedSettings) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Otomatik Kapanma'),
                    subtitle: const Text(
                      'Kapı açıldıktan sonra otomatik kapat',
                    ),
                    value: _configuration['autoClose'] ?? false,
                    onChanged: (value) {
                      setState(() {
                        _configuration['autoClose'] = value;
                      });
                    },
                  ),

                  if (_configuration['autoClose'] == true) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Kapanma Süresi (saniye)'),
                              const SizedBox(height: 8),
                              Slider(
                                value: (_configuration['autoCloseDelay'] ?? 5)
                                    .toDouble(),
                                min: 3,
                                max: 30,
                                divisions: 27,
                                label:
                                    '${_configuration['autoCloseDelay'] ?? 5}s',
                                onChanged: (value) {
                                  setState(() {
                                    _configuration['autoCloseDelay'] = value
                                        .round();
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],

                  const Divider(),

                  SwitchListTile(
                    title: const Text('Acil Durum Açılımı'),
                    subtitle: const Text('Yangın alarmında otomatik aç'),
                    value: _configuration['emergencyOpen'] ?? true,
                    onChanged: (value) {
                      setState(() {
                        _configuration['emergencyOpen'] = value;
                      });
                    },
                  ),

                  const Divider(),

                  SwitchListTile(
                    title: const Text('Kullanım Bildirimi'),
                    subtitle: const Text('Her kullanımda bildirim gönder'),
                    value: _configuration['notifyOnUse'] ?? false,
                    onChanged: (value) {
                      setState(() {
                        _configuration['notifyOnUse'] = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
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
