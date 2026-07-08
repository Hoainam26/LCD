import '../services/api_service.dart';

class UserItem {
  final int id;
  final String fullName;
  final String email;
  final String phone;
  final String? studentCode;
  final String? position;
  final String role;
  final String status;
  final int? unitId;
  final String? unitName;
  final String? avatarUrl;

  UserItem({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    this.studentCode,
    this.position,
    required this.role,
    required this.status,
    this.unitId,
    this.unitName,
    this.avatarUrl,
  });

  factory UserItem.fromApi(
    Map<String, dynamic> json, {
    Map<int, String>? unitMap,
  }) {
    final unitId = json['unit_id'];
    final mappedUnit =
        (unitId is int && unitMap != null) ? unitMap[unitId] : null;
    final rawAvatar = json['avatar_url'] ?? json['avatarUrl'];
    final avatar = rawAvatar is String ? rawAvatar : rawAvatar?.toString();

    final externalProfile = json['external_profile'];
    final position = json['position'] ??
      (externalProfile is Map ? externalProfile['position'] : null);

    return UserItem(
      id: json['id'] ?? 0,
      fullName: json['full_name'] ?? json['fullName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      studentCode: json['student_code'] ??
        json['studentCode'] ??
        json['mssv'] ??
        (json['external_profile'] is Map
          ? json['external_profile']['student_code'] ??
            json['external_profile']['mssv']
          : null),
      position: position?.toString(),
      role: json['role'] ?? 'member',
      status: json['status'] ?? 'active',
      unitId: unitId is int ? unitId : null,
      unitName: mappedUnit,
      avatarUrl: ApiService.resolveAvatarUrl(avatar),
    );
  }

  String get displayRole {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'staff':
        return 'Can bo';
      case 'member':
      default:
        return 'Doan vien';
    }
  }

  String get displayStatus {
    switch (status) {
      case 'inactive':
        return 'Ngung hoat dong';
      case 'pending':
        return 'Cho duyet';
      case 'alumni':
        return 'Cuu doan vien';
      case 'active':
      default:
        return 'Hoat dong';
    }
  }
}
