// lib/presentation/screens/global_admin/sites/add_site_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:girisim/data/presentation/providers/auth_provider.dart';
import 'package:girisim/data/presentation/providers/site_provider.dart';
import 'package:girisim/data/presentation/widgets/loading_overlay.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/validators.dart';
import '../../../../data/models/site_model.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/models/device_model.dart';

class AddSiteScreen extends StatefulWidget {
  const AddSiteScreen({super.key});

  @override
  State<AddSiteScreen> createState() => _AddSiteScreenState();
}

class _AddSiteScreenState extends State<AddSiteScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isLoading = false;

  // Step 1: Site bilgileri
  final _siteNameController = TextEditingController();
  final _addressController = TextEditingController();
  SiteType _selectedType = SiteType.residential;

  // Step 2: Yetkili bilgileri
  final _adminNameController = TextEditingController();
  final _adminEmailController = TextEditingController();
  final _adminPhoneController = TextEditingController();
  String _adminPassword = '';

  // Step 3: Cihazlar
  final List<_DeviceInput> _devices = [];

  @override
  void dispose() {
    _siteNameController.dispose();
    _addressController.dispose();
    _adminNameController.dispose();
    _adminEmailController.dispose();
    _adminPhoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final siteProvider = context.read<SiteProvider>();

      // 1. Önce site adminini oluştur
      final adminCreated = await authProvider.createUser(
        email: _adminEmailController.text.trim(),
        password: _adminPassword,
        fullName: _adminNameController.text.trim(),
        phoneNumber: _adminPhoneController.text.trim(),
        role: UserRole.siteAdmin,
        siteIds: [], // Henüz site yok
      );

      if (!adminCreated) {
        throw Exception('Admin kullanıcısı oluşturulamadı');
      }

      // 2. Site'ı oluştur
      // TODO: Admin ID'sini al
      final siteCreated = await siteProvider.createSite(
        name: _siteNameController.text.trim(),
        address: _addressController.text.trim(),
        type: _selectedType,
        adminId: 'admin-user-id', // TODO: Gerçek admin ID
      );

      if (!siteCreated) {
        throw Exception('Site oluşturulamadı');
      }

      // 3. Cihazları ekle
      // TODO: Cihaz ekleme implementasyonu

      if (!mounted) return;

      // Başarılı
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Site başarıyla oluşturuldu!'),
          backgroundColor: Colors.green,
        ),
      );

      // Site listesine dön
      context.go('/admin/sites');
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
      appBar: AppBar(title: const Text('Yeni Site Ekle')),
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: 'Site oluşturuluyor...',
        child: Form(
          key: _formKey,
          child: Stepper(
            currentStep: _currentStep,
            onStepContinue: () {
              if (_currentStep < 2) {
                if (_validateCurrentStep()) {
                  setState(() {
                    _currentStep++;
                  });
                }
              } else {
                _handleSubmit();
              }
            },
            onStepCancel: () {
              if (_currentStep > 0) {
                setState(() {
                  _currentStep--;
                });
              } else {
                context.pop();
              }
            },
            controlsBuilder: (context, details) {
              return Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    FilledButton(
                      onPressed: details.onStepContinue,
                      child: Text(_currentStep == 2 ? 'Oluştur' : 'İleri'),
                    ),
                    const SizedBox(width: 12),
                    if (_currentStep > 0)
                      TextButton(
                        onPressed: details.onStepCancel,
                        child: const Text('Geri'),
                      ),
                  ],
                ),
              );
            },
            steps: [
              _buildSiteInfoStep(),
              _buildAdminInfoStep(),
              _buildDevicesStep(),
            ],
          ),
        ),
      ),
    );
  }

  Step _buildSiteInfoStep() {
    return Step(
      title: const Text('Site Bilgileri'),
      content: Column(
        children: [
          TextFormField(
            controller: _siteNameController,
            decoration: InputDecoration(
              labelText: 'Site Adı',
              hintText: 'Örn: Yeşil Vadi Sitesi',
              prefixIcon: const Icon(Icons.business),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) =>
                Validators.required(value, fieldName: 'Site adı'),
            textInputAction: TextInputAction.next,
          ).animate().fadeIn(duration: 300.ms),
          const SizedBox(height: 16),

          TextFormField(
            controller: _addressController,
            decoration: InputDecoration(
              labelText: 'Adres',
              hintText: 'Mahalle, Sokak, İlçe/İl',
              prefixIcon: const Icon(Icons.location_on),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) =>
                Validators.required(value, fieldName: 'Adres'),
            maxLines: 2,
          ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
          const SizedBox(height: 16),

          DropdownButtonFormField<SiteType>(
            value: _selectedType,
            decoration: InputDecoration(
              labelText: 'Site Tipi',
              prefixIcon: const Icon(Icons.category),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: SiteType.values.map((type) {
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
          ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
        ],
      ),
      isActive: _currentStep >= 0,
    );
  }

  Step _buildAdminInfoStep() {
    return Step(
      title: const Text('Site Yöneticisi'),
      content: Column(
        children: [
          Card(
            color: Theme.of(
              context,
            ).colorScheme.primaryContainer.withOpacity(0.3),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Site yöneticisi, site ile ilgili tüm işlemleri yapabilir.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 300.ms),
          const SizedBox(height: 16),

          TextFormField(
            controller: _adminNameController,
            decoration: InputDecoration(
              labelText: 'Ad Soyad',
              prefixIcon: const Icon(Icons.person),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) =>
                Validators.required(value, fieldName: 'Ad soyad'),
            textInputAction: TextInputAction.next,
          ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
          const SizedBox(height: 16),

          TextFormField(
            controller: _adminEmailController,
            decoration: InputDecoration(
              labelText: 'E-posta',
              hintText: 'ornek@email.com',
              prefixIcon: const Icon(Icons.email),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: Validators.email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
          const SizedBox(height: 16),

          TextFormField(
            controller: _adminPhoneController,
            decoration: InputDecoration(
              labelText: 'Telefon',
              hintText: '0555 555 55 55',
              prefixIcon: const Icon(Icons.phone),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: Validators.phone,
            keyboardType: TextInputType.phone,
          ).animate().fadeIn(delay: 300.ms, duration: 300.ms),
          const SizedBox(height: 16),

          // Şifre oluştur butonu
          OutlinedButton.icon(
            onPressed: _generatePassword,
            icon: const Icon(Icons.vpn_key),
            label: Text(
              _adminPassword.isEmpty
                  ? 'Şifre Oluştur'
                  : 'Şifre: $_adminPassword',
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ).animate().fadeIn(delay: 400.ms, duration: 300.ms),

          if (_adminPassword.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Bu şifreyi yöneticiye iletin',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.orange),
            ),
          ],
        ],
      ),
      isActive: _currentStep >= 1,
    );
  }

  Step _buildDevicesStep() {
    return Step(
      title: const Text('Cihaz Yapılandırması'),
      content: Column(
        children: [
          if (_devices.isEmpty)
            EmptyStateWidget(
              icon: Icons.devices_other,
              title: 'Henüz cihaz eklenmedi',
              message: 'Site için kapı kontrol cihazları ekleyin.',
            ).animate().fadeIn(duration: 300.ms)
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _devices.length,
              itemBuilder: (context, index) {
                return _DeviceInputCard(
                  device: _devices[index],
                  onRemove: () {
                    setState(() {
                      _devices.removeAt(index);
                    });
                  },
                ).animate().fadeIn(
                  delay: Duration(milliseconds: 100 * index),
                  duration: 300.ms,
                );
              },
            ),
          const SizedBox(height: 16),

          OutlinedButton.icon(
            onPressed: _addDevice,
            icon: const Icon(Icons.add),
            label: const Text('Cihaz Ekle'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 300.ms),

          const SizedBox(height: 16),
          Card(
            color: Theme.of(
              context,
            ).colorScheme.secondaryContainer.withOpacity(0.3),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Cihazları daha sonra da ekleyebilirsiniz.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 300.ms, duration: 300.ms),
        ],
      ),
      isActive: _currentStep >= 2,
    );
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _siteNameController.text.isNotEmpty &&
            _addressController.text.isNotEmpty;
      case 1:
        return _adminNameController.text.isNotEmpty &&
            _adminEmailController.text.isNotEmpty &&
            _adminPassword.isNotEmpty;
      case 2:
        return true; // Cihazlar opsiyonel
      default:
        return false;
    }
  }

  void _generatePassword() {
    // Basit bir şifre oluşturucu
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final password = List.generate(
      8,
      (index) => chars[DateTime.now().millisecondsSinceEpoch % chars.length],
    ).join();

    setState(() {
      _adminPassword = password;
    });
  }

  void _addDevice() {
    showDialog(
      context: context,
      builder: (context) => _AddDeviceDialog(
        onAdd: (device) {
          setState(() {
            _devices.add(device);
          });
        },
      ),
    );
  }

  IconData _getIconForType(SiteType type) {
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

  String _getTypeText(SiteType type) {
    switch (type) {
      case SiteType.residential:
        return 'Konut Sitesi';
      case SiteType.business:
        return 'İş Merkezi';
      case SiteType.mixed:
        return 'Karma (Konut + İş)';
      case SiteType.factory:
        return 'Fabrika/Sanayi';
    }
  }
}

// Cihaz input modeli
class _DeviceInput {
  final String name;
  final DeviceType type;
  final String tuyaId;

  _DeviceInput({required this.name, required this.type, required this.tuyaId});
}

// Cihaz input kartı
class _DeviceInputCard extends StatelessWidget {
  final _DeviceInput device;
  final VoidCallback onRemove;

  const _DeviceInputCard({required this.device, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(_getIconForType(device.type)),
        title: Text(device.name),
        subtitle: Text('ID: ${device.tuyaId}'),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: onRemove,
        ),
      ),
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
}

// Cihaz ekleme dialog
class _AddDeviceDialog extends StatefulWidget {
  final Function(_DeviceInput) onAdd;

  const _AddDeviceDialog({required this.onAdd});

  @override
  State<_AddDeviceDialog> createState() => _AddDeviceDialogState();
}

class _AddDeviceDialogState extends State<_AddDeviceDialog> {
  final _nameController = TextEditingController();
  final _tuyaIdController = TextEditingController();
  DeviceType _selectedType = DeviceType.door;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Yeni Cihaz'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Cihaz Adı',
              hintText: 'Örn: Ana Giriş Kapısı',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _tuyaIdController,
            decoration: const InputDecoration(
              labelText: 'Tuya Cihaz ID',
              hintText: 'Tuya uygulamasından alın',
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<DeviceType>(
            value: _selectedType,
            decoration: const InputDecoration(labelText: 'Cihaz Tipi'),
            items: DeviceType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(_getTypeText(type)),
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
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        FilledButton(
          onPressed: () {
            if (_nameController.text.isNotEmpty &&
                _tuyaIdController.text.isNotEmpty) {
              widget.onAdd(
                _DeviceInput(
                  name: _nameController.text,
                  type: _selectedType,
                  tuyaId: _tuyaIdController.text,
                ),
              );
              Navigator.pop(context);
            }
          },
          child: const Text('Ekle'),
        ),
      ],
    );
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

// Empty state widget (geçici)
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Icon(icon, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(message, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
