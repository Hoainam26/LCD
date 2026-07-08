class TrainingCriterion {
  final int id;
  final String code;
  final String name;
  final String? groupName;
  final int maxScore;
  final int sortOrder;

  TrainingCriterion({
    required this.id,
    required this.code,
    required this.name,
    this.groupName,
    required this.maxScore,
    required this.sortOrder,
  });

  factory TrainingCriterion.fromApi(Map<String, dynamic> json) {
    return TrainingCriterion(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      groupName: json['group_name'] ?? json['groupName'],
      maxScore: json['max_score'] ?? json['maxScore'] ?? 0,
      sortOrder: json['sort_order'] ?? json['sortOrder'] ?? 0,
    );
  }
}
