// lib/presentation/screens/site_admin/users/add_user_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:girisim/data/models/repositories/site_repository.dart';
import 'package:girisim/data/presentation/providers/auth_provider.dart';
import 'package:girisim/data/presentation/widgets/loading_overlay.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/validators.dart';
import '../../../../data/models/user_model.dart';

class AddUserScreen extends StatefulWidget {
  final String siteId;

  const AddUserScreen({super.key, required this.siteId});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  UserRole _selectedRole = UserRole.user;
  String _generatedPassword = '';
  bool _sendWelcomeEmail = true;

  // İzinler
  final Map<String, bool> _permissions = {
    'canOpenDoors': true,
    'canCreateGuestQr': true,
    'canViewLogs': false,
    'canManageDevices': false,
    'canManageUsers': false,
  };

  @override
  void initState() {
    super.initState();
    _generatePassword();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _generatePassword() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*';
    final password = List.generate(
      12,
      (index) => chars[DateTime.now().millisecondsSinceEpoch % chars.length],
    ).join();

    setState(() {
      _generatedPassword = password;
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();

      // Kullanıcı oluştur
      final success = await authProvider.createUser(
        email: _emailController.text.trim(),
        password: _generatedPassword,
        fullName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        role: _selectedRole,
        siteIds: [widget.siteId],
      );

      if (!success) {
        throw Exception(
          authProvider.errorMessage ?? 'Kullanıcı oluşturulamadı',
        );
      }

      // Site'a kullanıcı ekle
      final siteRepository = SiteRepository();
      await siteRepository.addUserToSite(
        siteId: widget.siteId,
        userId: '', // TODO: Yeni oluşturulan kullanıcının ID'si
        permissions: _permissions,
      );

      if (!mounted) return;

      // Başarı mesajı
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _SuccessDialog(
          userName: _nameController.text.trim(),
          userEmail: _emailController.text.trim(),
          password: _generatedPassword,
          sendEmail: _sendWelcomeEmail,
          onClose: () {
            Navigator.of(context).pop();
            context.pop();
          },
        ),
      );
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
    final currentUser = context.watch<AuthProvider>().currentUser;
    final canAddAdmin = currentUser?.role == UserRole.globalAdmin;

    return Scaffold(
      appBar: AppBar(title: const Text('Yeni Kullanıcı Ekle')),
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: 'Kullanıcı oluşturuluyor...',
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Kullanıcı bilgileri
                _buildUserInfo().animate().fadeIn(duration: 300.ms),

                const SizedBox(height: 24),

                // Rol ve yetki
                _buildRoleAndPermissions(
                  canAddAdmin,
                ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

                const SizedBox(height: 24),

                // Şifre ve bildirim
                _buildPasswordSection().animate().fadeIn(
                  delay: 200.ms,
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
                        'Kullanıcıyı Ekle',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 300.ms)
                    .slideY(begin: 0.2, end: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kullanıcı Bilgileri',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Ad Soyad',
            prefixIcon: const Icon(Icons.person),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (value) =>
              Validators.required(value, fieldName: 'Ad soyad'),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: 'E-posta',
            hintText: 'ornek@email.com',
            prefixIcon: const Icon(Icons.email),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: Validators.email,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _phoneController,
          decoration: InputDecoration(
            labelText: 'Telefon (Opsiyonel)',
            hintText: '0555 555 55 55',
            prefixIcon: const Icon(Icons.phone),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: Validators.phone,
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _buildRoleAndPermissions(bool canAddAdmin) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rol ve Yetkiler',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Rol seçimi
        DropdownButtonFormField<UserRole>(
          value: _selectedRole,
          decoration: InputDecoration(
            labelText: 'Kullanıcı Rolü',
            prefixIcon: const Icon(Icons.admin_panel_settings),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: [
            const DropdownMenuItem(
              value: UserRole.user,
              child: Text('Normal Kullanıcı'),
            ),
            if (canAddAdmin)
              const DropdownMenuItem(
                value: UserRole.siteAdmin,
                child: Text('Site Yöneticisi'),
              ),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedRole = value;
                // Site admini seçilirse tüm yetkileri ver
                if (value == UserRole.siteAdmin) {
                  _permissions.updateAll((key, value) => true);
                }
              });
            }
          },
        ),
        const SizedBox(height: 16),

        // Yetkiler
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Yetkiler',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                SwitchListTile(
                  title: const Text('Kapı Açma'),
                  subtitle: const Text('Kapıları açıp kapatabilir'),
                  value: _permissions['canOpenDoors'] ?? true,
                  onChanged: _selectedRole == UserRole.siteAdmin
                      ? null
                      : (value) {
                          setState(() {
                            _permissions['canOpenDoors'] = value;
                          });
                        },
                  secondary: const Icon(Icons.door_front_door),
                ),

                SwitchListTile(
                  title: const Text('Misafir QR Oluşturma'),
                  subtitle: const Text('Misafirler için QR kod oluşturabilir'),
                  value: _permissions['canCreateGuestQr'] ?? true,
                  onChanged: _selectedRole == UserRole.siteAdmin
                      ? null
                      : (value) {
                          setState(() {
                            _permissions['canCreateGuestQr'] = value;
                          });
                        },
                  secondary: const Icon(Icons.qr_code),
                ),

                SwitchListTile(
                  title: const Text('Logları Görüntüleme'),
                  subtitle: const Text('Giriş çıkış kayıtlarını görebilir'),
                  value: _permissions['canViewLogs'] ?? false,
                  onChanged: _selectedRole == UserRole.siteAdmin
                      ? null
                      : (value) {
                          setState(() {
                            _permissions['canViewLogs'] = value;
                          });
                        },
                  secondary: const Icon(Icons.history),
                ),

                if (_selectedRole == UserRole.siteAdmin) ...[
                  SwitchListTile(
                    title: const Text('Cihaz Yönetimi'),
                    subtitle: const Text('Cihazları yönetebilir'),
                    value: _permissions['canManageDevices'] ?? false,
                    onChanged: null,
                    secondary: const Icon(Icons.devices),
                  ),

                  SwitchListTile(
                    title: const Text('Kullanıcı Yönetimi'),
                    subtitle: const Text('Kullanıcıları yönetebilir'),
                    value: _permissions['canManageUsers'] ?? false,
                    onChanged: null,
                    secondary: const Icon(Icons.people),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Şifre ve Bildirim',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Şifre
        Card(
          color: Theme.of(
            context,
          ).colorScheme.secondaryContainer.withOpacity(0.3),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.vpn_key,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Otomatik Oluşturulan Şifre',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _generatedPassword,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _generatePassword,
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Yeni Şifre Oluştur',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Bu şifre kullanıcıya iletilecektir. İlk girişte değiştirmesi önerilir.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // E-posta bildirimi
        SwitchListTile(
          title: const Text('Hoşgeldin E-postası Gönder'),
          subtitle: const Text('Giriş bilgileri e-posta ile gönderilsin'),
          value: _sendWelcomeEmail,
          onChanged: (value) {
            setState(() {
              _sendWelcomeEmail = value;
            });
          },
          secondary: const Icon(Icons.email),
        ),
      ],
    );
  }
}

// Başarı dialog'u
class _SuccessDialog extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String password;
  final bool sendEmail;
  final VoidCallback onClose;

  const _SuccessDialog({
    required this.userName,
    required this.userEmail,
    required this.password,
    required this.sendEmail,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          const Text('Kullanıcı Eklendi!'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            userName,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(userEmail, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Giriş Bilgileri:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.email, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        userEmail,
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.vpn_key, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        password,
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (sendEmail) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.check, size: 16, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Giriş bilgileri kullanıcıya e-posta ile gönderildi.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      actions: [FilledButton(onPressed: onClose, child: const Text('Tamam'))],
    );
  }
}
