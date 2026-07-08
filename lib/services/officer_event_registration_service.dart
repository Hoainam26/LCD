import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';

class OfficerEventRegistrationRequest {
  final String id;
  final String eventId;
  final String eventTitle;
  final String officerId;
  final String officerName;
  final String officerUnit;
  final List<String> memberIds;
  final List<String> memberNames;
  final String? note;
  final String status; // pending | approved | rejected
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? reviewNote;

  const OfficerEventRegistrationRequest({
    required this.id,
    required this.eventId,
    required this.eventTitle,
    required this.officerId,
    required this.officerName,
    required this.officerUnit,
    required this.memberIds,
    required this.memberNames,
    this.note,
    required this.status,
    required this.createdAt,
    this.reviewedAt,
    this.reviewedBy,
    this.reviewNote,
  });

  OfficerEventRegistrationRequest copyWith({
    String? status,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? reviewNote,
  }) {
    return OfficerEventRegistrationRequest(
      id: id,
      eventId: eventId,
      eventTitle: eventTitle,
      officerId: officerId,
      officerName: officerName,
      officerUnit: officerUnit,
      memberIds: List<String>.from(memberIds),
      memberNames: List<String>.from(memberNames),
      note: note,
      status: status ?? this.status,
      createdAt: createdAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewNote: reviewNote ?? this.reviewNote,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'eventTitle': eventTitle,
      'officerId': officerId,
      'officerName': officerName,
      'officerUnit': officerUnit,
      'memberIds': memberIds,
      'memberNames': memberNames,
      'note': note,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'reviewedAt': reviewedAt?.toIso8601String(),
      'reviewedBy': reviewedBy,
      'reviewNote': reviewNote,
    };
  }

  factory OfficerEventRegistrationRequest.fromJson(Map<String, dynamic> json) {
    final event = json['Event'];
    final officer = json['officer'];
    final reviewer = json['reviewer'];

    final eventIdRaw = json['eventId'] ??
        json['event_id'] ??
        (event is Map ? event['id'] : '');
    final eventTitleRaw = json['eventTitle'] ??
        json['event_title'] ??
        (event is Map ? event['title'] : '');
    final officerIdRaw = json['officerId'] ??
        json['officer_id'] ??
        (officer is Map ? officer['id'] : '');
    final officerNameRaw = json['officerName'] ??
        json['officer_name'] ??
        (officer is Map ? officer['full_name'] : '');
    final reviewerIdRaw = json['reviewedBy'] ??
        json['reviewed_by'] ??
        (reviewer is Map ? reviewer['id'] : null);
    final memberIdsRaw = json['memberIds'] ?? json['member_ids'];

    return OfficerEventRegistrationRequest(
      id: (json['id'] ?? '').toString(),
      eventId: (eventIdRaw ?? '').toString(),
      eventTitle: (eventTitleRaw ?? '').toString(),
      officerId: (officerIdRaw ?? '').toString(),
      officerName: (officerNameRaw ?? '').toString(),
      officerUnit: (json['officerUnit'] ??
              json['officer_unit'] ??
              (officer is Map ? officer['unit_name'] : ''))
          .toString(),
      memberIds: (memberIdsRaw as List<dynamic>? ?? const <dynamic>[])
          .map((e) => e.toString())
          .toList(),
      memberNames: (json['memberNames'] as List<dynamic>? ?? const <dynamic>[])
          .map((e) => e.toString())
          .toList(),
      note: json['note']?.toString(),
      status: (json['status'] ?? 'pending').toString(),
      createdAt: DateTime.tryParse(
              (json['createdAt'] ?? json['created_at'] ?? '').toString()) ??
          DateTime.now(),
      reviewedAt: DateTime.tryParse(
          (json['reviewedAt'] ?? json['reviewed_at'] ?? '').toString()),
      reviewedBy: reviewerIdRaw?.toString(),
      reviewNote: (json['reviewNote'] ?? json['review_note'])?.toString(),
    );
  }
}

class OfficerEventRegistrationService {
  static const String _storageKey = 'officer_event_requests_v1';
  static const String _readStateKey = 'officer_event_requests_read_v1';

  static String signatureFor(OfficerEventRegistrationRequest item) {
    return '${item.id}|${item.status}|${item.reviewedAt?.toIso8601String() ?? ''}';
  }

  static Future<List<OfficerEventRegistrationRequest>> getAllRequests() async {
    final remoteItems = await ApiService.getOfficerEventRequests();
    if (remoteItems.isNotEmpty) {
      final mapped = remoteItems
          .whereType<Map<String, dynamic>>()
          .map(OfficerEventRegistrationRequest.fromJson)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      await _saveAll(mapped);
      return mapped;
    }

    return _loadLocal();
  }

  static Future<OfficerEventRegistrationRequest?> getById(String id) async {
    final all = await getAllRequests();
    for (final item in all) {
      if (item.id == id) return item;
    }
    return null;
  }

  static Future<List<OfficerEventRegistrationRequest>>
      getPendingRequests() async {
    final all = await getAllRequests();
    return all.where((item) => item.status == 'pending').toList();
  }

  static Future<List<OfficerEventRegistrationRequest>> getByOfficer(
      String officerId) async {
    final all = await getAllRequests();
    return all.where((item) => item.officerId == officerId).toList();
  }

  static Future<Set<String>> getReadSignatures() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_readStateKey) ?? const <String>[]).toSet();
  }

  static Future<int> getUnreadCount({String? officerId}) async {
    final requests = officerId == null
        ? await getAllRequests()
        : await getByOfficer(officerId);
    final readSignatures = await getReadSignatures();
    return requests
        .where((item) => !readSignatures.contains(signatureFor(item)))
        .length;
  }

  static Future<void> markAsRead(OfficerEventRegistrationRequest request) async {
    final prefs = await SharedPreferences.getInstance();
    final readSignatures = await getReadSignatures();
    readSignatures.add(signatureFor(request));
    await prefs.setStringList(_readStateKey, readSignatures.toList());
  }

  static Future<void> markAllAsReadForOfficer(String officerId) async {
    final requests = await getByOfficer(officerId);
    if (requests.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final readSignatures = await getReadSignatures();
    for (final request in requests) {
      readSignatures.add(signatureFor(request));
    }
    await prefs.setStringList(_readStateKey, readSignatures.toList());
  }

  static Future<OfficerEventRegistrationRequest> submitRequest({
    required String eventId,
    required String eventTitle,
    required String officerId,
    required String officerName,
    required String officerUnit,
    required List<String> memberIds,
    required List<String> memberNames,
    String? note,
    bool invite = false,
  }) async {
    final remote = await ApiService.createOfficerEventRequest(
      eventId: eventId,
      memberIds: memberIds,
      note: note,
      invite: invite,
    );

    if (remote['success'] == true && remote['data'] is Map<String, dynamic>) {
      final request = OfficerEventRegistrationRequest.fromJson(
        remote['data'] as Map<String, dynamic>,
      );
      final all = await getAllRequests();
      final merged = [request, ...all.where((item) => item.id != request.id)];
      await _saveAll(merged);
      return request;
    }

    final request = OfficerEventRegistrationRequest(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      eventId: eventId,
      eventTitle: eventTitle,
      officerId: officerId,
      officerName: officerName,
      officerUnit: officerUnit,
      memberIds: List<String>.from(memberIds),
      memberNames: List<String>.from(memberNames),
      note: note,
      status: invite ? 'invited' : 'pending',
      createdAt: DateTime.now(),
    );

    final all = await getAllRequests();
    all.insert(0, request);
    await _saveAll(all);
    return request;
  }

  static Future<Map<String, dynamic>> updateStatus({
    required String requestId,
    required String status,
    String? reviewedBy,
    String? reviewNote,
  }) async {
    final remote = await ApiService.reviewOfficerEventRequest(
      requestId: requestId,
      status: status,
      reviewNote: reviewNote,
    );

    if (remote['success'] == true) {
      await getAllRequests();
      return remote;
    }

    if (remote['statusCode'] != null) {
      return remote;
    }

    final all = await getAllRequests();
    final idx = all.indexWhere((item) => item.id == requestId);
    if (idx == -1) {
      return {
        'success': false,
        'message': 'Không tìm thấy yêu cầu để cập nhật.',
      };
    }

    all[idx] = all[idx].copyWith(
      status: status,
      reviewedAt: DateTime.now(),
      reviewedBy: reviewedBy,
      reviewNote: reviewNote,
    );
    await _saveAll(all);
    return {
      'success': true,
      'message': 'Đã cập nhật yêu cầu cục bộ.',
    };
  }

  static Future<List<OfficerEventRegistrationRequest>> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey) ?? '[]';
    final decoded = (jsonDecode(raw) as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(OfficerEventRegistrationRequest.fromJson)
        .toList();
    decoded.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return decoded;
  }

  static Future<void> _saveAll(
      List<OfficerEventRegistrationRequest> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(items.map((item) => item.toJson()).toList()),
    );
  }
}
