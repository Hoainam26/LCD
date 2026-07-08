class TrainingPeriod {
  final int id;
  final String name;
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? description;

  TrainingPeriod({
    required this.id,
    required this.name,
    required this.status,
    this.startDate,
    this.endDate,
    this.description,
  });

  factory TrainingPeriod.fromApi(Map<String, dynamic> json) {
    final start = json['start_date'] ?? json['startDate'];
    final end = json['end_date'] ?? json['endDate'];
    return TrainingPeriod(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      status: json['status'] ?? 'open',
      startDate: start != null ? DateTime.tryParse(start.toString()) : null,
      endDate: end != null ? DateTime.tryParse(end.toString()) : null,
      description: json['description'],
    );
  }

  String get displayStatus {
    switch (status) {
      case 'closed':
        return 'Đã khóa';
      case 'archived':
        return 'Lưu trữ';
      case 'open':
      default:
        return 'Đang mở';
    }
  }
}
