// lib/presentation/screens/site_admin/logs/access_logs_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:girisim/data/models/repositories/site_repository.dart';
import 'package:girisim/data/presentation/widgets/empty_state_widget.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/access_log_model.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/models/device_model.dart';

class AccessLogsScreen extends StatefulWidget {
  final String siteId;

  const AccessLogsScreen({super.key, required this.siteId});

  @override
  State<AccessLogsScreen> createState() => _AccessLogsScreenState();
}

class _AccessLogsScreenState extends State<AccessLogsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SiteRepository _siteRepository = SiteRepository();
  final ScrollController _scrollController = ScrollController();

  List<AccessLogModel> _logs = [];
  List<AccessLogModel> _filteredLogs = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;

  // Filtreler
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedUserId;
  String? _selectedDeviceId;
  bool? _filterSuccess;

  // Sayfalama
  static const int _pageSize = 50;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController.addListener(_onScroll);
    _loadLogs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreLogs();
    }
  }

  Future<void> _loadLogs({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _logs.clear();
        _hasMore = true;
      });
    }

    setState(() {
      _isLoading = refresh || _logs.isEmpty;
    });

    try {
      final logs = await _siteRepository.getSiteAccessLogs(
        widget.siteId,
        limit: _pageSize,
        startDate: _startDate,
        endDate: _endDate,
        userId: _selectedUserId,
        deviceId: _selectedDeviceId,
      );

      if (mounted) {
        setState(() {
          _logs = logs;
          _filteredLogs = _filterLogsByTab(logs);
          _isLoading = false;
          _hasMore = logs.length >= _pageSize;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Loglar yüklenemedi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadMoreLogs() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      // Son log'un timestamp'ini al
      final lastTimestamp = _logs.isNotEmpty
          ? _logs.last.timestamp
          : DateTime.now();

      final moreLogs = await _siteRepository.getSiteAccessLogs(
        widget.siteId,
        limit: _pageSize,
        endDate: lastTimestamp,
        userId: _selectedUserId,
        deviceId: _selectedDeviceId,
      );

      if (mounted) {
        setState(() {
          _logs.addAll(moreLogs);
          _filteredLogs = _filterLogsByTab(_logs);
          _isLoadingMore = false;
          _hasMore = moreLogs.length >= _pageSize;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  List<AccessLogModel> _filterLogsByTab(List<AccessLogModel> logs) {
    switch (_tabController.index) {
      case 0: // Tümü
        return logs;
      case 1: // Başarılı
        return logs.where((log) => log.success).toList();
      case 2: // Başarısız
        return logs.where((log) => !log.success).toList();
      default:
        return logs;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Erişim Logları'),
        bottom: TabBar(
          controller: _tabController,
          onTap: (_) {
            setState(() {
              _filteredLogs = _filterLogsByTab(_logs);
            });
          },
          tabs: [
            Tab(
              text: 'Tümü',
              icon: Badge(
                label: Text(_logs.length.toString()),
                child: const Icon(Icons.list),
              ),
            ),
            Tab(
              text: 'Başarılı',
              icon: Badge(
                label: Text(_logs.where((l) => l.success).length.toString()),
                backgroundColor: Colors.green,
                child: const Icon(Icons.check_circle),
              ),
            ),
            Tab(
              text: 'Başarısız',
              icon: Badge(
                label: Text(_logs.where((l) => !l.success).length.toString()),
                backgroundColor: Colors.red,
                child: const Icon(Icons.error),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(icon: const Icon(Icons.download), onPressed: _exportLogs),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _loadLogs(refresh: true),
              child: Column(
                children: [
                  // Filtre bilgisi
                  if (_hasActiveFilters()) _buildActiveFilters(),

                  // Log listesi
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildLogList(),
                        _buildLogList(),
                        _buildLogList(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildActiveFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
      child: Row(
        children: [
          const Icon(Icons.filter_alt, size: 20),
          const SizedBox(width: 8),
          const Text('Filtreler aktif'),
          const Spacer(),
          TextButton(onPressed: _clearFilters, child: const Text('Temizle')),
        ],
      ),
    );
  }

  Widget _buildLogList() {
    if (_filteredLogs.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.history,
        title: 'Log bulunamadı',
        message: _hasActiveFilters()
            ? 'Filtre kriterlerinize uygun log yok'
            : 'Henüz erişim logu bulunmuyor',
        actionLabel: _hasActiveFilters() ? 'Filtreleri Temizle' : null,
        onAction: _hasActiveFilters() ? _clearFilters : null,
      );
    }

    // Logları tarihe göre grupla
    final groupedLogs = _groupLogsByDate(_filteredLogs);

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: groupedLogs.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= groupedLogs.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final dateGroup = groupedLogs.entries.elementAt(index);
        final date = dateGroup.key;
        final logs = dateGroup.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tarih başlığı
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _formatDateHeader(date),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${logs.length} kayıt',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),

            // O güne ait loglar
            ...logs.map((log) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AccessLogCard(
                  log: log,
                  onTap: () => _showLogDetails(log),
                ).animate().fadeIn(duration: 300.ms),
              );
            }),

            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Map<DateTime, List<AccessLogModel>> _groupLogsByDate(
    List<AccessLogModel> logs,
  ) {
    final grouped = <DateTime, List<AccessLogModel>>{};

    for (final log in logs) {
      final date = DateTime(
        log.timestamp.year,
        log.timestamp.month,
        log.timestamp.day,
      );

      if (grouped.containsKey(date)) {
        grouped[date]!.add(log);
      } else {
        grouped[date] = [log];
      }
    }

    return Map.fromEntries(
      grouped.entries.toList()..sort((a, b) => b.key.compareTo(a.key)),
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date == today) {
      return 'Bugün';
    } else if (date == yesterday) {
      return 'Dün';
    } else {
      return DateFormat('d MMMM yyyy', 'tr_TR').format(date);
    }
  }

  bool _hasActiveFilters() {
    return _startDate != null ||
        _endDate != null ||
        _selectedUserId != null ||
        _selectedDeviceId != null ||
        _filterSuccess != null;
  }

  void _clearFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _selectedUserId = null;
      _selectedDeviceId = null;
      _filterSuccess = null;
    });
    _loadLogs(refresh: true);
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _FilterBottomSheet(
        startDate: _startDate,
        endDate: _endDate,
        selectedUserId: _selectedUserId,
        selectedDeviceId: _selectedDeviceId,
        filterSuccess: _filterSuccess,
        siteId: widget.siteId,
        onApply: (start, end, userId, deviceId, success) {
          setState(() {
            _startDate = start;
            _endDate = end;
            _selectedUserId = userId;
            _selectedDeviceId = deviceId;
            _filterSuccess = success;
          });
          Navigator.pop(context);
          _loadLogs(refresh: true);
        },
      ),
    );
  }

  void _showLogDetails(AccessLogModel log) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _LogDetailsSheet(log: log),
    );
  }

  void _exportLogs() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logları Dışa Aktar'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('PDF olarak indir'),
              onTap: () {
                Navigator.pop(context);
                // TODO: PDF export
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PDF oluşturuluyor...')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('Excel olarak indir'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Excel export
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Excel oluşturuluyor...')),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
        ],
      ),
    );
  }
}

// Filtre bottom sheet
class _FilterBottomSheet extends StatefulWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? selectedUserId;
  final String? selectedDeviceId;
  final bool? filterSuccess;
  final String siteId;
  final Function(
    DateTime? start,
    DateTime? end,
    String? userId,
    String? deviceId,
    bool? success,
  )
  onApply;

  const _FilterBottomSheet({
    required this.startDate,
    required this.endDate,
    required this.selectedUserId,
    required this.selectedDeviceId,
    required this.filterSuccess,
    required this.siteId,
    required this.onApply,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedUserId;
  String? _selectedDeviceId;
  bool? _filterSuccess;

  @override
  void initState() {
    super.initState();
    _startDate = widget.startDate;
    _endDate = widget.endDate;
    _selectedUserId = widget.selectedUserId;
    _selectedDeviceId = widget.selectedDeviceId;
    _filterSuccess = widget.filterSuccess;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
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

            // Tarih aralığı
            Text(
              'Tarih Aralığı',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _startDate ?? DateTime.now(),
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 365),
                        ),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() {
                          _startDate = date;
                        });
                      }
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      _startDate != null
                          ? DateFormat('dd/MM/yyyy').format(_startDate!)
                          : 'Başlangıç',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _endDate ?? DateTime.now(),
                        firstDate:
                            _startDate ??
                            DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() {
                          _endDate = date;
                        });
                      }
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      _endDate != null
                          ? DateFormat('dd/MM/yyyy').format(_endDate!)
                          : 'Bitiş',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  label: const Text('Bugün'),
                  onPressed: () {
                    final now = DateTime.now();
                    setState(() {
                      _startDate = DateTime(now.year, now.month, now.day);
                      _endDate = now;
                    });
                  },
                ),
                ActionChip(
                  label: const Text('Son 7 Gün'),
                  onPressed: () {
                    final now = DateTime.now();
                    setState(() {
                      _startDate = now.subtract(const Duration(days: 7));
                      _endDate = now;
                    });
                  },
                ),
                ActionChip(
                  label: const Text('Son 30 Gün'),
                  onPressed: () {
                    final now = DateTime.now();
                    setState(() {
                      _startDate = now.subtract(const Duration(days: 30));
                      _endDate = now;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Durum filtresi
            Text('Durum', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                FilterChip(
                  label: const Text('Tümü'),
                  selected: _filterSuccess == null,
                  onSelected: (selected) {
                    setState(() {
                      _filterSuccess = null;
                    });
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Başarılı'),
                  selected: _filterSuccess == true,
                  onSelected: (selected) {
                    setState(() {
                      _filterSuccess = selected ? true : null;
                    });
                  },
                  avatar: const Icon(
                    Icons.check_circle,
                    size: 18,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Başarısız'),
                  selected: _filterSuccess == false,
                  onSelected: (selected) {
                    setState(() {
                      _filterSuccess = selected ? false : null;
                    });
                  },
                  avatar: const Icon(Icons.error, size: 18, color: Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // TODO: Kullanıcı ve cihaz filtreleri

            // Butonlar
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      widget.onApply(null, null, null, null, null);
                    },
                    child: const Text('Sıfırla'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      widget.onApply(
                        _startDate,
                        _endDate,
                        _selectedUserId,
                        _selectedDeviceId,
                        _filterSuccess,
                      );
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
}

// Log detayları sheet
class _LogDetailsSheet extends StatelessWidget {
  final AccessLogModel log;

  const _LogDetailsSheet({required this.log});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
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

          // Başlık
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: log.success
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  log.success ? Icons.check : Icons.close,
                  color: log.success ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.actionDisplayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm:ss').format(log.timestamp),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Detaylar
          _DetailItem(
            icon: Icons.person,
            label: 'Kullanıcı',
            value: log.userName ?? 'Bilinmiyor',
          ),
          const SizedBox(height: 12),
          _DetailItem(
            icon: Icons.door_front_door,
            label: 'Cihaz',
            value: log.deviceName ?? 'Bilinmiyor',
          ),
          const SizedBox(height: 12),
          _DetailItem(
            icon: Icons.fingerprint,
            label: 'Log ID',
            value: log.id,
            isMonospace: true,
          ),

          if (!log.success && log.errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hata Mesajı:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          log.errorMessage!,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Kapat butonu
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Kapat'),
            ),
          ),
        ],
      ),
    );
  }
}

// Detay öğesi
class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isMonospace;

  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
    this.isMonospace = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontFamily: isMonospace ? 'monospace' : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
