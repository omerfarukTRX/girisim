// lib/data/repositories/auth_repository.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:girisim/data/models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Mevcut kullanıcıyı getir
  User? get currentUser => _auth.currentUser;

  // Auth durumu stream'i
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Kullanıcı bilgilerini getir
  Future<UserModel?> getCurrentUserData() async {
    try {
      final user = currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return null;

      return UserModel.fromFirestore(doc);
    } catch (e) {
      print('Error getting current user data: $e');
      return null;
    }
  }

  // Giriş yap
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Son giriş zamanını güncelle
      await _updateLastLogin(credential.user!.uid);

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Kayıt ol (Sadece Global Admin yapabilir)
  Future<UserModel> createUser({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    required UserRole role,
    required List<String> siteIds,
  }) async {
    try {
      // Yeni kullanıcı oluştur
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Kullanıcı modelini oluştur
      final userModel = UserModel(
        id: credential.user!.uid,
        email: email,
        fullName: fullName,
        phoneNumber: phoneNumber,
        role: role,
        siteIds: siteIds,
        isActive: true,
        createdAt: DateTime.now(),
      );

      // Firestore'a kaydet
      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set(userModel.toFirestore());

      // Display name'i güncelle
      await credential.user!.updateDisplayName(fullName);

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Şifre sıfırlama
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Çıkış yap
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Şifre değiştir
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = currentUser;
      if (user == null) throw 'Kullanıcı bulunamadı';

      // Yeniden kimlik doğrulama
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Şifreyi güncelle
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Profil güncelle
  Future<void> updateProfile({
    required String fullName,
    String? phoneNumber,
    String? profilePhotoUrl,
  }) async {
    try {
      final user = currentUser;
      if (user == null) throw 'Kullanıcı bulunamadı';

      // Firebase Auth display name güncelle
      await user.updateDisplayName(fullName);
      if (profilePhotoUrl != null) {
        await user.updatePhotoURL(profilePhotoUrl);
      }

      // Firestore'da güncelle
      await _firestore.collection('users').doc(user.uid).update({
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'profilePhotoUrl': profilePhotoUrl,
        'lastModifiedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Profil güncellenemedi: $e';
    }
  }

  // Son giriş zamanını güncelle
  Future<void> _updateLastLogin(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating last login: $e');
    }
  }

  // Auth hatalarını işle
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Kullanıcı bulunamadı';
      case 'wrong-password':
        return 'Hatalı şifre';
      case 'email-already-in-use':
        return 'Bu e-posta adresi zaten kullanımda';
      case 'invalid-email':
        return 'Geçersiz e-posta adresi';
      case 'weak-password':
        return 'Şifre çok zayıf';
      case 'user-disabled':
        return 'Bu hesap devre dışı bırakılmış';
      case 'too-many-requests':
        return 'Çok fazla başarısız deneme. Lütfen daha sonra tekrar deneyin';
      default:
        return 'Bir hata oluştu: ${e.message}';
    }
  }

  // Kullanıcı rolünü kontrol et
  Future<bool> checkUserRole(UserRole requiredRole) async {
    try {
      final userData = await getCurrentUserData();
      if (userData == null) return false;

      switch (requiredRole) {
        case UserRole.globalAdmin:
          return userData.role == UserRole.globalAdmin;
        case UserRole.siteAdmin:
          return userData.role == UserRole.globalAdmin ||
              userData.role == UserRole.siteAdmin;
        case UserRole.user:
          return true; // Tüm roller user yetkilerine sahip
      }
    } catch (e) {
      return false;
    }
  }

  // Site erişimini kontrol et
  Future<bool> checkSiteAccess(String siteId) async {
    try {
      final userData = await getCurrentUserData();
      if (userData == null) return false;

      return userData.hasAccessToSite(siteId);
    } catch (e) {
      return false;
    }
  }
}
