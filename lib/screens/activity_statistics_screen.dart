import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../constants/colors.dart';
import '../models/event_model.dart';
import '../models/user_item.dart';
import '../services/api_service.dart';
import '../services/app_state_service.dart';

class ActivityStatisticsScreen extends StatefulWidget {
  final String eventId;
  final String title;
  final bool attendanceMode;

  const ActivityStatisticsScreen({
    super.key,
    required this.eventId,
    required this.title,
    this.attendanceMode = true,
  });

  @override
  State<ActivityStatisticsScreen> createState() => _ActivityStatisticsScreenState();
}

class _ActivityStatisticsScreenState extends State<ActivityStatisticsScreen> {
  bool _isLoading = false;
  bool _isRefreshing = false;
  Map<String, dynamic>? _stats;
  Event? _event;
  List<dynamic> _participants = [];
  List<_ParticipantRow> _rows = [];
  String _searchQuery = '';
  String _selectedClass = 'Tất cả';
  String _selectedStatus = 'Tất cả';
  List<String> _classOptions = const ['Tất cả'];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _isRefreshing = true;
      });
    }

    try {
      final results = await Future.wait([
        ApiService.getActivityStatistics(widget.eventId),
        ApiService.getActivityById(widget.eventId),
        ApiService.getEventParticipants(widget.eventId),
      ]);

      final stats = _extractMap(results[0] as Map<String, dynamic>);
      final eventData = _extractMap(results[1] as Map<String, dynamic>);
      final participants = List<dynamic>.from(results[2] as List<dynamic>);

      if (!mounted) return;

      final event = eventData != null ? Event.fromApi(eventData) : null;

      setState(() {
        _stats = stats;
        _event = event;
        _participants = participants;
        _isLoading = false;
        _isRefreshing = false;
      });

      await _rebuildRows();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _stats = null;
        _event = null;
        _participants = [];
        _rows = [];
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  Map<String, dynamic>? _extractMap(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }

  Future<void> _rebuildRows() async {
    final appState = Provider.of<AppStateService>(context, listen: false);
    await appState.refreshCurrentUser();
    await appState.refreshMembers();
    await appState.refreshOfficers();

    final managedUnit = _managedUnit(appState);
    final participantById = <String, Map<String, dynamic>>{};
    for (final item in _participants) {
      if (item is Map<String, dynamic>) {
        final id = _participantId(item);
        if (id != null && id.isNotEmpty) {
          participantById[id] = item;
        }
      } else if (item is Map) {
        final map = Map<String, dynamic>.from(item);
        final id = _participantId(map);
        if (id != null && id.isNotEmpty) {
          participantById[id] = map;
        }
      }
    }

    final members = appState.members.where((member) {
      if (managedUnit.isEmpty) return true;
      return _normalizedUnit(member.unitName) == _normalizedUnit(managedUnit);
    }).toList();

    final classSet = <String>{};
    final rows = <_ParticipantRow>[];
    for (final member in members) {
      final className = _resolvedClass(member);
      if (className.isNotEmpty) {
        classSet.add(className);
      }

      final participant = participantById[member.id.toString()];
      rows.add(
        _ParticipantRow(
          memberId: member.id.toString(),
          fullName: member.fullName,
          studentCode: member.studentCode?.trim() ?? '',
          className: className.isEmpty ? 'Chưa có lớp' : className,
          participantStatus: _normalizeStatus(participant),
          checkInTime: participant?['check_in_at']?.toString() ??
              participant?['checkInAt']?.toString(),
        ),
      );
    }

    rows.sort((a, b) => a.fullName.compareTo(b.fullName));

    if (!mounted) return;
    setState(() {
      _rows = rows;
      _classOptions = [
        'Tất cả',
        ...classSet.toList()..sort(),
      ];
      if (!_classOptions.contains(_selectedClass)) {
        _selectedClass = 'Tất cả';
      }
    });
  }

  String _managedUnit(AppStateService appState) {
    final currentUserId = appState.currentUser?['id']?.toString();
    String managedUnit = '';

    for (final officer in appState.officers) {
      if (officer.id.toString() == currentUserId) {
        managedUnit = (officer.unitName ?? '').trim();
        break;
      }
    }

    if (managedUnit.isEmpty) {
      managedUnit = (appState.currentUser?['unit_name'] ??
              appState.currentUser?['unitName'] ??
              '')
          .toString()
          .trim();
    }

    return managedUnit;
  }

  String _normalizedUnit(String? unit) => unit?.trim().toLowerCase() ?? '';

  String _resolvedClass(UserItem member) {
    final unit = (member.unitName ?? '').trim();
    if (unit.isNotEmpty) return unit;
    return 'Chưa có lớp';
  }

  String? _participantId(Map<String, dynamic> participant) {
    final user = participant['member'] ?? participant['user'] ?? participant['User'];
    return participant['memberId']?.toString() ??
        participant['member_id']?.toString() ??
        participant['user_id']?.toString() ??
        (user is Map ? user['id']?.toString() : null);
  }

  String _participantName(Map<String, dynamic>? participant) {
    if (participant == null) return '';
    final user = participant['member'] ?? participant['user'] ?? participant['User'] ?? {};
    if (user is Map) {
      return user['fullName']?.toString() ??
          user['full_name']?.toString() ??
          user['name']?.toString() ??
          '';
    }
    return '';
  }

  String _participantCode(Map<String, dynamic>? participant) {
    if (participant == null) return '';
    final user = participant['member'] ?? participant['user'] ?? participant['User'] ?? {};
    if (user is Map) {
      return user['studentCode']?.toString() ??
          user['student_code']?.toString() ??
          user['mssv']?.toString() ??
          '';
    }
    return '';
  }

  String _normalizeStatus(Map<String, dynamic>? participant) {
    if (participant == null) return 'absent';
    final raw = participant['status'] ??
        participant['attendanceStatus'] ??
        participant['attendance_status'];
    final text = raw?.toString().toLowerCase() ?? '';
    if (text == 'pending') return 'pending';
    if (['attended', 'checked_in', 'checkin', 'present'].contains(text)) {
      return 'attended';
    }
    if (['absent', 'missed'].contains(text)) {
      return 'absent';
    }
    if (['canceled', 'cancelled', 'rejected'].contains(text)) {
      return 'canceled';
    }
    if (text == 'registered') return 'registered';
    return participant.isEmpty ? 'absent' : 'registered';
  }

  bool _isRegisteredLike(String status) {
    return status == 'registered' || status == 'pending';
  }

  String _statusLabel(String status, {required bool attendanceMode}) {
    switch (status) {
      case 'attended':
        return 'Đã điểm danh';
      case 'pending':
        return 'Chờ duyệt';
      case 'registered':
        return 'Đã đăng ký';
      case 'canceled':
        return 'Hủy';
      case 'absent':
        return attendanceMode ? 'Vắng mặt' : 'Chưa đăng ký';
      default:
        return attendanceMode ? 'Vắng mặt' : 'Chưa đăng ký';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'attended':
        return const Color(0xFF10B981);
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'registered':
        return const Color(0xFF2563EB);
      case 'canceled':
        return const Color(0xFF9CA3AF);
      case 'absent':
      default:
        return const Color(0xFFEF4444);
    }
  }

  String _formatShortDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  }

  List<_ParticipantRow> _filteredRows() {
    final keyword = _searchQuery.trim().toLowerCase();
    return _rows.where((row) {
      final matchesClass = _selectedClass == 'Tất cả' || row.className == _selectedClass;
      final matchesStatus =
          _selectedStatus == 'Tất cả' ||
          _statusLabel(
                row.participantStatus,
                attendanceMode: widget.attendanceMode,
              ) ==
              _selectedStatus;
      final matchesSearch = keyword.isEmpty ||
          row.fullName.toLowerCase().contains(keyword) ||
          row.studentCode.toLowerCase().contains(keyword) ||
          row.className.toLowerCase().contains(keyword);
      return matchesClass && matchesStatus && matchesSearch;
    }).toList();
  }

  List<_ParticipantRow> _classFilteredRows() {
    return _rows.where((row) {
      return _selectedClass == 'Tất cả' || row.className == _selectedClass;
    }).toList();
  }

  int _countStatus(List<_ParticipantRow> rows, String status) {
    return rows.where((row) => row.participantStatus == status).length;
  }

  int _countRegisteredLike(List<_ParticipantRow> rows) {
    return rows.where((row) => _isRegisteredLike(row.participantStatus)).length;
  }

  List<String> _statusFilterOptions() {
    if (widget.attendanceMode) {
      return const ['Tất cả', 'Đã điểm danh', 'Chờ duyệt', 'Đã đăng ký', 'Hủy', 'Vắng mặt'];
    }
    return const ['Tất cả', 'Chờ duyệt', 'Đã đăng ký', 'Chưa đăng ký', 'Hủy'];
  }

  @override
  Widget build(BuildContext context) {
    final classRows = _classFilteredRows();
    final rows = _filteredRows();
    final total = classRows.length;
    final registered = _countRegisteredLike(classRows);
    final attended = _countStatus(classRows, 'attended');
    final absent = _countStatus(classRows, 'absent');
    final title = widget.attendanceMode ? 'Thống kê tham gia' : 'Thống kê đăng ký';
    final summaryRegisteredLabel = widget.attendanceMode ? 'Đã tham gia' : 'Đã đăng ký';
    final summaryAbsentLabel = widget.attendanceMode ? 'Vắng mặt' : 'Chưa đăng ký';
    final sectionCountLabel = widget.attendanceMode
        ? '$attended đã tham gia'
        : '$registered đã đăng ký';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FF),
      appBar: AppBar(
        title: Text(
          title,
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        backgroundColor: const Color(0xFFF7F8FF),
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        surfaceTintColor: const Color(0xFFF7F8FF),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.share_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: _isLoading && _event == null
            ? ListView(
                padding: const EdgeInsets.all(16),
                children: const [
                  SizedBox(height: 220),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  _buildSummaryRow(
                    total,
                    registered,
                    attended,
                    absent,
                    registeredLabel: summaryRegisteredLabel,
                    absentLabel: summaryAbsentLabel,
                  ),
                  const SizedBox(height: 16),
                  _buildClassFilterRow(),
                  const SizedBox(height: 10),
                  _buildStatusFilterRow(),
                  const SizedBox(height: 10),
                  _buildSearchField(),
                  const SizedBox(height: 14),
                  _buildSectionHeader(rows.length, sectionCountLabel),
                  const SizedBox(height: 10),
                  if (rows.isEmpty)
                    _buildEmptyState()
                  else
                    ...rows.map(_buildMemberCard),
                  const SizedBox(height: 20),
                  _buildExportButton(),
                ],
              ),
      ),
    );
  }

  Widget _buildSummaryRow(
    int total,
    int registered,
    int attended,
    int absent, {
    required String registeredLabel,
    required String absentLabel,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            label: 'Tổng đăng ký',
            value: total.toString(),
            icon: Icons.groups_outlined,
            background: const Color(0xFF254AA8),
            foreground: Colors.white,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSummaryCard(
            label: registeredLabel,
            value: registered.toString(),
            icon: widget.attendanceMode
                ? Icons.check_circle_outline
                : Icons.event_available_outlined,
            background: Colors.white,
            foreground: const Color(0xFF1D4ED8),
            borderColor: const Color(0xFFE5E7EB),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSummaryCard(
            label: absentLabel,
            value: absent.toString(),
            icon: Icons.cancel_outlined,
            background: Colors.white,
            foreground: const Color(0xFFDC2626),
            borderColor: const Color(0xFFE5E7EB),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String label,
    required String value,
    required IconData icon,
    required Color background,
    required Color foreground,
    Color? borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor ?? Colors.transparent),
        boxShadow: [
          if (background == Colors.white)
            BoxShadow(
              color: const Color(0x0F0F172A),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: foreground.withOpacity(background == Colors.white ? 0.9 : 0.65),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(icon, size: 18, color: foreground),
              const SizedBox(width: 8),
              Text(
                value,
                style: GoogleFonts.manrope(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: foreground,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClassFilterRow() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFD8DDEB)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedClass,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
                items: _classOptions
                    .map(
                      (item) => DropdownMenuItem(
                        value: item,
                        child: Text(
                          item,
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _selectedClass = value);
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: const Color(0xFFEAEAF4),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.tune, color: Color(0xFF334155)),
        ),
      ],
    );
  }

  Widget _buildStatusFilterRow() {
    final options = _statusFilterOptions();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((option) {
          final selected = _selectedStatus == option;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(option),
              selected: selected,
              onSelected: (_) => setState(() => _selectedStatus = option),
              selectedColor: const Color(0xFF254AA8).withOpacity(0.14),
              backgroundColor: Colors.white,
              labelStyle: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? const Color(0xFF254AA8) : const Color(0xFF475569),
              ),
              side: BorderSide(
                color: selected ? const Color(0xFF254AA8) : const Color(0xFFD8DDEB),
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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8DDEB)),
      ),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Tìm tên sinh viên...',
          hintStyle: GoogleFonts.manrope(
            fontSize: 14,
            color: const Color(0xFF94A3B8),
          ),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(int totalRows, String countLabel) {
    final classLabel = _selectedClass == 'Tất cả' ? 'Tất cả lớp' : _selectedClass;

    return Row(
      children: [
        Expanded(
          child: Text(
            'DANH SÁCH $classLabel'.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF334155),
            ),
          ),
        ),
        Text(
          countLabel,
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildMemberCard(_ParticipantRow row) {
    final statusColor = _statusColor(row.participantStatus);
    final statusLabel = _statusLabel(
      row.participantStatus,
      attendanceMode: widget.attendanceMode,
    );
    final initials = _initials(row.fullName);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: const Color(0xFFD9E5FF),
            child: Text(
              initials,
              style: GoogleFonts.manrope(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF173B90),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'MSSV: ${row.studentCode.isEmpty ? '--' : row.studentCode}',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: const Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  row.className,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: const Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusLabel,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                row.checkInTime == null ? '--:--' : _formatTimeOnly(row.checkInTime!),
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  color: const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.characters.take(2).toString().toUpperCase();
    }
    return '${parts.first.characters.first}${parts.last.characters.first}'.toUpperCase();
  }

  String _formatTimeOnly(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }

  Widget _buildExportButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tính năng xuất báo cáo đang phát triển')),
          );
        },
        icon: const Icon(Icons.download_outlined),
        label: const Text('Xuất báo cáo'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0B63C7),
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: const Color(0x330B63C7),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(Icons.group_off, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            'Chưa có dữ liệu phù hợp',
            style: GoogleFonts.manrope(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class _ParticipantRow {
  final String memberId;
  final String fullName;
  final String studentCode;
  final String className;
  final String participantStatus;
  final String? checkInTime;

  _ParticipantRow({
    required this.memberId,
    required this.fullName,
    required this.studentCode,
    required this.className,
    required this.participantStatus,
    required this.checkInTime,
  });
}
