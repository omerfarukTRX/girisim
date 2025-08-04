import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:girisim/data/models/repositories/device_repository.dart';
import '../../models/device_model.dart';
import 'auth_provider.dart';

class DeviceProvider extends ChangeNotifier {
  final DeviceRepository _deviceRepository = DeviceRepository();

  List<DeviceModel> _devices = [];
  bool _isLoading = false;
  String? _errorMessage;
  AuthProvider? _authProvider;

  // Getters
  List<DeviceModel> get devices => _devices;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void updateAuth(AuthProvider authProvider) {
    _authProvider = authProvider;
  }

  // Site cihazlarını yükle
  Future<void> loadDevicesForSite(String siteId) async {
    try {
      _setLoading(true);
      _clearError();

      _devices = await _deviceRepository.getDevicesForSite(siteId);
      notifyListeners();
    } catch (e) {
      _setError('Cihazlar yüklenemedi: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Cihaz kontrolü
  Future<bool> controlDevice(String deviceId, String command) async {
    try {
      _clearError();

      await _deviceRepository.sendCommand(
        deviceId: deviceId,
        command: command,
        userId: _authProvider!.currentUser!.id,
      );

      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
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
