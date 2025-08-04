// lib/data/repositories/device_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:girisim/data/models/access_log_model.dart';
import 'package:girisim/data/models/device_model.dart';

class DeviceRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TuyaApiService _tuyaService = TuyaApiService();

  // Site'a ait cihazları getir
  Future<List<DeviceModel>> getDevicesForSite(String siteId) async {
    try {
      final snapshot = await _firestore
          .collection('sites')
          .doc(siteId)
          .collection('devices')
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      return snapshot.docs
          .map((doc) => DeviceModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw 'Cihazlar yüklenemedi: $e';
    }
  }

  // Tek bir cihazı getir
  Future<DeviceModel?> getDevice(String siteId, String deviceId) async {
    try {
      final doc = await _firestore
          .collection('sites')
          .doc(siteId)
          .collection('devices')
          .doc(deviceId)
          .get();

      if (!doc.exists) return null;
      return DeviceModel.fromFirestore(doc);
    } catch (e) {
      throw 'Cihaz bilgisi alınamadı: $e';
    }
  }

  // Cihaz durumunu güncelle (Tuya'dan)
  Future<void> updateDeviceStatus(String siteId, String deviceId) async {
    try {
      final device = await getDevice(siteId, deviceId);
      if (device == null) throw 'Cihaz bulunamadı';

      // Tuya API'den güncel durumu al
      final status = await _tuyaService.getDeviceStatus(device.tuyaDeviceId);

      // Firestore'da güncelle
      await _firestore
          .collection('sites')
          .doc(siteId)
          .collection('devices')
          .doc(deviceId)
          .update({
            'status': status['online'] ? 'online' : 'offline',
            'isOpen': status['isOpen'],
            'batteryLevel': status['batteryLevel'],
            'signalStrength': status['signalStrength'],
            'lastSeenAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw 'Cihaz durumu güncellenemedi: $e';
    }
  }

  // Cihaza komut gönder
  Future<void> sendCommand({
    required String deviceId,
    required String command,
    required String userId,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      // Önce cihazı bul
      final deviceQuery = await _firestore
          .collectionGroup('devices')
          .where(FieldPath.documentId, isEqualTo: deviceId)
          .limit(1)
          .get();

      if (deviceQuery.docs.isEmpty) throw 'Cihaz bulunamadı';

      final deviceDoc = deviceQuery.docs.first;
      final device = DeviceModel.fromFirestore(deviceDoc);
      final siteId = device.siteId;

      // Tuya API'ye komut gönder
      await _tuyaService.sendCommand(
        deviceId: device.tuyaDeviceId,
        command: command,
        parameters: parameters,
      );

      // Access log kaydet
      await _createAccessLog(
        siteId: siteId,
        deviceId: deviceId,
        userId: userId,
        action: command,
        success: true,
      );

      // Cihaz durumunu güncelle
      await updateDeviceStatus(siteId, deviceId);
    } catch (e) {
      // Hata durumunda da log kaydet
      try {
        final deviceQuery = await _firestore
            .collectionGroup('devices')
            .where(FieldPath.documentId, isEqualTo: deviceId)
            .limit(1)
            .get();

        if (deviceQuery.docs.isNotEmpty) {
          final device = DeviceModel.fromFirestore(deviceQuery.docs.first);
          await _createAccessLog(
            siteId: device.siteId,
            deviceId: deviceId,
            userId: userId,
            action: command,
            success: false,
            errorMessage: e.toString(),
          );
        }
      } catch (_) {}

      throw 'Komut gönderilemedi: $e';
    }
  }

  // Yeni cihaz ekle
  Future<String> addDevice({
    required String siteId,
    required String name,
    required DeviceType type,
    required String tuyaDeviceId,
    String? tuyaProductId,
    Map<String, dynamic>? configuration,
  }) async {
    try {
      // Tuya cihazını kontrol et
      final tuyaDevice = await _tuyaService.getDeviceInfo(tuyaDeviceId);
      if (tuyaDevice == null) throw 'Tuya cihazı bulunamadı';

      final device = DeviceModel(
        id: '', // Firestore otomatik oluşturacak
        name: name,
        siteId: siteId,
        type: type,
        status: DeviceStatus.online,
        tuyaDeviceId: tuyaDeviceId,
        tuyaProductId: tuyaProductId ?? tuyaDevice['productId'],
        isActive: true,
        createdAt: DateTime.now(),
        configuration: configuration,
        metadata: {'tuyaInfo': tuyaDevice},
      );

      final docRef = await _firestore
          .collection('sites')
          .doc(siteId)
          .collection('devices')
          .add(device.toFirestore());

      // Site'ın device listesini güncelle
      await _firestore.collection('sites').doc(siteId).update({
        'deviceIds': FieldValue.arrayUnion([docRef.id]),
        'totalDevices': FieldValue.increment(1),
      });

      return docRef.id;
    } catch (e) {
      throw 'Cihaz eklenemedi: $e';
    }
  }

  // Cihaz güncelle
  Future<void> updateDevice(DeviceModel device) async {
    try {
      await _firestore
          .collection('sites')
          .doc(device.siteId)
          .collection('devices')
          .doc(device.id)
          .update(device.toFirestore());
    } catch (e) {
      throw 'Cihaz güncellenemedi: $e';
    }
  }

  // Cihaz sil (soft delete)
  Future<void> deleteDevice(String siteId, String deviceId) async {
    try {
      // Cihazı pasifleştir
      await _firestore
          .collection('sites')
          .doc(siteId)
          .collection('devices')
          .doc(deviceId)
          .update({
            'isActive': false,
            'deactivatedAt': FieldValue.serverTimestamp(),
          });

      // Site'ın device listesinden çıkar
      await _firestore.collection('sites').doc(siteId).update({
        'deviceIds': FieldValue.arrayRemove([deviceId]),
        'totalDevices': FieldValue.increment(-1),
      });
    } catch (e) {
      throw 'Cihaz silinemedi: $e';
    }
  }

  // Cihaz durumlarını toplu güncelle
  Future<void> refreshAllDeviceStatuses(String siteId) async {
    try {
      final devices = await getDevicesForSite(siteId);

      // Paralel olarak güncelle
      await Future.wait(
        devices.map((device) => updateDeviceStatus(siteId, device.id)),
      );
    } catch (e) {
      throw 'Cihaz durumları güncellenemedi: $e';
    }
  }

  // Erişim logu oluştur
  Future<void> _createAccessLog({
    required String siteId,
    required String deviceId,
    required String userId,
    required String action,
    required bool success,
    String? errorMessage,
  }) async {
    try {
      final log = AccessLogModel(
        id: '',
        siteId: siteId,
        deviceId: deviceId,
        userId: userId,
        action: action,
        timestamp: DateTime.now(),
        success: success,
        errorMessage: errorMessage,
      );

      await _firestore
          .collection('sites')
          .doc(siteId)
          .collection('access_logs')
          .add(log.toFirestore());

      // Bugünkü giriş sayısını güncelle
      if (success && (action == 'open' || action == 'toggle')) {
        await _firestore.collection('sites').doc(siteId).update({
          'todayAccessCount': FieldValue.increment(1),
        });
      }
    } catch (e) {
      print('Access log kaydedilemedi: $e');
    }
  }

  // Cihaz istatistiklerini getir
  Future<Map<String, dynamic>> getDeviceStatistics(
    String siteId,
    String deviceId,
  ) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final startOfMonth = DateTime(now.year, now.month, 1);

      // Bugünkü kullanım
      final todayLogs = await _firestore
          .collection('sites')
          .doc(siteId)
          .collection('access_logs')
          .where('deviceId', isEqualTo: deviceId)
          .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
          .where('success', isEqualTo: true)
          .count()
          .get();

      // Aylık kullanım
      final monthlyLogs = await _firestore
          .collection('sites')
          .doc(siteId)
          .collection('access_logs')
          .where('deviceId', isEqualTo: deviceId)
          .where('timestamp', isGreaterThanOrEqualTo: startOfMonth)
          .where('success', isEqualTo: true)
          .count()
          .get();

      // Son kullanım
      final lastUsage = await _firestore
          .collection('sites')
          .doc(siteId)
          .collection('access_logs')
          .where('deviceId', isEqualTo: deviceId)
          .where('success', isEqualTo: true)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      return {
        'todayUsageCount': todayLogs.count,
        'monthlyUsageCount': monthlyLogs.count,
        'lastUsedAt': lastUsage.docs.isNotEmpty
            ? (lastUsage.docs.first.data()['timestamp'] as Timestamp).toDate()
            : null,
      };
    } catch (e) {
      throw 'İstatistikler alınamadı: $e';
    }
  }

  // Cihaz durumu stream'i
  Stream<DeviceModel?> deviceStream(String siteId, String deviceId) {
    return _firestore
        .collection('sites')
        .doc(siteId)
        .collection('devices')
        .doc(deviceId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) return null;
          return DeviceModel.fromFirestore(snapshot);
        });
  }

  // Site cihazları stream'i
  Stream<List<DeviceModel>> siteDevicesStream(String siteId) {
    return _firestore
        .collection('sites')
        .doc(siteId)
        .collection('devices')
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => DeviceModel.fromFirestore(doc))
              .toList();
        });
  }
}
