// lib/data/models/user_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { globalAdmin, siteAdmin, user }

class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String? phoneNumber;
  final UserRole role;
  final List<String> siteIds; // Kullanıcının erişebildiği siteler
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final String? profilePhotoUrl;
  final Map<String, dynamic>? metadata;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.phoneNumber,
    required this.role,
    required this.siteIds,
    required this.isActive,
    required this.createdAt,
    this.lastLoginAt,
    this.profilePhotoUrl,
    this.metadata,
  });

  // Firestore'dan veri okuma
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      phoneNumber: data['phoneNumber'],
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == data['role'],
        orElse: () => UserRole.user,
      ),
      siteIds: List<String>.from(data['siteIds'] ?? []),
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastLoginAt: data['lastLoginAt'] != null
          ? (data['lastLoginAt'] as Timestamp).toDate()
          : null,
      profilePhotoUrl: data['profilePhotoUrl'],
      metadata: data['metadata'],
    );
  }

  // Firestore'a veri yazma
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'role': role.toString().split('.').last,
      'siteIds': siteIds,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': lastLoginAt != null
          ? Timestamp.fromDate(lastLoginAt!)
          : null,
      'profilePhotoUrl': profilePhotoUrl,
      'metadata': metadata,
    };
  }

  // Kopyalama metodu
  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phoneNumber,
    UserRole? role,
    List<String>? siteIds,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    String? profilePhotoUrl,
    Map<String, dynamic>? metadata,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      siteIds: siteIds ?? this.siteIds,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      metadata: metadata ?? this.metadata,
    );
  }

  // Rol kontrolü için yardımcı metodlar
  bool get isGlobalAdmin => role == UserRole.globalAdmin;
  bool get isSiteAdmin => role == UserRole.siteAdmin;
  bool get isNormalUser => role == UserRole.user;

  // Site erişim kontrolü
  bool hasAccessToSite(String siteId) {
    return isGlobalAdmin || siteIds.contains(siteId);
  }
}
