// lib/data/models/site_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

enum SiteType { residential, business, mixed, factory }

class SiteModel {
  final String id;
  final String name;
  final String address;
  final SiteType type;
  final String adminId; // Site yöneticisi user ID
  final List<String> deviceIds;
  final List<String> userIds;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastModifiedAt;
  final Map<String, dynamic>? settings;
  final Map<String, dynamic>? metadata;

  // İstatistikler
  final int? totalUsers;
  final int? totalDevices;
  final int? todayAccessCount;

  SiteModel({
    required this.id,
    required this.name,
    required this.address,
    required this.type,
    required this.adminId,
    required this.deviceIds,
    required this.userIds,
    required this.isActive,
    required this.createdAt,
    this.lastModifiedAt,
    this.settings,
    this.metadata,
    this.totalUsers,
    this.totalDevices,
    this.todayAccessCount,
  });

  factory SiteModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SiteModel(
      id: doc.id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      type: SiteType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => SiteType.residential,
      ),
      adminId: data['adminId'] ?? '',
      deviceIds: List<String>.from(data['deviceIds'] ?? []),
      userIds: List<String>.from(data['userIds'] ?? []),
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastModifiedAt: data['lastModifiedAt'] != null
          ? (data['lastModifiedAt'] as Timestamp).toDate()
          : null,
      settings: data['settings'],
      metadata: data['metadata'],
      totalUsers: data['totalUsers'],
      totalDevices: data['totalDevices'],
      todayAccessCount: data['todayAccessCount'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'address': address,
      'type': type.toString().split('.').last,
      'adminId': adminId,
      'deviceIds': deviceIds,
      'userIds': userIds,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastModifiedAt': lastModifiedAt != null
          ? Timestamp.fromDate(lastModifiedAt!)
          : FieldValue.serverTimestamp(),
      'settings': settings,
      'metadata': metadata,
      'totalUsers': totalUsers ?? userIds.length,
      'totalDevices': totalDevices ?? deviceIds.length,
      'todayAccessCount': todayAccessCount ?? 0,
    };
  }

  SiteModel copyWith({
    String? id,
    String? name,
    String? address,
    SiteType? type,
    String? adminId,
    List<String>? deviceIds,
    List<String>? userIds,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastModifiedAt,
    Map<String, dynamic>? settings,
    Map<String, dynamic>? metadata,
    int? totalUsers,
    int? totalDevices,
    int? todayAccessCount,
  }) {
    return SiteModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      type: type ?? this.type,
      adminId: adminId ?? this.adminId,
      deviceIds: deviceIds ?? this.deviceIds,
      userIds: userIds ?? this.userIds,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
      settings: settings ?? this.settings,
      metadata: metadata ?? this.metadata,
      totalUsers: totalUsers ?? this.totalUsers,
      totalDevices: totalDevices ?? this.totalDevices,
      todayAccessCount: todayAccessCount ?? this.todayAccessCount,
    );
  }

  // Site tipi için Türkçe isim
  String get typeDisplayName {
    switch (type) {
      case SiteType.residential:
        return 'Konut Sitesi';
      case SiteType.business:
        return 'İş Merkezi';
      case SiteType.mixed:
        return 'Karma (Konut + İş)';
      case SiteType.factory:
        return 'Fabrika/Sanayi';
    }
  }
}
