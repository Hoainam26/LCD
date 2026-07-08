import 'package:flutter/material.dart';

enum OfficerRole {
  // Ban Chấp Hành Liên Chi Đoàn Khoa
  secretary, // Bí thư Liên Chi Đoàn
  viceSecretary, // Phó Bí thư Liên Chi Đoàn
  executiveMember, // Ủy viên Ban Chấp Hành
  
  // Chi Đoàn Lớp
  classSecretary, // Chi đoàn trưởng lớp
  classViceSecretary, // Phó chi đoàn trưởng lớp
  
  // Đoàn viên
  unionMember, // Đoàn viên
}

extension OfficerRoleExtension on OfficerRole {
  String get displayName {
    switch (this) {
      case OfficerRole.secretary:
        return 'Bí thư Liên Chi Đoàn';
      case OfficerRole.viceSecretary:
        return 'Phó Bí thư Liên Chi Đoàn';
      case OfficerRole.executiveMember:
        return 'Ủy viên BCH';
      case OfficerRole.classSecretary:
        return 'Chi đoàn trưởng';
      case OfficerRole.classViceSecretary:
        return 'Phó chi đoàn trưởng';
      case OfficerRole.unionMember:
        return 'Đoàn viên';
    }
  }

  String get badge {
    switch (this) {
      case OfficerRole.secretary:
        return '🏆';
      case OfficerRole.viceSecretary:
        return '⭐';
      case OfficerRole.executiveMember:
        return '🎖️';
      case OfficerRole.classSecretary:
        return '👨‍💼';
      case OfficerRole.classViceSecretary:
        return '👔';
      case OfficerRole.unionMember:
        return '👥';
    }
  }

  Color get color {
    switch (this) {
      case OfficerRole.secretary:
        return const Color(0xFFD4AF37); // Gold
      case OfficerRole.viceSecretary:
        return const Color(0xFFC0C0C0); // Silver
      case OfficerRole.executiveMember:
        return const Color(0xFFCD7F32); // Bronze
      case OfficerRole.classSecretary:
        return const Color(0xFF4A90E2); // Blue
      case OfficerRole.classViceSecretary:
        return const Color(0xFF7B68EE); // Medium Slate Blue
      case OfficerRole.unionMember:
        return const Color(0xFF9E9E9E); // Light Gray
    }
  }

  // Danh sách quyền truy cập theo cấp bậc
  List<String> get permissions {
    switch (this) {
      case OfficerRole.secretary:
        return [
          'event_full', // Sự kiện: Toàn khoa
          'approval_full', // Phê duyệt: Toàn bộ
          'report_full', // Báo cáo: Toàn khoa
          'member_full', // Đoàn viên: Toàn khoa
          'class_full', // Chi đoàn lớp: Toàn bộ
          'document_full', // Tài liệu: Toàn bộ
          'attendance_view', // Điểm danh: Xem
          'statistics_full', // Thống kê: Toàn khoa
          'settings_full', // Cài đặt hệ thống
        ];
      case OfficerRole.viceSecretary:
        return [
          'event_full', // Sự kiện: Toàn khoa
          'approval_full', // Phê duyệt: Toàn bộ
          'report_full', // Báo cáo: Toàn khoa
          'member_view', // Đoàn viên: Xem
          'class_view', // Chi đoàn lớp: Xem
          'document_full', // Tài liệu: Toàn bộ
          'attendance_view', // Điểm danh: Xem
          'statistics_full', // Thống kê: Toàn khoa
          'settings_limited', // Cài đặt giới hạn
        ];
      case OfficerRole.executiveMember:
        return [
          'event_view', // Sự kiện: Xem
          'approval_view', // Phê duyệt: Xem
          'report_view', // Báo cáo: Xem
          'member_view', // Đoàn viên: Xem
          'class_view', // Chi đoàn lớp: Xem
          'document_view', // Tài liệu: Xem
          'attendance_view', // Điểm danh: Xem
          'statistics_view', // Thống kê: Xem
        ];
      case OfficerRole.classSecretary:
        return [
          'event_class', // Sự kiện: Quản lý lớp
          'approval_class', // Phê duyệt: Trong lớp
          'report_class', // Báo cáo: Lớp
          'member_class', // Đoàn viên: Quản lý lớp
          'document_class', // Tài liệu: Lớp
          'attendance_class', // Điểm danh: Quản lý lớp
          'statistics_class', // Thống kê: Lớp
        ];
      case OfficerRole.classViceSecretary:
        return [
          'event_class_view', // Sự kiện: Xem lớp
          'member_class_view', // Đoàn viên: Xem lớp
          'report_class_view', // Báo cáo: Xem lớp
          'document_class', // Tài liệu: Lớp
          'attendance_class', // Điểm danh: Quản lý lớp
          'statistics_class_view', // Thống kê: Xem lớp
        ];
      case OfficerRole.unionMember:
        return [
          'event_view_own', // Sự kiện: Xem của mình
          'profile_view', // Đoàn viên: Hồ sơ cá nhân
          'profile_edit', // Chỉnh sửa thông tin cá nhân
          'document_view_public', // Tài liệu: Công khai
          'attendance_checkin', // Điểm danh: Check-in
          'notification_view', // Xem thông báo
        ];
    }
  }

  bool hasPermission(String permission) {
    return permissions.contains(permission);
  }
  
  // Kiểm tra cấp độ quản lý
  bool get isFacultyLevel {
    return this == OfficerRole.secretary ||
           this == OfficerRole.viceSecretary ||
           this == OfficerRole.executiveMember;
  }
  
  bool get isClassLevel {
    return this == OfficerRole.classSecretary ||
           this == OfficerRole.classViceSecretary;
  }
  
  bool get isLeader {
    return this == OfficerRole.secretary ||
           this == OfficerRole.viceSecretary ||
           this == OfficerRole.classSecretary ||
           this == OfficerRole.classViceSecretary;
  }
}
