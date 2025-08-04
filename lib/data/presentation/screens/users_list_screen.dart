// lib/presentation/screens/site_admin/users/users_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:girisim/data/models/repositories/site_repository.dart';
import 'package:girisim/data/presentation/screens/add_site_screen.dart';
import 'package:girisim/data/presentation/widgets/search_field.dart';
import 'package:girisim/data/presentation/widgets/user_list_card.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../widgets/cards/user_list_card.dart';
import '../../../widgets/common/empty_state_widget.dart';
import '../../../widgets/common/search_field.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/models/site_model.dart';
import '../../../../data/repositories/site_repository.dart';

class UsersListScreen extends StatefulWidget {
  final String siteId;

  const UsersListScreen({super.key, required this.siteId});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SiteRepository _siteRepository = SiteRepository();
  final _searchController = TextEditingController();

  List<UserModel> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';
  UserRole? _filterRole;
  bool _showOnlyActive = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final users = await _siteRepository.getSiteUsers(widget.siteId);
      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kullanıcılar yüklenemedi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<UserModel> _getFilteredUsers() {
    return _users.where((user) {
      // Aktiflik filtresi
      if (_showOnlyActive && !user.isActive) return false;

      // Rol filtresi
      if (_filterRole != null && user.role != _filterRole) return false;

      // Arama filtresi
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return user.fullName.toLowerCase().contains(query) ||
            user.email.toLowerCase().contains(query) ||
            (user.phoneNumber?.contains(query) ?? false);
      }

      return true;
    }).toList();
  }

  List<UserModel> _getActiveUsers() {
    final now = DateTime.now();
    return _users.where((user) {
      if (user.lastLoginAt == null) return false;
      final difference = now.difference(user.lastLoginAt!);
      return difference.inDays <= 7; // Son 7 günde giriş yapmış
    }).toList();
  }

  List<UserModel> _getInactiveUsers() {
    final now = DateTime.now();
    return _users.where((user) {
      if (user.lastLoginAt == null) return true;
      final difference = now.difference(user.lastLoginAt!);
      return difference.inDays > 30; // 30 günden fazla giriş yapmamış
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kullanıcı Yönetimi'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tümü'),
            Tab(text: 'Aktif'),
            Tab(text: 'Pasif'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Arama ve istatistikler
                Container(
                  padding: const EdgeInsets.all(16),
                  color: theme.colorScheme.surface,
                  child: Column(
                    children: [
                      SearchField(
                        controller: _searchController,
                        hintText: 'Kullanıcı ara...',
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildStatistics(),
                    ],
                  ),
                ),

                // Kullanıcı listesi
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAllUsersTab(),
                      _buildActiveUsersTab(),
                      _buildInactiveUsersTab(),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed(
          'addSiteUser',
          pathParameters: {'siteId': widget.siteId},
        ),
        icon: const Icon(Icons.person_add),
        label: const Text('Kullanıcı Ekle'),
      ),
    );
  }

  Widget _buildStatistics() {
    final totalUsers = _users.length;
    final activeUsers = _getActiveUsers().length;
    final adminCount = _users.where((u) => u.role == UserRole.siteAdmin).length;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Toplam',
            value: totalUsers.toString(),
            icon: Icons.people,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: 'Aktif',
            value: activeUsers.toString(),
            icon: Icons.check_circle,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: 'Yönetici',
            value: adminCount.toString(),
            icon: Icons.admin_panel_settings,
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildAllUsersTab() {
    final users = _getFilteredUsers();

    if (users.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.people_outline,
        title: 'Kullanıcı bulunamadı',
        message: _searchQuery.isNotEmpty || _filterRole != null
            ? 'Arama kriterlerinize uygun kullanıcı yok'
            : 'Henüz kullanıcı eklenmemiş',
        actionLabel: _searchQuery.isNotEmpty || _filterRole != null
            ? 'Filtreleri Temizle'
            : 'Kullanıcı Ekle',
        onAction: () {
          if (_searchQuery.isNotEmpty || _filterRole != null) {
            setState(() {
              _searchController.clear();
              _searchQuery = '';
              _filterRole = null;
            });
          } else {
            context.pushNamed(
              'addSiteUser',
              pathParameters: {'siteId': widget.siteId},
            );
          }
        },
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return UserListCard(
            user: user,
            onTap: () => _showUserDetails(user),
            onEdit: () => _editUser(user),
            onToggleStatus: () => _toggleUserStatus(user),
            onResetPassword: () => _resetUserPassword(user),
            onRemove: () => _removeUser(user),
          ).animate().fadeIn(
            delay: Duration(milliseconds: 50 * index),
            duration: 300.ms,
          );
        },
      ),
    );
  }

  Widget _buildActiveUsersTab() {
    final activeUsers = _getActiveUsers();

    if (activeUsers.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.person_off,
        title: 'Aktif kullanıcı yok',
        message: 'Son 7 günde giriş yapan kullanıcı bulunmuyor',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activeUsers.length,
      itemBuilder: (context, index) {
        final user = activeUsers[index];
        return UserListCard(
          user: user,
          onTap: () => _showUserDetails(user),
          onEdit: () => _editUser(user),
          onToggleStatus: () => _toggleUserStatus(user),
          onResetPassword: () => _resetUserPassword(user),
          onRemove: () => _removeUser(user),
        );
      },
    );
  }

  Widget _buildInactiveUsersTab() {
    final inactiveUsers = _getInactiveUsers();

    if (inactiveUsers.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.person_outline,
        title: 'Pasif kullanıcı yok',
        message: 'Tüm kullanıcılar aktif durumda',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: inactiveUsers.length,
      itemBuilder: (context, index) {
        final user = inactiveUsers[index];
        return UserListCard(
          user: user,
          onTap: () => _showUserDetails(user),
          onEdit: () => _editUser(user),
          onToggleStatus: () => _toggleUserStatus(user),
          onResetPassword: () => _resetUserPassword(user),
          onRemove: () => _removeUser(user),
        );
      },
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _FilterBottomSheet(
        selectedRole: _filterRole,
        showOnlyActive: _showOnlyActive,
        onApply: (role, onlyActive) {
          setState(() {
            _filterRole = role;
            _showOnlyActive = onlyActive;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showUserDetails(UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _UserDetailsSheet(user: user),
    );
  }

  void _editUser(UserModel user) {
    // TODO: Kullanıcı düzenleme
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Düzenleme özelliği yakında')));
  }

  void _toggleUserStatus(UserModel user) {
    // TODO: Kullanıcı durumunu değiştir
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          user.isActive ? 'Kullanıcıyı Pasifleştir' : 'Kullanıcıyı Aktifleştir',
        ),
        content: Text(
          '${user.fullName} kullanıcısını ${user.isActive ? "pasifleştirmek" : "aktifleştirmek"} istediğinize emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: API çağrısı
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${user.fullName} ${user.isActive ? "pasifleştirildi" : "aktifleştirildi"}',
                  ),
                ),
              );
            },
            child: Text(user.isActive ? 'Pasifleştir' : 'Aktifleştir'),
          ),
        ],
      ),
    );
  }

  void _resetUserPassword(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Şifre Sıfırlama'),
        content: Text(
          '${user.fullName} kullanıcısına şifre sıfırlama e-postası gönderilecek.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Şifre sıfırlama
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Şifre sıfırlama e-postası gönderildi'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Gönder'),
          ),
        ],
      ),
    );
  }

  void _removeUser(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kullanıcıyı Kaldır'),
        content: Text(
          '${user.fullName} kullanıcısını bu siteden kaldırmak istediğinize emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _siteRepository.removeUserFromSite(
                  siteId: widget.siteId,
                  userId: user.id,
                );
                await _loadUsers();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Kullanıcı kaldırıldı'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Hata: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Kaldır'),
          ),
        ],
      ),
    );
  }
}

// İstatistik kartı
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
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
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }
}

// Filtre bottom sheet
class _FilterBottomSheet extends StatefulWidget {
  final UserRole? selectedRole;
  final bool showOnlyActive;
  final Function(UserRole?, bool) onApply;

  const _FilterBottomSheet({
    required this.selectedRole,
    required this.showOnlyActive,
    required this.onApply,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  UserRole? _selectedRole;
  bool _showOnlyActive = true;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.selectedRole;
    _showOnlyActive = widget.showOnlyActive;
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

            Text(
              'Kullanıcı Rolü',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('Tümü'),
                  selected: _selectedRole == null,
                  onSelected: (selected) {
                    setState(() {
                      _selectedRole = null;
                    });
                  },
                ),
                ...UserRole.values.map((role) {
                  return FilterChip(
                    label: Text(_getRoleText(role)),
                    selected: _selectedRole == role,
                    onSelected: (selected) {
                      setState(() {
                        _selectedRole = selected ? role : null;
                      });
                    },
                  );
                }),
              ],
            ),
            const SizedBox(height: 24),

            SwitchListTile(
              title: const Text('Sadece aktif kullanıcıları göster'),
              value: _showOnlyActive,
              onChanged: (value) {
                setState(() {
                  _showOnlyActive = value;
                });
              },
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      widget.onApply(null, true);
                    },
                    child: const Text('Sıfırla'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      widget.onApply(_selectedRole, _showOnlyActive);
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

  String _getRoleText(UserRole role) {
    switch (role) {
      case UserRole.globalAdmin:
        return 'Global Yönetici';
      case UserRole.siteAdmin:
        return 'Site Yöneticisi';
      case UserRole.user:
        return 'Kullanıcı';
    }
  }
}

// Kullanıcı detayları sheet
class _UserDetailsSheet extends StatelessWidget {
  final UserModel user;

  const _UserDetailsSheet({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
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

              // Profil başlığı
              Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: theme.colorScheme.primary,
                    child: Text(
                      user.fullName.substring(0, 2).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getRoleColor(user.role).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _getRoleText(user.role),
                            style: TextStyle(
                              color: _getRoleColor(user.role),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // İletişim bilgileri
              _DetailSection(
                title: 'İletişim Bilgileri',
                children: [
                  _DetailItem(
                    icon: Icons.email,
                    label: 'E-posta',
                    value: user.email,
                  ),
                  if (user.phoneNumber != null)
                    _DetailItem(
                      icon: Icons.phone,
                      label: 'Telefon',
                      value: user.phoneNumber!,
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Hesap bilgileri
              _DetailSection(
                title: 'Hesap Bilgileri',
                children: [
                  _DetailItem(
                    icon: Icons.check_circle,
                    label: 'Durum',
                    value: user.isActive ? 'Aktif' : 'Pasif',
                    valueColor: user.isActive ? Colors.green : Colors.red,
                  ),
                  _DetailItem(
                    icon: Icons.calendar_today,
                    label: 'Kayıt Tarihi',
                    value: _formatDate(user.createdAt),
                  ),
                  if (user.lastLoginAt != null)
                    _DetailItem(
                      icon: Icons.login,
                      label: 'Son Giriş',
                      value: _formatDate(user.lastLoginAt!),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Erişim bilgileri
              _DetailSection(
                title: 'Erişim Bilgileri',
                children: [
                  _DetailItem(
                    icon: Icons.business,
                    label: 'Site Sayısı',
                    value: user.siteIds.length.toString(),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getRoleText(UserRole role) {
    switch (role) {
      case UserRole.globalAdmin:
        return 'Global Yönetici';
      case UserRole.siteAdmin:
        return 'Site Yöneticisi';
      case UserRole.user:
        return 'Kullanıcı';
    }
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.globalAdmin:
        return Colors.red;
      case UserRole.siteAdmin:
        return Colors.orange;
      case UserRole.user:
        return Colors.blue;
    }
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
            padding: const EdgeInsets.all(12),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }
}

// Detay öğesi
class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
