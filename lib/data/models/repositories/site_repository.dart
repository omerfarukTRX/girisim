// lib/data/repositories/site_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/site_model.dart';
import '../models/user_model.dart';
import '../models/device_model.dart';
import '../models/access_log_model.dart';

class SiteRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Kullanıcının erişebildiği siteleri getir
  Future<List<SiteModel>> getSitesForUser(UserModel user) async {
    try {
      Query query = _firestore.collection('sites');

      // Global admin değilse, sadece erişim yetkisi olan siteleri getir
      if (!user.isGlobalAdmin) {
        if (user.isSiteAdmin) {
          // Site admin ise kendi yönettiği siteleri getir
          query = query.where('adminId', isEqualTo: user.id);
        } else {
          // Normal kullanıcı ise erişimi olan siteleri getir
          if (user.siteIds.isEmpty) return [];
          query = query.where(FieldPath.documentId, whereIn: user.siteIds);
        }
      }

      final snapshot = await query
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      return snapshot.docs.map((doc) => SiteModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw 'Siteler yüklenemedi: $e';
    }
  }

  // Tek bir siteyi getir
  Future<SiteModel?> getSite(String siteId) async {
    try {
      final doc = await _firestore.collection('sites').doc(siteId).get();

      if (!doc.exists) return null;
      return SiteModel.fromFirestore(doc);
    } catch (e) {
      throw 'Site bilgisi alınamadı: $e';
    }
  }

  // Yeni site oluştur
  Future<String> createSite({
    required String name,
    required String address,
    required SiteType type,
    required String adminId,
    Map<String, dynamic>? settings,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Admin kullanıcısının varlığını kontrol et
      final adminDoc = await _firestore.collection('users').doc(adminId).get();
      if (!adminDoc.exists) throw 'Admin kullanıcısı bulunamadı';

      final site = SiteModel(
        id: '', // Firestore otomatik oluşturacak
        name: name,
        address: address,
        type: type,
        adminId: adminId,
        deviceIds: [],
        userIds: [adminId], // Admin otomatik olarak site kullanıcısı
        isActive: true,
        createdAt: DateTime.now(),
        settings: settings ?? _getDefaultSettings(type),
        metadata: metadata,
      );

      // Site'ı oluştur
      final docRef = await _firestore
          .collection('sites')
          .add(site.toFirestore());

      // Admin kullanıcısının site listesini güncelle
      await _firestore.collection('users').doc(adminId).update({
        'siteIds': FieldValue.arrayUnion([docRef.id]),
      });

      // Admin'in rolünü güncelle (eğer normal kullanıcıysa)
      final adminData = UserModel.fromFirestore(adminDoc);
      if (adminData.role == UserRole.user) {
        await _firestore.collection('users').doc(adminId).update({
          'role': UserRole.siteAdmin.toString().split('.').last,
        });
      }

      return docRef.id;
    } catch (e) {
      throw 'Site oluşturulamadı: $e';
    }
  }

  // Site güncelle
  Future<void> updateSite(SiteModel site) async {
    try {
      await _firestore.collection('sites').doc(site.id).update({
        ...site.toFirestore(),
        'lastModifiedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Site güncellenemedi: $e';
    }
  }

  // Site sil (soft delete)
  Future<void> deleteSite(String siteId) async {
    try {
      // Site'ı pasifleştir
      await _firestore.collection('sites').doc(siteId).update({
        'isActive': false,
        'deactivatedAt': FieldValue.serverTimestamp(),
      });

      // Tüm kullanıcıların site erişimini kaldır
      final siteDoc = await getSite(siteId);
      if (siteDoc != null) {
        final batch = _firestore.batch();

        for (final userId in siteDoc.userIds) {
          batch.update(_firestore.collection('users').doc(userId), {
            'siteIds': FieldValue.arrayRemove([siteId]),
          });
        }

        await batch.commit();
      }
    } catch (e) {
      throw 'Site silinemedi: $e';
    }
  }

  // Site'a kullanıcı ekle
  Future<void> addUserToSite({
    required String siteId,
    required String userId,
    Map<String, dynamic>? permissions,
  }) async {
    try {
      final batch = _firestore.batch();

      // Site'ın kullanıcı listesine ekle
      batch.update(_firestore.collection('sites').doc(siteId), {
        'userIds': FieldValue.arrayUnion([userId]),
        'totalUsers': FieldValue.increment(1),
      });

      // Kullanıcının site listesine ekle
      batch.update(_firestore.collection('users').doc(userId), {
        'siteIds': FieldValue.arrayUnion([siteId]),
      });

      // Site kullanıcı koleksiyonuna ekle (detaylı izinler için)
      batch.set(
        _firestore
            .collection('sites')
            .doc(siteId)
            .collection('users')
            .doc(userId),
        {
          'addedAt': FieldValue.serverTimestamp(),
          'permissions': permissions ?? _getDefaultPermissions(),
          'isActive': true,
        },
      );

      await batch.commit();
    } catch (e) {
      throw 'Kullanıcı eklenemedi: $e';
    }
  }

  // Site'dan kullanıcı çıkar
  Future<void> removeUserFromSite({
    required String siteId,
    required String userId,
  }) async {
    try {
      final batch = _firestore.batch();

      // Site'ın kullanıcı listesinden çıkar
      batch.update(_firestore.collection('sites').doc(siteId), {
        'userIds': FieldValue.arrayRemove([userId]),
        'totalUsers': FieldValue.increment(-1),
      });

      // Kullanıcının site listesinden çıkar
      batch.update(_firestore.collection('users').doc(userId), {
        'siteIds': FieldValue.arrayRemove([siteId]),
      });

      // Site kullanıcı koleksiyonundan sil
      batch.delete(
        _firestore
            .collection('sites')
            .doc(siteId)
            .collection('users')
            .doc(userId),
      );

      await batch.commit();
    } catch (e) {
      throw 'Kullanıcı çıkarılamadı: $e';
    }
  }

  // Site adminini değiştir
  Future<void> changeSiteAdmin({
    required String siteId,
    required String newAdminId,
  }) async {
    try {
      // Yeni admin'in site kullanıcısı olduğunu kontrol et
      final site = await getSite(siteId);
      if (site == null) throw 'Site bulunamadı';

      if (!site.userIds.contains(newAdminId)) {
        throw 'Yeni admin site kullanıcısı değil';
      }

      // Site adminini güncelle
      await _firestore.collection('sites').doc(siteId).update({
        'adminId': newAdminId,
        'lastModifiedAt': FieldValue.serverTimestamp(),
      });

      // Yeni admin'in rolünü güncelle
      final userDoc = await _firestore
          .collection('users')
          .doc(newAdminId)
          .get();
      final userData = UserModel.fromFirestore(userDoc);

      if (userData.role == UserRole.user) {
        await _firestore.collection('users').doc(newAdminId).update({
          'role': UserRole.siteAdmin.toString().split('.').last,
        });
      }
    } catch (e) {
      throw 'Admin değiştirilemedi: $e';
    }
  }

  // Site istatistiklerini getir
  Future<Map<String, dynamic>> getSiteStatistics(String siteId) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startOfMonth = DateTime(now.year, now.month, 1);

      // Bugünkü giriş sayısı
      final todayAccess = await _firestore
          .collection('sites')
          .doc(siteId)
          .collection('access_logs')
          .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
          .where('success', isEqualTo: true)
          .count()
          .get();

      // Haftalık giriş sayısı
      final weeklyAccess = await _firestore
          .collection('sites')
          .doc(siteId)
          .collection('access_logs')
          .where('timestamp', isGreaterThanOrEqualTo: startOfWeek)
          .where('success', isEqualTo: true)
          .count()
          .get();

      // Aylık giriş sayısı
      final monthlyAccess = await _firestore
          .collection('sites')
          .doc(siteId)
          .collection('access_logs')
          .where('timestamp', isGreaterThanOrEqualTo: startOfMonth)
          .where('success', isEqualTo: true)
          .count()
          .get();

      // Aktif cihaz sayısı
      final activeDevices = await _firestore
          .collection('sites')
          .doc(siteId)
          .collection('devices')
          .where('isActive', isEqualTo: true)
          .where('status', isEqualTo: 'online')
          .count()
          .get();

      // Toplam kullanıcı sayısı
      final totalUsers = await _firestore
          .collection('sites')
          .doc(siteId)
          .collection('users')
          .where('isActive', isEqualTo: true)
          .count()
          .get();

      return {
        'todayAccessCount': todayAccess.count,
        'weeklyAccessCount': weeklyAccess.count,
        'monthlyAccessCount': monthlyAccess.count,
        'activeDeviceCount': activeDevices.count,
        'totalUserCount': totalUsers.count,
      };
    } catch (e) {
      throw 'İstatistikler alınamadı: $e';
    }
  }

  // Site kullanıcılarını getir
  Future<List<UserModel>> getSiteUsers(String siteId) async {
    try {
      final site = await getSite(siteId);
      if (site == null) throw 'Site bulunamadı';

      if (site.userIds.isEmpty) return [];

      // Kullanıcı bilgilerini toplu getir
      final userDocs = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: site.userIds)
          .get();

      return userDocs.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw 'Kullanıcılar yüklenemedi: $e';
    }
  }

  // Site erişim loglarını getir
  Future<List<AccessLogModel>> getSiteAccessLogs(
    String siteId, {
    int limit = 50,
    DateTime? startDate,
    DateTime? endDate,
    String? userId,
    String? deviceId,
  }) async {
    try {
      Query query = _firestore
          .collection('sites')
          .doc(siteId)
          .collection('access_logs');

      // Filtreler
      if (startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: startDate);
      }
      if (endDate != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: endDate);
      }
      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }
      if (deviceId != null) {
        query = query.where('deviceId', isEqualTo: deviceId);
      }

      final snapshot = await query
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => AccessLogModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw 'Erişim logları yüklenemedi: $e';
    }
  }

  // Site stream'i
  Stream<SiteModel?> siteStream(String siteId) {
    return _firestore.collection('sites').doc(siteId).snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists) return null;
      return SiteModel.fromFirestore(snapshot);
    });
  }

  // Kullanıcının siteleri stream'i
  Stream<List<SiteModel>> userSitesStream(UserModel user) {
    Query query = _firestore.collection('sites');

    if (!user.isGlobalAdmin) {
      if (user.isSiteAdmin) {
        query = query.where('adminId', isEqualTo: user.id);
      } else {
        if (user.siteIds.isEmpty) {
          return Stream.value([]);
        }
        query = query.where(FieldPath.documentId, whereIn: user.siteIds);
      }
    }

    return query
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => SiteModel.fromFirestore(doc))
              .toList();
        });
  }

  // Varsayılan site ayarları
  Map<String, dynamic> _getDefaultSettings(SiteType type) {
    return {
      'autoOpenEmergency': true, // Acil durumda otomatik aç
      'guestQrEnabled': true, // Misafir QR kodu aktif
      'accessTimeRestriction': false, // Zaman kısıtlaması
      'notifyOnAccess': false, // Her girişte bildirim
      'requireApproval': false, // Giriş onayı gerekli
      'maxGuestDuration': 24, // Misafir QR geçerlilik (saat)
    };
  }

  // Varsayılan kullanıcı izinleri
  Map<String, dynamic> _getDefaultPermissions() {
    return {
      'canOpenDoors': true,
      'canCreateGuestQr': true,
      'canViewLogs': false,
      'canManageDevices': false,
      'canManageUsers': false,
    };
  }
}
