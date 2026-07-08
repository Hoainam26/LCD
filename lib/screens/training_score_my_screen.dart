import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../constants/colors.dart';
import '../models/training_score.dart';
import '../models/training_period.dart';
import '../models/user_item.dart';
import '../services/app_state_service.dart';
import 'training_score_form_screen.dart';

const Color _ink = AppColors.textPrimary;
const Color _muted = AppColors.textSecondary;
const Color _primary = AppColors.secondary;
const Color _primaryDark = AppColors.primaryDark;
const Color _accent = AppColors.warning;
const Color _bg = AppColors.backgroundColor;

class TrainingScoreMyScreen extends StatefulWidget {
  const TrainingScoreMyScreen({super.key});

  @override
  State<TrainingScoreMyScreen> createState() => _TrainingScoreMyScreenState();
}

class _TrainingScoreMyScreenState extends State<TrainingScoreMyScreen> {
  static const String _allPeriodsLabel = 'Tất cả';
  String _selectedPeriodFilter = _allPeriodsLabel;
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final appState = Provider.of<AppStateService>(context, listen: false);
      appState.refreshTrainingPeriods();
      appState.refreshMyTrainingScores();
      appState.refreshTrainingCriteria();
    });
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);
    final textTheme = GoogleFonts.manropeTextTheme(baseTheme.textTheme);

    return Theme(
      data: baseTheme.copyWith(textTheme: textTheme),
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          title: Text(
            'Điểm rèn luyện',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          foregroundColor: Colors.white,
          elevation: 0,
          backgroundColor: Colors.transparent,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF274BBA), Color(0xFF1E3FA0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        body: Stack(
          children: [
            _buildBackground(),
            Consumer<AppStateService>(
              builder: (context, appState, _) {
                final scores = appState.myTrainingScores;
                final latest = scores.isNotEmpty ? scores.first : null;

                final filteredScores = _selectedPeriodFilter == _allPeriodsLabel
                    ? scores
                    : scores.where((s) => s.period?.name == _selectedPeriodFilter).toList();

                return RefreshIndicator(
                  onRefresh: appState.refreshMyTrainingScores,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                    children: [
                      _buildHero(latest, appState.isLoadingTraining),
                      const SizedBox(height: 12),
                      _buildPeriodFilter(appState.trainingPeriods),
                      const SizedBox(height: 18),
                      _buildSectionHeader(
                        'Lịch sử học kỳ',
                        'Chạm để xem chi tiết theo tiêu chí',
                      ),
                      const SizedBox(height: 12),

                      if (appState.isLoadingTraining)
                        const Padding(
                          padding: EdgeInsets.only(top: 24),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (filteredScores.isEmpty)
                        _buildEmptyState(appState)
                      else
                        ...List.generate(
                          filteredScores.length,
                          (index) => _buildScoreCard(filteredScores[index], index),
                        ),
                    ],
                  ),
                );
              },
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
            colors: [Color(0xFFF8F8FF), Color(0xFFF4F7FB)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -40,
              right: -30,
              child: _buildGlowCircle(120, const Color(0xFFBFDBFE)),
            ),
            Positioned(
              bottom: -50,
              left: -40,
              child: _buildGlowCircle(160, const Color(0xFFFDE68A)),
            ),
          ],
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
        color: color.withOpacity(0.35),
      ),
    );
  }

  Widget _buildPeriodFilter(List<TrainingPeriod> periods) {
    final options = <String>[_allPeriodsLabel, ...periods.map((p) => p.name)];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((label) {
          final selected = label == _selectedPeriodFilter;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => setState(() => _selectedPeriodFilter = label),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFF173A8A) : const Color(0xFFF1F1F5),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  label,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : const Color(0xFF475569),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHero(TrainingScore? score, bool isLoading) {
    if (score == null) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFF274BBA), Color(0xFF1E3FA0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chưa có điểm rèn luyện',
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isLoading
                  ? 'Đang tải dữ liệu học kỳ...'
                  : 'Hãy quay lại sau khi admin chấm điểm.',
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 14),
            if (!isLoading)
              OutlinedButton.icon(
                onPressed: () {
                  Provider.of<AppStateService>(context, listen: false)
                      .refreshMyTrainingScores();
                },
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: Text(
                  'Tải lại',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white70),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    final maxTotal = _maxTotalFromScore(score);
    final progress = maxTotal == 0 ? 0.0 : score.totalScore / maxTotal;
    final statusColor = _statusColor(score.status);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - value)),
            child: child,
          ),
        );
      },
            child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFF274BBA), Color(0xFF1E3FA0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Học kỳ gần nhất',
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              score.period?.name ?? 'Học kỳ',
              style: GoogleFonts.playfairDisplay(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tổng điểm',
                        style: GoogleFonts.manrope(
                          fontSize: 10,
                          color: _muted,
                        ),
                      ),
                      Text(
                        '${score.totalScore}',
                        style: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: statusColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    score.displayStatus,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.white.withOpacity(0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFFFBBF24),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              maxTotal > 0 ? 'Mục tiêu: $maxTotal điểm' : 'Chưa có tiêu chí',
              style: GoogleFonts.manrope(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
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

  Widget _buildEmptyState(AppStateService appState) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.assignment, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            'Chưa có điểm rèn luyện',
            style: GoogleFonts.manrope(fontSize: 14, color: _muted),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => appState.refreshMyTrainingScores(),
            child: const Text('Tải lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildSelfScorePanel(AppStateService appState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tự chấm điểm rèn luyện',
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Cán bộ đoàn có thể tự nhập điểm của mình, sau đó admin sẽ duyệt hoặc sửa lại trước khi chốt.',
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: _muted,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _openSelfScoreForm(appState),
              icon: const Icon(Icons.edit_note),
              label: const Text('Tự chấm điểm'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                textStyle: GoogleFonts.manrope(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openSelfScoreForm(AppStateService appState) async {
    final currentUser = appState.currentUser;
    if (currentUser == null) return;

    if (appState.trainingCriteria.isEmpty) {
      await appState.refreshTrainingCriteria();
    }
    if (appState.trainingPeriods.isEmpty) {
      await appState.refreshTrainingPeriods();
    }

    if (appState.trainingCriteria.isEmpty || appState.trainingPeriods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa sẵn sàng dữ liệu để tự chấm điểm.')),
      );
      return;
    }

    final user = UserItem(
      id: currentUser['id'] ?? 0,
      fullName: currentUser['full_name']?.toString() ?? '',
      email: currentUser['email']?.toString() ?? '',
      phone: currentUser['phone']?.toString() ?? '',
      studentCode: currentUser['student_code']?.toString() ??
          currentUser['studentCode']?.toString(),
      position: currentUser['position']?.toString(),
      role: currentUser['role']?.toString() ?? 'staff',
      status: currentUser['status']?.toString() ?? 'active',
      unitId: currentUser['unit_id'] is int
          ? currentUser['unit_id'] as int
          : null,
      unitName: currentUser['unit_name']?.toString(),
      avatarUrl: null,
    );

    final period = appState.trainingPeriods.first;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TrainingScoreFormScreen(
          member: user,
          period: period,
          criteria: appState.trainingCriteria,
          initialStatus: 'submitted',
        ),
      ),
    );

    if (result == true) {
      await appState.refreshMyTrainingScores();
    }
  }

  Widget _buildScoreCard(TrainingScore score, int index) {
    final statusColor = _statusColor(score.status);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + (index * 40)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - value)),
            child: child,
          ),
        );
      },
      child: InkWell(
        onTap: () => _showScoreDetail(score),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 60,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      score.period?.name ?? 'Học kỳ',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      score.displayStatus,
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${score.totalScore} điểm',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showScoreDetail(TrainingScore score) {
    final maxTotal = _maxTotalFromScore(score);
    final progress = maxTotal == 0 ? 0.0 : score.totalScore / maxTotal;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (context, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Text(
                score.period?.name ?? 'Chi tiết',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                score.displayStatus,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: _statusColor(score.status),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFF1F5F9),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Color(0xFFFBBF24)),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tổng điểm: ${score.totalScore} / ${maxTotal == 0 ? '-' : maxTotal}',
                style: GoogleFonts.manrope(fontSize: 12, color: _muted),
              ),
              const SizedBox(height: 16),
              if (score.items.isEmpty)
                Text(
                  'Chưa có chi tiết tiêu chí',
                  style: GoogleFonts.manrope(fontSize: 13, color: _muted),
                )
              else
                ...score.items.map((item) {
                  final name = item.criterion?.name ?? 'Tiêu chí';
                  final maxScore = item.criterion?.maxScore ?? 0;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _ink,
                            ),
                          ),
                        ),
                        Text(
                          '${item.score}/$maxScore',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _primaryDark,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  int _maxTotalFromScore(TrainingScore score) {
    int total = 0;
    for (final item in score.items) {
      total += item.criterion?.maxScore ?? 0;
    }
    return total;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return const Color(0xFF16A34A);
      case 'submitted':
        return const Color(0xFF2563EB);
      case 'rejected':
        return const Color(0xFFDC2626);
      case 'draft':
        return const Color(0xFFEA580C);
      default:
        return Colors.grey;
    }
  }
}
