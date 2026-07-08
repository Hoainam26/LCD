class Event {
  final String id;
  final String? code;
  final String title;
  final String description;
  final DateTime dateTime;
  final DateTime? endDateTime;
  final DateTime? registerStartTime;
  final DateTime? registerEndTime;
  final String location;
  final String createdBy;
  final DateTime createdAt;
  final String status; // 'upcoming', 'ongoing', 'completed'
  final int maxParticipants; // Giới hạn số người tham gia
  final bool isRequired;
  final List<EventRegistration> registrations; // Danh sách đăng ký
  final List<String> approvedMemberIds; // Danh sách member đã được duyệt
  final String? imageUrl; // Hình ảnh sự kiện

  Event({
    required this.id,
    this.code,
    required this.title,
    required this.description,
    required this.dateTime,
    this.endDateTime,
    this.registerStartTime,
    this.registerEndTime,
    required this.location,
    required this.createdBy,
    required this.createdAt,
    this.status = 'upcoming',
    this.maxParticipants = 0,
    this.isRequired = false,
    List<EventRegistration>? registrations,
    List<String>? approvedMemberIds,
    this.imageUrl,
  })  : registrations = registrations ?? [],
        approvedMemberIds = approvedMemberIds ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'title': title,
    'description': description,
    'dateTime': dateTime.toIso8601String(),
    'endDateTime': endDateTime?.toIso8601String(),
    'registerStartTime': registerStartTime?.toIso8601String(),
    'registerEndTime': registerEndTime?.toIso8601String(),
    'location': location,
    'createdBy': createdBy,
    'createdAt': createdAt.toIso8601String(),
    'status': status,
    'maxParticipants': maxParticipants,
    'isRequired': isRequired,
    'registrations': registrations.map((r) => r.toJson()).toList(),
    'approvedMemberIds': approvedMemberIds,
    'imageUrl': imageUrl,
  };

  factory Event.fromJson(Map<String, dynamic> json) => Event(
    id: json['id'],
    code: json['code'],
    title: json['title'],
    description: json['description'],
    dateTime: DateTime.parse(json['dateTime']),
    endDateTime: json['endDateTime'] != null ? DateTime.parse(json['endDateTime']) : null,
    registerStartTime:
      json['registerStartTime'] != null ? DateTime.parse(json['registerStartTime']) : null,
    registerEndTime:
      json['registerEndTime'] != null ? DateTime.parse(json['registerEndTime']) : null,
    location: json['location'],
    createdBy: json['createdBy'],
    createdAt: DateTime.parse(json['createdAt']),
    status: json['status'] ?? 'upcoming',
    maxParticipants: json['maxParticipants'] ?? 0,
    isRequired: json['isRequired'] ?? false,
    registrations: (json['registrations'] as List<dynamic>?)
        ?.map((r) => EventRegistration.fromJson(r))
        .toList(),
    approvedMemberIds: (json['approvedMemberIds'] as List<dynamic>?)
        ?.map((id) => id.toString())
        .toList(),
    imageUrl: json['imageUrl'],
  );

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return ['1', 'true', 'yes', 'y'].contains(normalized);
    }
    return false;
  }

  factory Event.fromApi(Map<String, dynamic> json) {
    final startTime = json['start_time'] ?? json['startTime'] ?? json['start_date'] ?? json['startDate'] ?? json['dateTime'];
    final endTime = json['end_time'] ?? json['endTime'] ?? json['end_date'] ?? json['endDate'] ?? json['endDateTime'];
    final registerStart =
      json['register_start_time'] ?? json['registerStartTime'] ?? json['register_start_date'] ?? json['registerStartDate'];
    final registerEnd = json['register_end_time'] ?? json['registerEndTime'] ?? json['register_end_date'] ?? json['registerEndDate'];
    final createdAt = json['created_at'] ?? json['createdAt'];
    final rawMax = json['max_participants'] ??
        json['maxParticipants'] ??
        json['participant_limit'] ??
        json['participantLimit'];
    final maxParticipants = rawMax == null ? 0 : int.tryParse('$rawMax') ?? 0;
    final isRequired = _parseBool(
      json['is_required'] ?? json['isRequired'] ?? json['required'],
    );

    return Event(
      id: (json['id'] ?? json['activityId'] ?? json['activity_id'] ?? json['code'])
          .toString(),
      code: json['code']?.toString(),
      title: json['title'] ?? json['name'] ?? json['activityName'] ?? '',
      description: json['description'] ?? '',
      dateTime: startTime != null
          ? DateTime.parse(startTime)
          : DateTime.now(),
      endDateTime: endTime != null ? DateTime.parse(endTime) : null,
      registerStartTime:
        registerStart != null ? DateTime.parse(registerStart) : null,
      registerEndTime:
        registerEnd != null ? DateTime.parse(registerEnd) : null,
      location: json['location'] ?? json['place'] ?? '',
      createdBy: json['created_by']?.toString() ?? json['createdBy']?.toString() ?? '',
      createdAt: createdAt != null ? DateTime.parse(createdAt) : DateTime.now(),
      status: json['status']?.toString() ?? 'upcoming',
      maxParticipants: maxParticipants,
      isRequired: isRequired,
      registrations: const [],
      approvedMemberIds: const [],
      imageUrl: json['cover_image_url'] ?? json['imageUrl'],
    );
  }
  
  String get dateTimeString {
    final startDate = _formatDate(dateTime);
    final startTime = _formatTime(dateTime);

    if (endDateTime == null) {
      return '$startDate, $startTime';
    }

    final sameDay = dateTime.year == endDateTime!.year &&
        dateTime.month == endDateTime!.month &&
        dateTime.day == endDateTime!.day;
    final endDate = sameDay ? '' : '${_formatDate(endDateTime!)} ';
    final endTime = _formatTime(endDateTime!);

    return '$startDate, $startTime - $endDate$endTime';
  }
  
  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  
  // Helper methods
  int get registeredCount => registrations.length;
  int get approvedCount => approvedMemberIds.length;
  bool get hasParticipantLimit => maxParticipants > 0;
  bool get isFull => hasParticipantLimit && approvedCount >= maxParticipants;
  int get availableSlots => hasParticipantLimit ? maxParticipants - approvedCount : 0;
  bool get isClosed => status == 'closed' || status == 'canceled';

  bool get hasEnded {
    if (endDateTime == null) return false;
    return DateTime.now().isAfter(endDateTime!);
  }

  bool get isOngoing {
    final now = DateTime.now();
    if (now.isBefore(dateTime)) return false;
    if (endDateTime == null) return true;
    return now.isBefore(endDateTime!) || now.isAtSameMomentAs(endDateTime!);
  }

  bool get isUpcoming => DateTime.now().isBefore(dateTime);

  bool get isActive {
    if (isClosed) return false;
    final now = DateTime.now();
    if (endDateTime != null) {
      return now.isBefore(endDateTime!) || now.isAtSameMomentAs(endDateTime!);
    }
    return now.isBefore(dateTime) || now.isAtSameMomentAs(dateTime);
  }

  bool get isRegistrationOpen {
    final now = DateTime.now();
    if (isClosed || hasEnded) return false;
    if (registerStartTime != null && now.isBefore(registerStartTime!)) {
      return false;
    }
    if (registerEndTime != null && now.isAfter(registerEndTime!)) {
      return false;
    }
    if (registerEndTime == null && now.isAfter(dateTime)) {
      return false;
    }
    return true;
  }

  /// Check-in có thể khi:
  /// - Hết thời gian đăng ký (registerEndTime <= now)
  /// - Hoạt động đang diễn ra hoặc bắt đầu
  /// - Hoạt động chưa kết thúc/đóng
  bool get canCheckIn {
    if (isClosed || hasEnded) return false;
    
    final now = DateTime.now();
    // Phải hết thời gian đăng ký (registration closed)
    if (registerEndTime != null && now.isBefore(registerEndTime!)) {
      return true; // Vẫn trong registration period - nhưng nếu là thời gian hoạt động
    }
    
    // Hoạt động phải đã bắt đầu hoặc đang diễn ra
    if (now.isBefore(dateTime)) {
      return false; // Hoạt động chưa bắt đầu
    }
    
    return true; // Hoạt động đang diễn ra hoặc hết hạn đăng ký
  }

  /// Check xem thời gian check-in đã đến chưa (sau khi hết thời gian đăng ký)
  bool get isCheckInTimeActive {
    final now = DateTime.now();
    
    // Nếu registerEndTime được set, check-in bắt đầu sau thời điểm đó
    if (registerEndTime != null) {
      return now.isAfter(registerEndTime!) || now.isAtSameMomentAs(registerEndTime!);
    }
    
    // Nếu không có registerEndTime, check-in bắt đầu khi hoạt động bắt đầu
    return now.isAfter(dateTime) || now.isAtSameMomentAs(dateTime);
  }
}

// Đăng ký tham gia sự kiện
class EventRegistration {
  final String memberId;
  final String memberName;
  final String memberClass;
  final DateTime registeredAt;
  final String status; // 'pending', 'approved', 'rejected'
  final String? note;

  EventRegistration({
    required this.memberId,
    required this.memberName,
    required this.memberClass,
    required this.registeredAt,
    this.status = 'pending',
    this.note,
  });

  Map<String, dynamic> toJson() => {
    'memberId': memberId,
    'memberName': memberName,
    'memberClass': memberClass,
    'registeredAt': registeredAt.toIso8601String(),
    'status': status,
    'note': note,
  };

  factory EventRegistration.fromJson(Map<String, dynamic> json) => EventRegistration(
    memberId: json['memberId'],
    memberName: json['memberName'],
    memberClass: json['memberClass'],
    registeredAt: DateTime.parse(json['registeredAt']),
    status: json['status'] ?? 'pending',
    note: json['note'],
  );
}
