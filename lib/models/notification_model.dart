class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type; // 'event', 'request', 'general'
  final DateTime createdAt;
  final bool isRead;
  final String? relatedId; // ID của event hoặc request liên quan
  final String? recipientId; // ID của member nhận thông báo

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.relatedId,
    this.recipientId,
  });

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      title: title,
      message: message,
      type: type,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      relatedId: relatedId,
      recipientId: recipientId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'message': message,
    'type': type,
    'createdAt': createdAt.toIso8601String(),
    'isRead': isRead,
    'relatedId': relatedId,
    'recipientId': recipientId,
  };

  factory NotificationModel.fromJson(Map<String, dynamic> json) => NotificationModel(
    id: json['id'],
    title: json['title'],
    message: json['message'],
    type: json['type'],
    createdAt: DateTime.parse(json['createdAt']),
    isRead: json['isRead'] ?? false,
    relatedId: json['relatedId'],
    recipientId: json['recipientId'],
  );
}
