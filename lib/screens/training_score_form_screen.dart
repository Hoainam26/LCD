import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../constants/colors.dart';
import '../models/training_criterion.dart';
import '../models/training_period.dart';
import '../models/training_score.dart';
import '../models/user_item.dart';
import '../services/api_service.dart';
import '../services/app_state_service.dart';

const Color _ink = AppColors.textPrimary;
const Color _muted = AppColors.textSecondary;
const Color _primary = AppColors.secondary;
const Color _primaryDark = AppColors.primaryDark;
const Color _accent = AppColors.accent;
const Color _bg = AppColors.backgroundColor;

class TrainingScoreFormScreen extends StatefulWidget {
  final UserItem member;
  final TrainingPeriod period;
  final List<TrainingCriterion> criteria;
  final TrainingScore? existingScore;
  final String? initialStatus;

  const TrainingScoreFormScreen({
    super.key,
    required this.member,
    required this.period,
    required this.criteria,
    this.existingScore,
    this.initialStatus,
  });

  @override
  State<TrainingScoreFormScreen> createState() =>
      _TrainingScoreFormScreenState();
}

class _TrainingScoreFormScreenState extends State<TrainingScoreFormScreen> {
  final Map<int, TextEditingController> _controllers = {};
  final Map<int, int?> _officerScores = {};
  bool _isSubmitting = false;
  String _status = 'draft';
  String? _scoreId;
  String _actorRole = 'member';
  bool _isLocked = false;

  @override
  void initState() {
    super.initState();

    for (final criterion in widget.criteria) {
      _controllers[criterion.id] = TextEditingController(text: '0');
      _officerScores[criterion.id] = null;
    }

    _status = widget.initialStatus ?? 'draft';

    if (widget.existingScore != null) {
      _applyExisting(widget.existingScore!);
    } else {
      _loadExistingScore();
    }

    Future.microtask(_refreshRoleState);
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _applyExisting(TrainingScore score) {
    _status = widget.initialStatus ?? score.status;
    _scoreId = score.id.toString();
    _prefillScores(score);
    _refreshLockedState();
  }

  Future<void> _loadExistingScore() async {
    final items = await ApiService.getTrainingScores(
      periodId: widget.period.id,
      userId: widget.member.id,
    );
    if (!mounted || items.isEmpty) return;

    final score = TrainingScore.fromApi(items.first);
    setState(() {
      _status = widget.initialStatus ?? score.status;
      _scoreId = score.id.toString();
    });
    _prefillScores(score);
    _refreshLockedState();
  }

  void _refreshRoleState() {
    if (!mounted) return;

    final appState = Provider.of<AppStateService>(context, listen: false);
    final role = appState.currentUser?['role']?.toString().toLowerCase() ?? 'member';

    setState(() {
      _actorRole = role;
      if (_actorRole == 'staff' && _scoreId == null && _status == 'draft') {
        _status = 'submitted';
      }
      if (_actorRole == 'admin' && widget.initialStatus != null) {
        _status = widget.initialStatus!;
      }
    });

    _refreshLockedState();
  }

  void _refreshLockedState() {
    final locked = _actorRole == 'staff' &&
        _scoreId != null &&
        !_staffEditableStatuses.contains(_status);

    if (!mounted) return;

    if (locked != _isLocked) {
      setState(() {
        _isLocked = locked;
      });
    }
  }

  void _prefillScores(TrainingScore? score) {
    if (score == null) return;
    final adminMap = {
      for (final item in score.items) item.criterionId: item.score,
    };
    final officerMap = {
      for (final item in score.items)
        item.criterionId: item.officerScore,
    };

    for (final criterion in widget.criteria) {
      final adminValue = adminMap[criterion.id];
      if (adminValue != null) {
        _controllers[criterion.id]?.text = adminValue.toString();
      }
      final officerValue = officerMap[criterion.id];
      if (officerValue != null) {
        _officerScores[criterion.id] = officerValue;
      }
    }
  }

  int _calculateTotal() {
    int total = 0;
    for (final criterion in widget.criteria) {
      final text = _controllers[criterion.id]?.text ?? '0';
      final value = int.tryParse(text) ?? 0;
      final normalized = value < 0
          ? 0
          : value > criterion.maxScore
              ? criterion.maxScore
              : value;
      total += normalized;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);
    final textTheme = GoogleFonts.manropeTextTheme(baseTheme.textTheme);
    final total = _calculateTotal();
    final maxTotal = widget.criteria.fold<int>(
      0,
      (sum, criterion) => sum + criterion.maxScore,
    );
    final progress = maxTotal == 0 ? 0.0 : total / maxTotal;

    return Theme(
      data: baseTheme.copyWith(textTheme: textTheme),
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          title: Text(
            'Chấm điểm rèn luyện',
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          foregroundColor: _ink,
          elevation: 0,
          backgroundColor: Colors.white,
        ),
        body: Stack(
          children: [
            _buildBackground(),
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              children: [
                _buildHero(total, maxTotal, progress),
                const SizedBox(height: 14),
                _buildSectionHeader(
                  'Chi tiết theo tiêu chí',
                  'Chạm để nhập điểm theo từng tiêu chí',
                ),
                const SizedBox(height: 10),
                ...List.generate(
                  widget.criteria.length,
                  (index) => _buildCriterionInput(
                    widget.criteria[index],
                    index,
                  ),
                ),
                const SizedBox(height: 12),
                _buildStatusSection(),
                const SizedBox(height: 14),
                _buildSaveButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF8F9FF), Color(0xFFF4F6FB)],
          ),
        ),
      ),
    );
  }

  Widget _buildGlowCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.4),
      ),
    );
  }

  Widget _buildHero(int total, int maxTotal, double progress) {
    final unitName = widget.member.unitName?.trim().isNotEmpty == true
        ? widget.member.unitName!.trim()
        : 'Chưa phân công';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF3152B7), Color(0xFF213F9E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withOpacity(0.24),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white.withOpacity(0.18),
                child: Text(
                  widget.member.fullName.isNotEmpty
                      ? widget.member.fullName.substring(0, 1).toUpperCase()
                      : '?',
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.member.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$unitName • ${widget.period.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.82),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Tổng',
                      style: GoogleFonts.manrope(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      '$total',
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E3A8A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tiến độ hoàn thành',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: Colors.white.withOpacity(0.16),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFFFBBF24),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$total/$maxTotal',
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mục tiêu: $maxTotal điểm',
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.78),
                ),
              ),
              Text(
                widget.period.name,
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withOpacity(0.92),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.playfairDisplay(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.manrope(fontSize: 12, color: _muted),
        ),
      ],
    );
  }

  Widget _buildCriterionInput(TrainingCriterion criterion, int index) {
    final officerScore = _officerScores[criterion.id];

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + (index * 40)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${criterion.code}. ${criterion.name}',
              style: GoogleFonts.manrope(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: _ink,
              ),
            ),
            if (criterion.groupName != null) ...[
              const SizedBox(height: 6),
              Text(
                criterion.groupName!,
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              'Nhập điểm',
              style: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (officerScore != null) ...[
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F8FF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cán bộ chấm',
                            style: GoogleFonts.manrope(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$officerScore/${criterion.maxScore}',
                            style: GoogleFonts.manrope(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1E3A8A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F6FB),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextField(
                      controller: _controllers[criterion.id],
                      enabled: !_isLocked,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _primaryDark,
                      ),
                      decoration: InputDecoration(
                        hintText: '0',
                        border: InputBorder.none,
                        isDense: true,
                        suffixText: '/${criterion.maxScore}',
                        suffixStyle: GoogleFonts.manrope(
                          fontSize: 10,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection() {
    final options = _visibleStatusOptions();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trạng thái hồ sơ',
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          const SizedBox(height: 10),
          if (_actorRole == 'staff') ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBAE6FD)),
              ),
              child: Text(
                _isLocked
                    ? 'Hồ sơ này đã được admin duyệt, cán bộ chỉ xem được.'
                    : 'Cán bộ chỉ chấm sơ bộ và nộp hồ sơ ở trạng thái chờ duyệt.',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0369A1),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (_isLocked)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                'Trạng thái hiện tại: ${_statusLabel(_status)}',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF334155),
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: options.map((option) {
                final selected = _status == option.value;
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(option.icon, size: 14, color: option.color),
                      const SizedBox(width: 6),
                      Text(option.label),
                    ],
                  ),
                  selected: selected,
                  selectedColor: option.color.withOpacity(0.15),
                  backgroundColor: const Color(0xFFF1F5F9),
                  labelStyle: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? option.color : _muted,
                  ),
                  onSelected: (_) {
                    setState(() {
                      _status = option.value;
                    });
                    _refreshLockedState();
                  },
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: (_isSubmitting || _isLocked) ? null : _submit,
          icon: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.save),
          label: Text(
            _isLocked
                ? 'Đã khóa'
                : (_isSubmitting
                    ? 'Đang lưu...'
                    : (_actorRole == 'admin' ? 'Lưu & duyệt' : 'Lưu điểm')),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (_isLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hồ sơ đã được admin duyệt, không thể chỉnh sửa.'),
        ),
      );
      return;
    }
    if (!_canSubmitForUser(widget.member)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chỉ có thể chấm điểm cho đoàn viên và cán bộ đoàn.'),
        ),
      );
      return;
    }
    setState(() => _isSubmitting = true);

    final items = <Map<String, dynamic>>[];
    for (final criterion in widget.criteria) {
      final text = _controllers[criterion.id]?.text ?? '0';
      final value = int.tryParse(text) ?? 0;
      if (value > criterion.maxScore) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('${criterion.name} vượt quá ${criterion.maxScore} điểm.'),
            backgroundColor: _accent,
          ),
        );
        return;
      }
      if (value < 0) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${criterion.name} không được nhỏ hơn 0.'),
            backgroundColor: _accent,
          ),
        );
        return;
      }

      final item = {
        'criterion_id': criterion.id,
        'score': value,
      };

      // Include officer score if available
      final officerScore = _officerScores[criterion.id];
      if (officerScore != null) {
        item['officer_score'] = officerScore;
      }

      items.add(item);
    }

    final result = _scoreId == null
        ? await ApiService.createTrainingScore(
            userId: widget.member.id,
            periodId: widget.period.id,
            items: items,
            status: _status,
          )
        : await ApiService.updateTrainingScore(
            scoreId: _scoreId!,
            userId: widget.member.id,
            periodId: widget.period.id,
            items: items,
            status: _status,
          );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result['success'] == false) {
      final message = result['message']?.toString() ??
          'Lưu điểm thất bại. Vui lòng thử lại.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: _accent),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã lưu điểm rèn luyện')),
    );
    Navigator.pop(context, true);
  }

  bool _canSubmitForUser(UserItem user) {
    final role = user.role.toLowerCase();
    return role == 'member' || role == 'staff';
  }

  List<_StatusOption> _visibleStatusOptions() {
    if (_actorRole == 'staff') {
      return _statusOptions
          .where((option) => _staffEditableStatuses.contains(option.value))
          .toList();
    }
    return _statusOptions;
  }

  String _statusLabel(String value) {
    for (final option in _statusOptions) {
      if (option.value == value) return option.label;
    }
    return value;
  }
}

class _StatusOption {
  final String value;
  final String label;
  final Color color;
  final IconData icon;

  const _StatusOption({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });
}

const List<_StatusOption> _statusOptions = [
  _StatusOption(
    value: 'draft',
    label: 'Nháp',
    color: Color(0xFFEA580C),
    icon: Icons.edit_note,
  ),
  _StatusOption(
    value: 'submitted',
    label: 'Đã nộp',
    color: Color(0xFF2563EB),
    icon: Icons.upload_file,
  ),
  _StatusOption(
    value: 'approved',
    label: 'Đã duyệt',
    color: Color(0xFF16A34A),
    icon: Icons.verified,
  ),
  _StatusOption(
    value: 'rejected',
    label: 'Từ chối',
    color: Color(0xFFDC2626),
    icon: Icons.cancel,
  ),
];

const Set<String> _staffEditableStatuses = {'draft', 'submitted'};
