import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';

class CollectiveTrainingEvaluation {
  final String id;
  final int periodId;
  final String scopeKey; // e.g. class/faculty key
  final String scopeLabel;
  final String evaluatorId;
  final String evaluatorRole;
  final double score;
  final String? note;
  final DateTime createdAt;

  const CollectiveTrainingEvaluation({
    required this.id,
    required this.periodId,
    required this.scopeKey,
    required this.scopeLabel,
    required this.evaluatorId,
    required this.evaluatorRole,
    required this.score,
    this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'periodId': periodId,
      'scopeKey': scopeKey,
      'scopeLabel': scopeLabel,
      'evaluatorId': evaluatorId,
      'evaluatorRole': evaluatorRole,
      'score': score,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CollectiveTrainingEvaluation.fromJson(Map<String, dynamic> json) {
    final evaluator = json['evaluator'];

    return CollectiveTrainingEvaluation(
      id: (json['id'] ?? '').toString(),
      periodId:
          int.tryParse((json['periodId'] ?? json['period_id'] ?? '').toString()) ??
              0,
      scopeKey: (json['scopeKey'] ?? json['scope_key'] ?? '').toString(),
      scopeLabel: (json['scopeLabel'] ?? json['scope_label'] ?? '').toString(),
      evaluatorId: (json['evaluatorId'] ??
              json['evaluator_id'] ??
              (evaluator is Map ? evaluator['id'] : ''))
          .toString(),
      evaluatorRole: (json['evaluatorRole'] ?? json['evaluator_role'] ?? '')
          .toString(),
      score: double.tryParse((json['score'] ?? '').toString()) ?? 0,
      note: json['note']?.toString(),
      createdAt: DateTime.tryParse(
              (json['createdAt'] ?? json['created_at'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}

class CollectiveTrainingEvaluationService {
  static const String _storageKey = 'collective_training_eval_v1';

  static Future<List<CollectiveTrainingEvaluation>> getAll() async {
    final remote = await ApiService.getCollectiveTrainingEvaluations();
    if (remote.isNotEmpty) {
      final mapped = remote
          .whereType<Map<String, dynamic>>()
          .map(CollectiveTrainingEvaluation.fromJson)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      await _saveLocal(mapped);
      return mapped;
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey) ?? '[]';
    final list = (jsonDecode(raw) as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(CollectiveTrainingEvaluation.fromJson)
        .toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  static Future<void> upsert(CollectiveTrainingEvaluation evaluation) async {
    final scopeType = evaluation.scopeKey.startsWith('class:')
        ? 'class'
        : evaluation.scopeKey.startsWith('faculty:')
            ? 'faculty'
            : 'class';
    final scopeKey = evaluation.scopeKey.contains(':')
        ? evaluation.scopeKey.split(':').sublist(1).join(':')
        : evaluation.scopeKey;

    final remote = await ApiService.upsertCollectiveTrainingEvaluation(
      periodId: evaluation.periodId,
      scopeType: scopeType,
      scopeKey: scopeKey,
      scopeLabel: evaluation.scopeLabel,
      score: evaluation.score,
      note: evaluation.note,
    );

    if (remote['success'] == true) {
      await getAll();
      return;
    }

    final all = await getAll();
    final idx = all.indexWhere((item) =>
        item.periodId == evaluation.periodId && item.scopeKey == evaluation.scopeKey);

    if (idx == -1) {
      all.insert(0, evaluation);
    } else {
      all[idx] = evaluation;
    }

    await _saveLocal(all);
  }

  static Future<void> _saveLocal(
    List<CollectiveTrainingEvaluation> items,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(items.map((item) => item.toJson()).toList()),
    );
  }
}
