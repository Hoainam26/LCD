class OfficerEventRequest {
  final String id;
  final String eventId;
  final String eventTitle;
  final String officerId;
  final String officerName;
  final List<String> memberIds;
  final List<String> memberNames;
  final String status;
  final String? note;
  final String? reviewNote;
  final DateTime createdAt;
  final DateTime? reviewedAt;

  OfficerEventRequest({
    required this.id,
    required this.eventId,
    required this.eventTitle,
    required this.officerId,
    required this.officerName,
    required this.memberIds,
    required this.memberNames,
    required this.status,
    this.note,
    this.reviewNote,
    required this.createdAt,
    this.reviewedAt,
  });

  factory OfficerEventRequest.fromApi(Map<String, dynamic> data) {
    return OfficerEventRequest(
      id: data['id']?.toString() ?? '',
      eventId: data['event_id']?.toString() ?? '',
      eventTitle: data['event']?['title'] ?? data['event_title'] ?? 'Sự kiện không xác định',
      officerId: data['officer_id']?.toString() ?? '',
      officerName: data['officer']?['full_name'] ?? data['officer_name'] ?? 'Cán bộ không xác định',
      memberIds: (data['member_ids'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      memberNames: (data['members'] as List<dynamic>?)?.map((e) => e['full_name']?.toString() ?? 'Không xác định').toList() ?? [],
      status: data['status'] ?? 'pending',
      note: data['note'],
      reviewNote: data['review_note'],
      createdAt: DateTime.tryParse(data['created_at'] ?? '') ?? DateTime.now(),
      reviewedAt: data['reviewed_at'] != null ? DateTime.tryParse(data['reviewed_at']) : null,
    );
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
}
