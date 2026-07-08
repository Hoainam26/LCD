import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../constants/colors.dart';
import '../models/training_period.dart';
import '../models/training_score.dart';
import '../models/user_item.dart';
import '../services/api_service.dart';
import '../services/app_state_service.dart';
import 'training_score_form_screen.dart';

const Color _ink = AppColors.textPrimary;
const Color _muted = AppColors.textSecondary;
const Color _primary = AppColors.secondary;
const Color _primaryDark = AppColors.primaryDark;
const Color _accent = AppColors.warning;
const Color _bg = AppColors.backgroundColor;

class TrainingScoreManagementScreen extends StatefulWidget {
  const TrainingScoreManagementScreen({super.key});

  @override
  State<TrainingScoreManagementScreen> createState() =>
      _TrainingScoreManagementScreenState();
}

class _TrainingScoreManagementScreenState
    extends State<TrainingScoreManagementScreen> {
  static const String _allFaculties = 'Tất cả khoa';
  static const String _allCohorts = 'Tất cả';

  TrainingPeriod? _selectedPeriod;
  bool _isLoadingScores = false;
  bool _isLoadingFaculties = false;
  final TextEditingController _searchController = TextEditingController();
  final Map<int, TrainingScore> _scoreMap = {};
  final Map<int, String> _facultyByUnitId = {};
  List<String> _facultyOptions = [_allFaculties];
  Map<String, List<String>> _classesByFaculty = {};
  List<String> _classOptions = [];
  String? _selectedClass;
  String _selectedFaculty = _allFaculties;
  List<String> _cohortOptions = [_allCohorts];
  String _selectedCohort = _allCohorts;
  bool _onlyMyClass = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadInitialData);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final appState = Provider.of<AppStateService>(context, listen: false);
    await Future.wait([
      appState.refreshTrainingPeriods(),
      appState.refreshTrainingCriteria(),
      appState.refreshMembers(),
      appState.refreshOfficers(),
      _loadFacultyMapping(),
    ]);

    if (_selectedPeriod == null && appState.trainingPeriods.isNotEmpty) {
      setState(() {
        _selectedPeriod = appState.trainingPeriods.first;
      });
      await _loadScores();
    }
  }

  Future<void> _loadFacultyMapping() async {
    setState(() => _isLoadingFaculties = true);
    _facultyByUnitId.clear();

    final units = await ApiService.getUnits();
    final map = <int, Map<String, dynamic>>{};
    for (final item in units) {
      if (item is! Map<String, dynamic>) continue;
      final id = item['id'];
      if (id is int) {
        map[id] = item;
      }
    }

    String? resolveFacultyForUnit(int? unitId) {
      if (unitId == null) return null;

      int? current = unitId;
      final visited = <int>{};
      while (current != null && !visited.contains(current)) {
        visited.add(current);
        final unit = map[current];
        if (unit == null) break;

        final level = (unit['level']?.toString() ?? '').toLowerCase();
        final name = unit['name']?.toString().trim() ?? '';
        if ((level == 'faculty' || level == 'khoa') && name.isNotEmpty) {
          return name;
        }

        final parent = unit['parent_id'];
        current = parent is int ? parent : null;
      }
      return null;
    }

    final facultySet = <String>{};
    for (final entry in map.entries) {
      final faculty = resolveFacultyForUnit(entry.key);
      if (faculty != null && faculty.isNotEmpty) {
        _facultyByUnitId[entry.key] = faculty;
        facultySet.add(faculty);
      }
    }

    final sortedFaculties = facultySet.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    // Build classes grouped by faculty (units with level 'branch')
    final classesMap = <String, List<String>>{};
    for (final entry in map.entries) {
      final unit = entry.value;
      final level = (unit['level']?.toString() ?? '').toLowerCase();
      if (level != 'branch') continue;
      final parentId = unit['parent_id'] is int ? unit['parent_id'] as int : null;
      final facultyName = resolveFacultyForUnit(parentId);
      if (facultyName == null) continue;
      final className = (unit['name']?.toString() ?? unit['code']?.toString() ?? '').trim();
      if (className.isEmpty) continue;
      classesMap.putIfAbsent(facultyName, () => []).add(className);
    }

    // sort class lists
    for (final k in classesMap.keys) {
      classesMap[k]!..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    }

    // Prefer selecting the CNTT faculty when available
    String preferred = '';
    for (final s in sortedFaculties) {
      if (s.toLowerCase().contains('cntt') || s.toLowerCase().contains('khoa cntt')) {
        preferred = s;
        break;
      }
    }

    if (!mounted) return;
    setState(() {
      _facultyOptions = [_allFaculties, ...sortedFaculties];
      _classesByFaculty = classesMap;
      if (preferred.isNotEmpty) {
        _selectedFaculty = preferred;
      } else if (!_facultyOptions.contains(_selectedFaculty)) {
        _selectedFaculty = _allFaculties;
      }
      _classOptions = _classesByFaculty[_selectedFaculty] ?? [];
      _selectedClass = _classOptions.isNotEmpty ? _classOptions.first : null;
      _isLoadingFaculties = false;
    });
  }

  Future<void> _loadScores() async {
    if (_selectedPeriod == null) return;
    setState(() => _isLoadingScores = true);
    _scoreMap.clear();

    final items = await ApiService.getTrainingScores(
      periodId: _selectedPeriod!.id,
    );
    for (final item in items) {
      final score = TrainingScore.fromApi(item);
      _scoreMap[score.userId] = score;
    }

    if (!mounted) return;
    setState(() => _isLoadingScores = false);
  }

  List<UserItem> _buildScorableUsers(AppStateService appState) {
    final users = <int, UserItem>{};

    for (final user in appState.members) {
      if (!_isScorableUser(user)) continue;
      users[user.id] = user;
    }

    for (final user in appState.officers) {
      if (!_isScorableUser(user)) continue;
      users[user.id] = user;
    }

    final list = users.values.toList();
    list.sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
    return list;
  }

  bool _isScorableUser(UserItem user) {
    final role = user.role.toLowerCase();
    return role == 'member' || role == 'staff';
  }

  String _cohortFromStudentCode(String? studentCode) {
    final code = (studentCode ?? '').trim();
    if (code.length < 2) return '';
    final match = RegExp(r'^(\d{2})').firstMatch(code);
    if (match == null) return '';
    return 'Khóa ${match.group(1)}';
  }

  List<String> _buildCohortOptions(List<UserItem> users) {
    final cohorts = <String>{};
    for (final user in users) {
      final cohort = _cohortFromStudentCode(user.studentCode);
      if (cohort.isNotEmpty) {
        cohorts.add(cohort);
      }
    }
    final list = cohorts.toList()
      ..sort((a, b) {
        final aNum = int.tryParse(a.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        final bNum = int.tryParse(b.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        return aNum.compareTo(bNum);
      });
    return [_allCohorts, ...list];
  }

  bool _matchesSearch(UserItem user, String keyword) {
    if (keyword.isEmpty) return true;
    final normalized = keyword.toLowerCase();
    final haystack = [
      user.fullName,
      user.unitName ?? '',
      user.studentCode ?? '',
    ].join(' ').toLowerCase();
    return haystack.contains(normalized);
  }

  List<UserItem> _applyFilters(List<UserItem> users) {
    final keyword = _searchController.text.trim();
    return users.where((user) {
      final cohort = _cohortFromStudentCode(user.studentCode);
      final matchesCohort = _selectedCohort == _allCohorts || cohort == _selectedCohort;
      return matchesCohort && _matchesSearch(user, keyword);
    }).toList();
  }

  Map<String, List<UserItem>> _groupMembersByClass(List<UserItem> members) {
    final map = <String, List<UserItem>>{};
    for (final member in members) {
      final className = (member.unitName ?? '').trim().isNotEmpty
          ? member.unitName!.trim()
          : 'Chưa phân lớp';
      map.putIfAbsent(className, () => <UserItem>[]).add(member);
    }

    final sortedKeys = map.keys.toList()
      ..sort((a, b) {
        if (a == 'Chưa phân lớp') return 1;
        if (b == 'Chưa phân lớp') return -1;
        return a.toLowerCase().compareTo(b.toLowerCase());
      });

    final sorted = <String, List<UserItem>>{};
    for (final key in sortedKeys) {
      final list = map[key]!..sort(
          (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
        );
      sorted[key] = list;
    }
    return sorted;
  }



  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);
    final textTheme = GoogleFonts.manropeTextTheme(baseTheme.textTheme);
    final appStateGlobal = Provider.of<AppStateService>(context);
    final currentRole = appStateGlobal.currentUser?['role']?.toString().toLowerCase() ?? '';
    final isAdmin = currentRole == 'admin';
    final isStaff = currentRole == 'staff';

    return Theme(
      data: baseTheme.copyWith(textTheme: textTheme),
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          title: Text(
            'Chấm điểm rèn luyện',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          backgroundColor: Colors.white,
          foregroundColor: _ink,
          elevation: 0,
          actions: [
            const SizedBox.shrink(),
          ],
        ),
        body: Stack(
          children: [
            _buildBackground(),
            Consumer<AppStateService>(
              builder: (context, appState, _) {
                final scorableUsers = _buildScorableUsers(appState);
                final cohortOptions = _buildCohortOptions(scorableUsers);
                if (_cohortOptions.length != cohortOptions.length ||
                    !_cohortOptions.toSet().containsAll(cohortOptions)) {
                  _cohortOptions = cohortOptions;
                  if (!_cohortOptions.contains(_selectedCohort)) {
                    _selectedCohort = _allCohorts;
                  }
                }

                final filteredMembers = _applyFilters(scorableUsers);
                final groupedMembers = _groupMembersByClass(filteredMembers);
                final visibleMembers = filteredMembers;

                final scoredCount = visibleMembers
                    .where((member) => _scoreMap.containsKey(member.id))
                    .length;
                final pendingCount =
                    (visibleMembers.length - scoredCount).clamp(0, visibleMembers.length);

                return RefreshIndicator(
                  onRefresh: () async {
                    await Future.wait([
                      appState.refreshTrainingPeriods(),
                      appState.refreshTrainingCriteria(),
                      appState.refreshMembers(),
                      appState.refreshOfficers(),
                      _loadFacultyMapping(),
                      _loadScores(),
                    ]);
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                    children: [
                      _buildHero(
                        appState,
                        visibleMembers.length,
                        scoredCount,
                        pendingCount,
                        isAdmin: isAdmin,
                        isStaff: isStaff,
                      ),
                      const SizedBox(height: 14),
                      _buildCohortChips(),
                      const SizedBox(height: 14),
                      _buildSearchField(),
                      const SizedBox(height: 18),
                      _buildSectionHeader('Danh sách đoàn viên', 'Bộ lọc'),
                      const SizedBox(height: 10),
                      if (_isLoadingScores ||
                          appState.isLoadingMembers ||
                          appState.isLoadingOfficers ||
                          _isLoadingFaculties)
                        const Padding(
                          padding: EdgeInsets.only(top: 24),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (visibleMembers.isEmpty)
                        _buildEmptyState()
                      else
                        ..._buildGroupedMemberSections(groupedMembers, appState),
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

  Widget _buildFacultySelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.apartment, size: 18, color: _primaryDark),
          const SizedBox(width: 8),
          Text(
            'Khoa CNTT',
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedFaculty,
                icon: const SizedBox.shrink(),
                items: _facultyOptions
                    .map(
                      (faculty) => DropdownMenuItem<String>(
                        value: faculty,
                        child: Text(faculty),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedFaculty = value;
                    _classOptions = _classesByFaculty[_selectedFaculty] ?? [];
                    _selectedClass = _classOptions.isNotEmpty ? _classOptions.first : null;
                  });
                },
              ),
            ),
          ),
          if (_classOptions.isNotEmpty) ...[
            const SizedBox(width: 10),
            SizedBox(
              width: 160,
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedClass,
                  icon: const SizedBox.shrink(),
                  items: _classOptions
                      .map((c) => DropdownMenuItem<String>(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      _selectedClass = v;
                    });
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCohortChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _cohortOptions.map((cohort) {
          final selected = cohort == _selectedCohort;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => setState(() => _selectedCohort = cohort),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFF173A8A) : const Color(0xFFF1F1F5),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  cohort,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : const Color(0xFF4B5563),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Tìm kiếm đoàn viên...',
          hintStyle: GoogleFonts.manrope(
            fontSize: 14,
            color: const Color(0xFF94A3B8),
          ),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        ),
      ),
    );
  }



  List<Widget> _buildGroupedMemberSections(
    Map<String, List<UserItem>> groupedMembers,
    AppStateService appState,
  ) {
    final widgets = <Widget>[];
    final faculties = _selectedFaculty == _allFaculties
        ? groupedMembers.keys.toList()
        : <String>[_selectedFaculty];

    for (final faculty in faculties) {
      final members = groupedMembers[faculty] ?? const <UserItem>[];
      if (members.isEmpty) continue;

      widgets.add(_buildFacultyHeader(faculty, members.length));
      widgets.add(const SizedBox(height: 8));
      widgets.addAll(
        List.generate(
          members.length,
          (index) => _buildMemberTile(
            members[index],
            appState,
            index,
          ),
        ),
      );
      widgets.add(const SizedBox(height: 4));
    }

    return widgets;
  }

  Widget _buildFacultyHeader(String faculty, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.list_alt, size: 18, color: _primaryDark),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'LỚP ${faculty.toUpperCase()} (${count.toString()})',
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF475569),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, List<UserItem>> _groupMembersByFaculty(List<UserItem> members) {
    final map = <String, List<UserItem>>{};

    for (final member in members) {
      final faculty = _resolveFacultyName(member);
      map.putIfAbsent(faculty, () => <UserItem>[]).add(member);
    }

    final sortedKeys = map.keys.toList()
      ..sort((a, b) {
        if (a == 'Chưa phân khoa') return 1;
        if (b == 'Chưa phân khoa') return -1;
        return a.toLowerCase().compareTo(b.toLowerCase());
      });

    final sorted = <String, List<UserItem>>{};
    for (final key in sortedKeys) {
      final list = map[key]!..sort(
          (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
        );
      sorted[key] = list;
    }

    return sorted;
  }

  String _resolveFacultyName(UserItem member) {
    if (member.unitId != null) {
      final faculty = _facultyByUnitId[member.unitId!];
      if (faculty != null && faculty.isNotEmpty) {
        return faculty;
      }
    }

    final rawUnit = member.unitName?.trim() ?? '';
    if (rawUnit.isNotEmpty) {
      return rawUnit;
    }

    return 'Chưa phân khoa';
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

  Widget _buildHero(
    AppStateService appState,
    int memberCount,
    int scoredCount,
    int pendingCount, {
    required bool isAdmin,
    required bool isStaff,
  }) {
    final hasPeriods = appState.trainingPeriods.isNotEmpty;
    final hasCriteria = appState.trainingCriteria.isNotEmpty;
    final period = _selectedPeriod?.name ?? 'HK2 2025-2026';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [Color(0xFF274BBA), Color(0xFF1E3FA0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3FA0).withOpacity(0.28),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Học kỳ hiện tại',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.55),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      period,
                      style: GoogleFonts.manrope(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.fact_check_outlined,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final tileWidth = (constraints.maxWidth - 16) / 3;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildStatCard('Tổng', memberCount, const Color(0xFF3655C9), tileWidth),
                  _buildStatCard('Đã chấm', scoredCount, const Color(0xFF3655C9), tileWidth),
                  _buildStatCard('Còn lại', pendingCount, const Color(0xFF3655C9), tileWidth),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (!hasPeriods)
                _buildAlertPill(Icons.calendar_month, 'Chưa có học kỳ'),
              if (!hasCriteria)
                _buildAlertPill(Icons.rule_folder, 'Chưa có tiêu chí'),
              if (isAdmin)
                _buildAlertPill(Icons.approval_outlined, 'Admin duyệt điểm'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlertPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(List<TrainingPeriod> periods) {
    final TrainingPeriod? effectiveSelected = periods.isEmpty
        ? null
        : (_selectedPeriod == null
            ? periods.first
            : (periods.firstWhere(
                (p) => p.id == _selectedPeriod!.id,
                orElse: () => periods.first,
              )));

    return DropdownButtonFormField<TrainingPeriod>(
      value: effectiveSelected,
      icon: const SizedBox.shrink(),
      decoration: InputDecoration(
        labelText: 'Học kỳ',
        labelStyle: GoogleFonts.manrope(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.35)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.8)),
        ),
        prefixIcon: const Icon(Icons.calendar_today, color: Colors.white),
      ),
      dropdownColor: Colors.white,
      iconEnabledColor: Colors.white,
      style: GoogleFonts.manrope(color: _ink, fontWeight: FontWeight.w600),
      items: periods
          .map(
            (period) => DropdownMenuItem(
              value: period,
              child: Text(period.name),
            ),
          )
          .toList(),
      onChanged: periods.isEmpty
          ? null
          : (value) async {
              setState(() {
                _selectedPeriod = value;
              });
              await _loadScores();
            },
    );
  }

  Widget _buildStatCard(
    String label,
    int value,
    Color background,
    double width,
  ) {
    final useDarkText = background.computeLuminance() > 0.72;
    final labelColor = useDarkText ? const Color(0xFF64748B) : Colors.white70;
    final valueColor = useDarkText ? _primaryDark : Colors.white;

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: background.withOpacity(0.95),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 11,
              color: labelColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value.toString(),
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF173A8A),
            ),
          ),
        ),
        Text(
          subtitle,
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF173A8A),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.group_off, size: 52, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            'Chưa có đối tượng phù hợp',
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: _muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberTile(
    UserItem member,
    AppStateService appState,
    int index,
  ) {
    final score = _scoreMap[member.id];
    final total = score?.totalScore;
    final status = score?.displayStatus ?? 'Chưa chấm';
    final statusColor = _statusColor(score?.status);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + (index * 45)),
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
        onTap: () => _openScoreForm(member, appState, score),
        borderRadius: BorderRadius.circular(22),
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFEAF6F3),
                radius: 24,
                child: Text(
                  member.fullName.isNotEmpty
                      ? member.fullName.substring(0, 1).toUpperCase()
                      : '?',
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1D4ED8),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      member.fullName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.manrope(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: _ink,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Builder(builder: (ctx) {
                                    final currentId = appState.currentUser?['id'] is int
                                        ? appState.currentUser!['id'] as int
                                        : null;
                                    if (currentId != null && member.id == currentId) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFDCFCE7),
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          'Bạn',
                                          style: GoogleFonts.manrope(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF065F46),
                                          ),
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  }),
                                ],
                              ),
                            ),
                        Text(
                          total != null ? '$total điểm' : '-- điểm',
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: _ink,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      member.unitName ?? 'Chưa phân công',
                      style: GoogleFonts.manrope(
                        fontSize: 12.5,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        status,
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    height: 38,
                    child: ElevatedButton.icon(
                      onPressed: () => _openScoreForm(
                        member,
                        appState,
                        score,
                      ),
                      icon: const Icon(Icons.edit, size: 16),
                      label: Text(
                        total == null ? 'Chấm điểm' : 'Sửa điểm',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF173A8A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                        textStyle: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openScoreForm(
    UserItem member,
    AppStateService appState,
    TrainingScore? score,
  ) async {
    if (!_isScorableUser(member)) {
      _showMessage('Chỉ có thể chấm điểm cho đoàn viên và cán bộ đoàn.');
      return;
    }
    if (_selectedPeriod == null) {
      _showMessage('Vui lòng chọn học kỳ trước khi chấm điểm.');
      return;
    }
    if (appState.trainingCriteria.isEmpty) {
      _showMessage('Chưa có tiêu chí rèn luyện. Vui lòng tải lại.');
      return;
    }

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TrainingScoreFormScreen(
          member: member,
          period: _selectedPeriod!,
          criteria: appState.trainingCriteria,
          existingScore: score,
        ),
      ),
    );

    if (result == true) {
      await _loadScores();
    }
  }

  Widget _buildReviewButton({
    required String label,
    required IconData icon,
    required Color background,
    required Color foreground,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 32,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 14, color: foreground),
        label: Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: foreground,
          ),
        ),
        style: TextButton.styleFrom(
          backgroundColor: background,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _accent,
      ),
    );
  }

  Color _statusColor(String? status) {
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
