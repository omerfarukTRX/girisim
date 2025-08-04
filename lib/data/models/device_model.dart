// lib/data/models/device_model.dart

import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';

enum DeviceType { door, barrier, gate, turnstile }

enum DeviceStatus { online, offline, error, maintenance }

class DeviceModel {
  final String id;
  final String name;
  final String siteId;
  final DeviceType type;
  final DeviceStatus status;
  final String tuyaDeviceId;
  final String? tuyaProductId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastSeenAt;
  final Map<String, dynamic>? configuration;
  final Map<String, dynamic>? metadata;

  // Cihaz durumu
  final bool? isOpen;
  final int? batteryLevel;
  final double? signalStrength;

  DeviceModel({
    required this.id,
    required this.name,
    required this.siteId,
    required this.type,
    required this.status,
    required this.tuyaDeviceId,
    this.tuyaProductId,
    required this.isActive,
    required this.createdAt,
    this.lastSeenAt,
    this.configuration,
    this.metadata,
    this.isOpen,
    this.batteryLevel,
    this.signalStrength,
  });

  factory DeviceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DeviceModel(
      id: doc.id,
      name: data['name'] ?? '',
      siteId: data['siteId'] ?? '',
      type: DeviceType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => DeviceType.door,
      ),
      status: DeviceStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => DeviceStatus.offline,
      ),
      tuyaDeviceId: data['tuyaDeviceId'] ?? '',
      tuyaProductId: data['tuyaProductId'],
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastSeenAt: data['lastSeenAt'] != null
          ? (data['lastSeenAt'] as Timestamp).toDate()
          : null,
      configuration: data['configuration'],
      metadata: data['metadata'],
      isOpen: data['isOpen'],
      batteryLevel: data['batteryLevel'],
      signalStrength: data['signalStrength']?.toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'siteId': siteId,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'tuyaDeviceId': tuyaDeviceId,
      'tuyaProductId': tuyaProductId,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastSeenAt': lastSeenAt != null
          ? Timestamp.fromDate(lastSeenAt!)
          : FieldValue.serverTimestamp(),
      'configuration': configuration,
      'metadata': metadata,
      'isOpen': isOpen,
      'batteryLevel': batteryLevel,
      'signalStrength': signalStrength,
    };
  }

  DeviceModel copyWith({
    String? id,
    String? name,
    String? siteId,
    DeviceType? type,
    DeviceStatus? status,
    String? tuyaDeviceId,
    String? tuyaProductId,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastSeenAt,
    Map<String, dynamic>? configuration,
    Map<String, dynamic>? metadata,
    bool? isOpen,
    int? batteryLevel,
    double? signalStrength,
  }) {
    return DeviceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      siteId: siteId ?? this.siteId,
      type: type ?? this.type,
      status: status ?? this.status,
      tuyaDeviceId: tuyaDeviceId ?? this.tuyaDeviceId,
      tuyaProductId: tuyaProductId ?? this.tuyaProductId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      configuration: configuration ?? this.configuration,
      metadata: metadata ?? this.metadata,
      isOpen: isOpen ?? this.isOpen,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      signalStrength: signalStrength ?? this.signalStrength,
    );
  }

  // Cihaz tipi için Türkçe isim
  String get typeDisplayName {
    switch (type) {
      case DeviceType.door:
        return 'Kapı';
      case DeviceType.barrier:
        return 'Bariyer';
      case DeviceType.gate:
        return 'Bahçe Kapısı';
      case DeviceType.turnstile:
        return 'Turnike';
    }
  }

  // Cihaz durumu için Türkçe isim
  String get statusDisplayName {
    switch (status) {
      case DeviceStatus.online:
        return 'Çevrimiçi';
      case DeviceStatus.offline:
        return 'Çevrimdışı';
      case DeviceStatus.error:
        return 'Hata';
      case DeviceStatus.maintenance:
        return 'Bakımda';
    }
  }

  // Durum rengi
  Color get statusColor {
    switch (status) {
      case DeviceStatus.online:
        return const Color(0xFF4CAF50); // Yeşil
      case DeviceStatus.offline:
        return const Color(0xFF9E9E9E); // Gri
      case DeviceStatus.error:
        return const Color(0xFFF44336); // Kırmızı
      case DeviceStatus.maintenance:
        return const Color(0xFFFF9800); // Turuncu
    }
  }

  // Sinyal gücü seviyesi
  String get signalLevel {
    if (signalStrength == null) return 'Bilinmiyor';
    if (signalStrength! > 70) return 'Mükemmel';
    if (signalStrength! > 50) return 'İyi';
    if (signalStrength! > 30) return 'Orta';
    return 'Zayıf';
  }
}

// Cihaz kontrolü için komut modeli
class DeviceCommand {
  final String deviceId;
  final String command; // open, close, toggle
  final Map<String, dynamic>? parameters;
  final DateTime timestamp;

  DeviceCommand({
    required this.deviceId,
    required this.command,
    this.parameters,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'command': command,
      'parameters': parameters,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
