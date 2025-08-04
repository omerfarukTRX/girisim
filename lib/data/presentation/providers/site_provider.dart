import 'package:flutter/material.dart';
import 'package:girisim/data/models/repositories/site_repository.dart';
import '../../models/site_model.dart';
import 'auth_provider.dart';

class SiteProvider extends ChangeNotifier {
  final SiteRepository _siteRepository = SiteRepository();

  List<SiteModel> _sites = [];
  SiteModel? _selectedSite;
  bool _isLoading = false;
  String? _errorMessage;
  AuthProvider? _authProvider;

  // Getters
  List<SiteModel> get sites => _sites;
  SiteModel? get selectedSite => _selectedSite;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void updateAuth(AuthProvider authProvider) {
    _authProvider = authProvider;
    if (_authProvider?.isAuthenticated ?? false) {
      loadSites();
    }
  }

  // Siteleri yükle
  Future<void> loadSites() async {
    try {
      _setLoading(true);
      _clearError();

      if (_authProvider?.currentUser == null) return;

      _sites = await _siteRepository.getSitesForUser(
        _authProvider!.currentUser!,
      );

      notifyListeners();
    } catch (e) {
      _setError('Siteler yüklenemedi: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Site seç
  void selectSite(SiteModel site) {
    _selectedSite = site;
    notifyListeners();
  }

  // Yeni site ekle (Global Admin)
  Future<bool> createSite({
    required String name,
    required String address,
    required SiteType type,
    required String adminId,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final siteId = await _siteRepository.createSite(
        name: name,
        address: address,
        type: type,
        adminId: adminId,
      );

      await loadSites();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Site güncelle
  Future<bool> updateSite(SiteModel site) async {
    try {
      _setLoading(true);
      _clearError();

      await _siteRepository.updateSite(site);
      await loadSites();

      if (_selectedSite?.id == site.id) {
        _selectedSite = site;
      }

      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Yardımcı metodlar
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
