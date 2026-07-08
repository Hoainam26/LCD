import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../constants/colors.dart';
import '../models/event_model.dart';
import '../models/user_item.dart';
import '../services/api_service.dart';
import '../services/app_state_service.dart';
import '../services/officer_event_registration_service.dart';
import 'activity_statistics_screen.dart';
import 'event_management_screen.dart';
import 'officer_event_detail_screen.dart';

class OfficerEventRegistrationScreen extends StatefulWidget {
  const OfficerEventRegistrationScreen({super.key});

  @override
  State<OfficerEventRegistrationScreen> createState() =>
      _OfficerEventRegistrationScreenState();
}

class _OfficerEventRegistrationScreenState
    extends State<OfficerEventRegistrationScreen> {
  String _activeFilter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final appState = Provider.of<AppStateService>(context, listen: false);
      await appState.refreshEvents();
      await appState.refreshMembers();
      await appState.refreshCurrentUser();
    });
  }

  bool _isOfficerLike(UserItem user) {
    final position = user.position?.toLowerCase() ?? '';
    return position.contains('bí thư') ||
        position.contains('phó bí thư') ||
        position.contains('cán bộ') ||
        position.contains('staff');
  }

  List<UserItem> _managedMembers(AppStateService appState) {
    final currentUserId = appState.currentUser?['id'];
    String managedUnit = '';

    for (final officer in appState.officers) {
      if (officer.id.toString() == currentUserId?.toString()) {
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

    final members = appState.members.where((m) {
      if (m.role != 'member') return false;
      if (_isOfficerLike(m)) return false;
      if (managedUnit.isEmpty) return true;
      return (m.unitName ?? '').trim() == managedUnit;
    }).toList();

    return members;
  }

  Future<void> _registerOfficer(Event event, AppStateService appState) async {
    try {
      final result = await ApiService.registerEvent(event.id.toString());
      if (!mounted) return;

      final success = result['code'] == 200;
      if (success) {
        _showSnack('${event.title} - Đăng ký thành công');
        await appState.refreshEvents();
      } else {
        _showSnack(
            result['message'] ?? 'Không thể đăng ký hoạt động. Vui lòng thử lại.');
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack('Lỗi: ${e.toString()}');
    }
  }

  Future<void> _openRegisterDialog(
      Event event, AppStateService appState) async {
    final members = _managedMembers(appState);
    if (members.isEmpty) {
      _showSnack('Không có đoàn viên trong lớp/chi đoàn đang quản lý.');
      return;
    }

    final selected = <int>{};
    final noteController = TextEditingController();

    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Đăng ký đoàn viên cho sự kiện',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(event.title, style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 220,
                      child: ListView.builder(
                        itemCount: members.length,
                        itemBuilder: (_, index) {
                          final member = members[index];
                          final checked = selected.contains(member.id);
                          return CheckboxListTile(
                            value: checked,
                            title: Text(member.fullName),
                            subtitle: Text(member.unitName ?? ''),
                            controlAffinity: ListTileControlAffinity.leading,
                            onChanged: (value) {
                              setSheetState(() {
                                if (value == true) {
                                  selected.add(member.id);
                                } else {
                                  selected.remove(member.id);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: noteController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Ghi chú gửi admin (tùy chọn)',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: selected.isEmpty
                            ? null
                            : () => Navigator.pop(sheetContext, true),
                        icon: const Icon(Icons.send),
                        label: Text('Gửi lời mời (${selected.length})'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (submitted != true) return;

    final selectedMembers =
        members.where((m) => selected.contains(m.id)).toList();
    final officerId = (appState.currentUser?['id'] ?? '').toString();
    final officerName = (appState.currentUser?['full_name'] ??
            appState.currentUser?['fullName'] ??
            'Cán bộ đoàn')
        .toString();
    final officerUnit = selectedMembers.isNotEmpty
        ? (selectedMembers.first.unitName ?? 'Lớp/chi đoàn chưa rõ')
        : 'Lớp/chi đoàn chưa rõ';

    await OfficerEventRegistrationService.submitRequest(
      eventId: event.id,
      eventTitle: event.title,
      officerId: officerId,
      officerName: officerName,
      officerUnit: officerUnit,
      memberIds: selectedMembers.map((m) => m.id.toString()).toList(),
      memberNames: selectedMembers.map((m) => m.fullName).toList(),
      note: noteController.text.trim().isEmpty
          ? null
          : noteController.text.trim(),
      invite: true,
    );

    if (!mounted) return;
    _showSnack('Đã gửi lời mời cho đoàn viên.');
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateService>(
      builder: (context, appState, _) {
        final allEvents = List<Event>.from(appState.events)
          ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
        final filteredEvents = _applyFilter(allEvents);

        return RefreshIndicator(
          onRefresh: () async {
            await appState.refreshEvents();
            await appState.refreshMembers();
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
            children: [
              _buildOverviewHeader(allEvents),
              const SizedBox(height: 12),
              _buildFilterChips(),
              const SizedBox(height: 12),
              if (filteredEvents.isEmpty)
                _buildEmptyState()
              else
                ...filteredEvents.map(
                  (event) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildOfficerEventCard(event, appState),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  List<Event> _applyFilter(List<Event> events) {
    switch (_activeFilter) {
      case 'ongoing':
        return events.where((e) => e.isOngoing).toList();
      case 'upcoming':
        return events.where((e) => e.isUpcoming).toList();
      case 'completed':
        return events.where((e) => _statusKey(e) == 'completed').toList();
      default:
        return events;
    }
  }

  String _statusKey(Event event) {
    if (event.status == 'completed' || event.hasEnded) return 'completed';
    if (event.isOngoing) return 'ongoing';
    if (event.isUpcoming) return 'upcoming';
    return 'upcoming';
  }

  String _statusLabel(Event event) {
    switch (_statusKey(event)) {
      case 'ongoing':
        return 'Đang diễn ra';
      case 'completed':
        return 'Đã kết thúc';
      default:
        return 'Sắp tới';
    }
  }

  void _openEventDetail(Event event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OfficerEventDetailScreen(event: event),
      ),
    );
  }

  void _openStatistics(Event event, {required bool attendanceMode}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActivityStatisticsScreen(
          eventId: event.id,
          title: event.title,
          attendanceMode: attendanceMode,
        ),
      ),
    );
  }

  Color _statusBg(Event event) {
    switch (_statusKey(event)) {
      case 'ongoing':
        return const Color(0xFFDFF5E8);
      case 'completed':
        return const Color(0xFFE5E7EB);
      default:
        return const Color(0xFFDBEAFE);
    }
  }

  Color _statusText(Event event) {
    switch (_statusKey(event)) {
      case 'ongoing':
        return const Color(0xFF15803D);
      case 'completed':
        return const Color(0xFF6B7280);
      default:
        return const Color(0xFF1D4ED8);
    }
  }

  Widget _buildOverviewHeader(List<Event> events) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hoạt động',
            style: GoogleFonts.manrope(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F2D7A),
              height: 1.05,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Danh sách hoạt động của đoàn',
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${events.length} hoạt động',
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1D4ED8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    Widget chip(String key, String label) {
      final active = _activeFilter == key;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _activeFilter = key),
          child: SizedBox(
            height: 54,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              decoration: BoxDecoration(
                color:
                    active ? const Color(0xFF0B2E86) : const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: active ? Colors.white : const Color(0xFF374151),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        chip('all', 'Tất cả'),
        const SizedBox(width: 8),
        chip('ongoing', 'Đang diễn ra'),
        const SizedBox(width: 8),
        chip('upcoming', 'Sắp tới'),
        const SizedBox(width: 8),
        chip('completed', 'Đã kết thúc'),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          const Icon(Icons.event_busy, size: 28, color: Color(0xFF9CA3AF)),
          const SizedBox(height: 8),
          Text(
            'Không có hoạt động phù hợp bộ lọc',
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfficerEventCard(Event event, AppStateService appState) {
    final status = _statusKey(event);

    return Container(
      padding: const EdgeInsets.fromLTRB(13, 13, 13, 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _statusBg(event),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _statusLabel(event).toUpperCase(),
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _statusText(event),
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: () => _openEventDetail(event),
                icon: const Icon(Icons.more_vert, color: Color(0xFF6B7280)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            event.title,
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF111827),
              height: 1.15,
            ),
          ),
          const SizedBox(height: 8),
          _metaRow(Icons.location_on_outlined, event.location),
          const SizedBox(height: 6),
          _metaRow(Icons.access_time, event.dateTimeString),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          if (status == 'ongoing')
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openEventDetail(event),
                    icon: const Icon(Icons.fact_check_outlined, size: 16),
                    label: const Text('Điểm danh'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B2E86),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openStatistics(
                      event,
                      attendanceMode: true,
                    ),
                    icon: const Icon(Icons.bar_chart, size: 16),
                    label: const Text('Thống kê'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE5EDF9),
                      foregroundColor: const Color(0xFF0B2E86),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            )
          else if (status == 'upcoming')
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openEventDetail(event),
                    icon: const Icon(Icons.visibility_outlined, size: 16),
                    label: const Text('Xem chi tiết'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF374151),
                      side: const BorderSide(color: Color(0xFFD1D5DB)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openStatistics(
                      event,
                      attendanceMode: false,
                    ),
                    icon: const Icon(Icons.bar_chart, size: 16),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B2E86),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    label: const Text('Thống kê'),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openStatistics(event, attendanceMode: true),
                icon: const Icon(Icons.history),
                label: const Text('Xem lại báo cáo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE5E7EB),
                  foregroundColor: const Color(0xFF4B5563),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                  ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _metaRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF6B7280)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: const Color(0xFF4B5563),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showEventDetailSheet(
      Event event, AppStateService appState) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.84,
          minChildSize: 0.55,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 4,
                    margin: const EdgeInsets.only(top: 12, bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                      children: [
                        _buildEventCardHeader(event),
                        const SizedBox(height: 18),
                        _buildQuickInfoRow(event),
                        const SizedBox(height: 20),
                        _buildSectionTitle('Thông tin hoạt động'),
                        const SizedBox(height: 14),
                        _buildInfoCard(
                          Icons.access_time,
                          'Thời gian',
                          _formatDateTime(event.dateTime),
                        ),
                        const SizedBox(height: 12),
                        if (event.endDateTime != null) ...[
                          _buildInfoCard(
                            Icons.event_available,
                            'Kết thúc',
                            _formatDateTime(event.endDateTime!),
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (event.registerStartTime != null ||
                            event.registerEndTime != null) ...[
                          _buildInfoCard(
                            Icons.calendar_today,
                            'Đăng ký',
                            '${event.registerStartTime != null ? _formatDateTime(event.registerStartTime!) : 'Mở ngay'}${event.registerEndTime != null ? ' - ${_formatDateTime(event.registerEndTime!)}' : ''}',
                          ),
                          const SizedBox(height: 12),
                        ],
                        _buildInfoCard(
                          Icons.location_on,
                          'Địa điểm',
                          event.location.isNotEmpty ? event.location : 'Chưa có',
                        ),
                        const SizedBox(height: 12),
                        _buildInfoCard(
                          Icons.verified,
                          'Loại hoạt động',
                          event.isRequired ? 'Bắt buộc' : 'Tự nguyện',
                        ),
                        const SizedBox(height: 12),
                        _buildInfoCard(
                          Icons.people,
                          'Số lượng tham gia',
                          event.hasParticipantLimit
                              ? '${event.approvedCount}/${event.maxParticipants} đoàn viên'
                              : 'Không giới hạn',
                        ),
                        const SizedBox(height: 20),
                        _buildSectionTitle('Mô tả'),
                        const SizedBox(height: 12),
                        _buildInfoCard(
                          Icons.description,
                          'Nội dung',
                          event.description.isNotEmpty
                              ? event.description
                              : 'Chưa có mô tả',
                        ),
                        const SizedBox(height: 26),
                      ],
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(sheetContext);
                                _registerOfficer(event, appState);
                              },
                              icon: const Icon(Icons.event_available),
                              label: const Text('Đăng ký tham gia'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(sheetContext);
                                _openRegisterDialog(event, appState);
                              },
                              icon: const Icon(Icons.group_add),
                              label: const Text('Đăng ký đoàn viên'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(color: AppColors.primary),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEventCardHeader(Event event) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          if (event.imageUrl != null && event.imageUrl!.trim().isNotEmpty)
            Image.network(
              ApiService.resolveMediaUrl(event.imageUrl) ?? event.imageUrl!,
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 220,
                color: const Color(0xFFF1F5F9),
                child: const Center(child: Icon(Icons.broken_image)),
              ),
            )
          else
            Container(
              height: 220,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.event,
                  size: 72,
                  color: Colors.white,
                ),
              ),
            ),
          Container(
            height: 220,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color.fromARGB(31, 0, 0, 0),
                  const Color.fromARGB(13, 0, 0, 0),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(230, 255, 255, 255),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    event.title,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickInfoRow(Event event) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thời gian',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatDateTime(event.dateTime),
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tham gia',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  event.hasParticipantLimit
                      ? '${event.approvedCount}/${event.maxParticipants}'
                      : 'Không giới hạn',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.spaceGrotesk(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value,
      {Widget? trailing}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFF8FAFC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(10, 0, 0, 0),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 22,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildEventImage(String? imageUrl) {
    final fallback = Container(
      height: 220,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF17A2B8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.all(Radius.circular(18)),
      ),
      child: const Center(
        child: Icon(
          Icons.event,
          size: 80,
          color: Colors.white,
        ),
      ),
    );

    if (imageUrl == null || imageUrl.isEmpty) {
      return fallback;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Image.network(
        ApiService.resolveMediaUrl(imageUrl) ?? imageUrl,
        height: 220,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }


  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
