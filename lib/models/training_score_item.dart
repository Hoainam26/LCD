import 'training_criterion.dart';

class TrainingScoreItem {
  final int id;
  final int criterionId;
  final int score;
  final int? officerScore;
  final String? note;
  final String? officerNote;
  final TrainingCriterion? criterion;

  TrainingScoreItem({
    required this.id,
    required this.criterionId,
    required this.score,
    this.officerScore,
    this.note,
    this.officerNote,
    this.criterion,
  });

  factory TrainingScoreItem.fromApi(Map<String, dynamic> json) {
    final criterionJson = json['TrainingCriterion'] ?? json['criterion'];
    return TrainingScoreItem(
      id: json['id'] ?? 0,
      criterionId: json['criterion_id'] ?? json['criterionId'] ?? 0,
      score: json['score'] ?? 0,
      officerScore: json['officer_score'] ?? json['officerScore'],
      note: json['note'],
      officerNote: json['officer_note'] ?? json['officerNote'],
      criterion: criterionJson is Map<String, dynamic>
          ? TrainingCriterion.fromApi(criterionJson)
          : null,
    );
  }
}
