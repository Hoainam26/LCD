import 'training_period.dart';
import 'training_score_item.dart';

class TrainingScore {
  final int id;
  final int userId;
  final int periodId;
  final int totalScore;
  final String status;
  final String? note;
  final TrainingPeriod? period;
  final List<TrainingScoreItem> items;

  TrainingScore({
    required this.id,
    required this.userId,
    required this.periodId,
    required this.totalScore,
    required this.status,
    this.note,
    this.period,
    List<TrainingScoreItem>? items,
  }) : items = items ?? [];

  factory TrainingScore.fromApi(Map<String, dynamic> json) {
    final periodJson = json['TrainingPeriod'] ?? json['period'];
    final itemsJson = json['TrainingScoreItems'] ?? json['items'];
    return TrainingScore(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? json['userId'] ?? 0,
      periodId: json['period_id'] ?? json['periodId'] ?? 0,
      totalScore: json['total_score'] ?? json['totalScore'] ?? 0,
      status: json['status'] ?? 'draft',
      note: json['note'],
      period: periodJson is Map<String, dynamic>
          ? TrainingPeriod.fromApi(periodJson)
          : null,
      items: itemsJson is List
          ? itemsJson
              .map((item) => TrainingScoreItem.fromApi(item))
              .toList()
          : [],
    );
  }

  String get displayStatus {
    switch (status) {
      case 'submitted':
        return 'Chờ duyệt';
      case 'approved':
        return 'Đã duyệt';
      case 'rejected':
        return 'Bị từ chối';
      case 'draft':
      default:
        return 'Nháp';
    }
  }
}
