// lib/presentation/screens/global_admin/sites/sites_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:girisim/data/presentation/providers/site_provider.dart';
import 'package:girisim/data/presentation/widgets/empty_state_widget.dart';
import 'package:girisim/data/presentation/widgets/search_field.dart';
import 'package:girisim/data/presentation/widgets/site_list_card.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/models/site_model.dart';

class SitesListScreen extends StatefulWidget {
  const SitesListScreen({super.key});

  @override
  State<SitesListScreen> createState() => _SitesListScreenState();
}

class _SitesListScreenState extends State<SitesListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  SiteType? _filterType;
  bool _showOnlyActive = true;

  @override
  void initState() {
    super.initState();
    // Siteleri yenile
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SiteProvider>().loadSites();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SiteModel> _getFilteredSites(List<SiteModel> sites) {
    return sites.where((site) {
      // Aktiflik filtresi
      if (_showOnlyActive && !site.isActive) return false;

      // Tip filtresi
      if (_filterType != null && site.type != _filterType) return false;

      // Arama filtresi
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return site.name.toLowerCase().contains(query) ||
            site.address.toLowerCase().contains(query);
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Siteler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.pushNamed('addSite'),
          ),
        ],
      ),
      body: Consumer<SiteProvider>(
        builder: (context, siteProvider, child) {
          if (siteProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final filteredSites = _getFilteredSites(siteProvider.sites);

          return RefreshIndicator(
            onRefresh: () async {
              await siteProvider.loadSites();
            },
            child: Column(
              children: [
                // Arama ve filtre bilgisi
                Container(
                  padding: const EdgeInsets.all(16),
                  color: theme.colorScheme.surface,
                  child: Column(
                    children: [
                      SearchField(
                        controller: _searchController,
                        hintText: 'Site ara...',
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                      if (_filterType != null || !_showOnlyActive) ...[
                        const SizedBox(height: 8),
                        _buildActiveFilters(),
                      ],
                    ],
                  ),
                ),

                // Site listesi
                Expanded(
                  child: filteredSites.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredSites.length,
                          itemBuilder: (context, index) {
                            final site = filteredSites[index];
                            return SiteListCard(
                              site: site,
                              onTap: () => context.pushNamed(
                                'siteDetail',
                                pathParameters: {'siteId': site.id},
                              ),
                              onEdit: () => _editSite(site),
                              onToggleStatus: () => _toggleSiteStatus(site),
                              onDelete: () => _deleteSite(site),
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
        onPressed: () => context.pushNamed('addSite'),
        icon: const Icon(Icons.add),
        label: const Text('Yeni Site'),
      ),
    );
  }

  Widget _buildActiveFilters() {
    return SizedBox(
      height: 32,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if (_filterType != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: Text(_getTypeText(_filterType!)),
                onDeleted: () {
                  setState(() {
                    _filterType = null;
                  });
                },
              ),
            ),
          if (!_showOnlyActive)
            Chip(
              label: const Text('Pasif siteler dahil'),
              onDeleted: () {
                setState(() {
                  _showOnlyActive = true;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    if (_searchQuery.isNotEmpty || _filterType != null) {
      return EmptyStateWidget(
        icon: Icons.search_off,
        title: 'Sonuç bulunamadı',
        message: 'Arama kriterlerinize uygun site bulunamadı.',
        actionLabel: 'Filtreleri Temizle',
        onAction: () {
          setState(() {
            _searchController.clear();
            _searchQuery = '';
            _filterType = null;
            _showOnlyActive = true;
          });
        },
      );
    }

    return EmptyStateWidget(
      icon: Icons.business_outlined,
      title: 'Henüz site eklenmemiş',
      message: 'İlk sitenizi ekleyerek başlayın.',
      actionLabel: 'Site Ekle',
      onAction: () => context.pushNamed('addSite'),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _FilterBottomSheet(
        selectedType: _filterType,
        showOnlyActive: _showOnlyActive,
        onApply: (type, onlyActive) {
          setState(() {
            _filterType = type;
            _showOnlyActive = onlyActive;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _editSite(SiteModel site) {
    // TODO: Site düzenleme sayfasına git
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Düzenleme özelliği yakında eklenecek')),
    );
  }

  void _toggleSiteStatus(SiteModel site) async {
    final siteProvider = context.read<SiteProvider>();
    final updatedSite = site.copyWith(isActive: !site.isActive);

    final success = await siteProvider.updateSite(updatedSite);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            site.isActive
                ? 'Site pasif duruma getirildi'
                : 'Site aktif duruma getirildi',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _deleteSite(SiteModel site) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Site Sil'),
        content: Text(
          '${site.name} sitesini silmek istediğinize emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              // TODO: Site silme işlemi
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Site silindi'),
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

  String _getTypeText(SiteType type) {
    switch (type) {
      case SiteType.residential:
        return 'Konut';
      case SiteType.business:
        return 'İş Merkezi';
      case SiteType.mixed:
        return 'Karma';
      case SiteType.factory:
        return 'Fabrika';
    }
  }
}

// Filtre bottom sheet
class _FilterBottomSheet extends StatefulWidget {
  final SiteType? selectedType;
  final bool showOnlyActive;
  final Function(SiteType?, bool) onApply;

  const _FilterBottomSheet({
    required this.selectedType,
    required this.showOnlyActive,
    required this.onApply,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late SiteType? _selectedType;
  late bool _showOnlyActive;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.selectedType;
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

            // Site tipi
            Text('Site Tipi', style: Theme.of(context).textTheme.titleMedium),
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
                ...SiteType.values.map((type) {
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

            // Aktiflik durumu
            SwitchListTile(
              title: const Text('Sadece aktif siteleri göster'),
              value: _showOnlyActive,
              onChanged: (value) {
                setState(() {
                  _showOnlyActive = value;
                });
              },
            ),
            const SizedBox(height: 24),

            // Butonlar
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
                      widget.onApply(_selectedType, _showOnlyActive);
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

  String _getTypeText(SiteType type) {
    switch (type) {
      case SiteType.residential:
        return 'Konut';
      case SiteType.business:
        return 'İş Merkezi';
      case SiteType.mixed:
        return 'Karma';
      case SiteType.factory:
        return 'Fabrika';
    }
  }
}
