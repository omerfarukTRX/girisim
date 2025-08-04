// lib/presentation/providers/auth_provider.dart

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:girisim/data/models/user_model.dart';
import 'package:girisim/data/repositories/auth_repository.dart';

enum AuthStatus {
  uninitialized,
  authenticated,
  authenticating,
  unauthenticated,
  error,
}

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();

  AuthStatus _status = AuthStatus.uninitialized;
  UserModel? _currentUser;
  String? _errorMessage;

  // Getters
  AuthStatus get status => _status;
  UserModel? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.authenticating;

  // Constructor
  AuthProvider() {
    _initializeAuth();
  }

  // Auth durumunu başlat
  void _initializeAuth() {
    _authRepository.authStateChanges.listen((User? user) async {
      if (user == null) {
        _setStatus(AuthStatus.unauthenticated);
        _currentUser = null;
      } else {
        await _loadUserData();
      }
    });
  }

  // Kullanıcı verilerini yükle
  Future<void> _loadUserData() async {
    try {
      final userData = await _authRepository.getCurrentUserData();
      if (userData != null) {
        _currentUser = userData;
        _setStatus(AuthStatus.authenticated);
      } else {
        _setStatus(AuthStatus.unauthenticated);
      }
    } catch (e) {
      _setError('Kullanıcı bilgileri yüklenemedi');
    }
  }

  // Giriş yap
  Future<bool> signIn({required String email, required String password}) async {
    try {
      _setStatus(AuthStatus.authenticating);
      _clearError();

      await _authRepository.signIn(email: email, password: password);

      await _loadUserData();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Yeni kullanıcı oluştur (Global Admin)
  Future<bool> createUser({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    required UserRole role,
    required List<String> siteIds,
  }) async {
    try {
      _clearError();

      // Sadece Global Admin kullanıcı oluşturabilir
      if (_currentUser?.role != UserRole.globalAdmin) {
        _setError('Bu işlem için yetkiniz yok');
        return false;
      }

      await _authRepository.createUser(
        email: email,
        password: password,
        fullName: fullName,
        phoneNumber: phoneNumber,
        role: role,
        siteIds: siteIds,
      );

      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Şifre sıfırlama
  Future<bool> resetPassword(String email) async {
    try {
      _clearError();
      await _authRepository.resetPassword(email);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Çıkış yap
  Future<void> signOut() async {
    try {
      await _authRepository.signOut();
      _currentUser = null;
      _setStatus(AuthStatus.unauthenticated);
    } catch (e) {
      _setError('Çıkış yapılamadı');
    }
  }

  // Şifre değiştir
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      _clearError();
      await _authRepository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Profil güncelle
  Future<bool> updateProfile({
    required String fullName,
    String? phoneNumber,
    String? profilePhotoUrl,
  }) async {
    try {
      _clearError();
      await _authRepository.updateProfile(
        fullName: fullName,
        phoneNumber: phoneNumber,
        profilePhotoUrl: profilePhotoUrl,
      );

      // Güncel veriyi yeniden yükle
      await _loadUserData();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Rol kontrolü
  bool hasRole(UserRole requiredRole) {
    if (_currentUser == null) return false;

    switch (requiredRole) {
      case UserRole.globalAdmin:
        return _currentUser!.role == UserRole.globalAdmin;
      case UserRole.siteAdmin:
        return _currentUser!.role == UserRole.globalAdmin ||
            _currentUser!.role == UserRole.siteAdmin;
      case UserRole.user:
        return true;
    }
  }

  // Site erişim kontrolü
  bool hasSiteAccess(String siteId) {
    if (_currentUser == null) return false;
    return _currentUser!.hasAccessToSite(siteId);
  }

  // Yardımcı metodlar
  void _setStatus(AuthStatus status) {
    _status = status;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _status = AuthStatus.error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  // Kullanıcıyı yenile
  Future<void> refreshUser() async {
    await _loadUserData();
  }
}
