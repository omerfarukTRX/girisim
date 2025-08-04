// lib/data/models/access_log_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class AccessLogModel {
  final String id;
  final String siteId;
  final String deviceId;
  final String userId;
  final String action; // open, close, toggle
  final DateTime timestamp;
  final bool success;
  final String? errorMessage;
  final Map<String, dynamic>? metadata;

  // İlişkili bilgiler (join için)
  final String? userName;
  final String? deviceName;

  AccessLogModel({
    required this.id,
    required this.siteId,
    required this.deviceId,
    required this.userId,
    required this.action,
    required this.timestamp,
    required this.success,
    this.errorMessage,
    this.metadata,
    this.userName,
    this.deviceName,
  });

  factory AccessLogModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AccessLogModel(
      id: doc.id,
      siteId: data['siteId'] ?? '',
      deviceId: data['deviceId'] ?? '',
      userId: data['userId'] ?? '',
      action: data['action'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      success: data['success'] ?? false,
      errorMessage: data['errorMessage'],
      metadata: data['metadata'],
      userName: data['userName'],
      deviceName: data['deviceName'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'siteId': siteId,
      'deviceId': deviceId,
      'userId': userId,
      'action': action,
      'timestamp': Timestamp.fromDate(timestamp),
      'success': success,
      'errorMessage': errorMessage,
      'metadata': metadata,
      'userName': userName,
      'deviceName': deviceName,
    };
  }

  // Action için Türkçe açıklama
  String get actionDisplayName {
    switch (action) {
      case 'open':
        return 'Açıldı';
      case 'close':
        return 'Kapandı';
      case 'toggle':
        return 'Değiştirildi';
      default:
        return action;
    }
  }

  // Log mesajı oluştur
  String get logMessage {
    final deviceText = deviceName ?? 'Cihaz';
    final userText = userName ?? 'Kullanıcı';

    if (success) {
      return '$userText tarafından $deviceText $actionDisplayName';
    } else {
      return '$userText $deviceText kontrolünde başarısız: ${errorMessage ?? 'Bilinmeyen hata'}';
    }
  }

  // Zaman formatı
  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Az önce';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} dakika önce';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} saat önce';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
