import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../constants/colors.dart';
import '../models/event_model.dart';
import '../models/user_item.dart';
import '../services/api_service.dart';
import '../services/app_state_service.dart';
import '../services/officer_event_registration_service.dart';

class OfficerEventDetailScreen extends StatefulWidget {
  final Event event;

  const OfficerEventDetailScreen({super.key, required this.event});

  @override
  State<OfficerEventDetailScreen> createState() =>
      _OfficerEventDetailScreenState();
}

class _OfficerEventDetailScreenState extends State<OfficerEventDetailScreen> {
  late Event _event;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _event = widget.event;
    _loadActivity();
  }

  Future<void> _loadActivity() async {
    setState(() => _isLoading = true);
    final result = await ApiService.getActivityById(widget.event.id);
    if (!mounted) return;

    final data = _extractMap(result);
    if (data != null) {
      setState(() {
        _event = Event.fromApi(data);
      });
    }

    setState(() => _isLoading = false);
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

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}, ${_formatDate(dt)}';
  }

  bool _isOfficerLike(UserItem user) {
    final position = user.position?.toLowerCase() ?? '';
    return position.contains('bi thu') ||
        position.contains('pho bi thu') ||
        position.contains('can bo') ||
        position.contains('staff') ||
        position.contains('bi thu') ||
        position.contains('pho');
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

    return appState.members.where((m) {
      if (m.role != 'member') return false;
      if (_isOfficerLike(m)) return false;
      if (managedUnit.isEmpty) return true;
      return (m.unitName ?? '').trim() == managedUnit;
    }).toList();
  }

  Future<void> _registerOfficer(AppStateService appState) async {
    final result = await ApiService.registerEvent(_event.id.toString());
    if (!mounted) return;

    if (result['code'] == 200) {
      _showSnack('Đăng ký tham gia thành công');
      await appState.refreshEvents();
      await _loadActivity();
      return;
    }

    _showSnack(result['message'] ?? 'Không thể đăng ký hoạt động');
  }

  Future<void> _unregisterOfficer(AppStateService appState) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy đăng ký'),
        content: const Text('Bạn có chắc muốn hủy đăng ký hoạt động này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Không'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            child: const Text('Hủy đăng ký'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await appState.unregisterFromEvent(_event.id);
    if (!mounted) return;
    await _loadActivity();

    _showSnack(success ? 'Đã hủy đăng ký' : 'Hủy đăng ký thất bại');
  }

  Future<void> _checkInOfficer(AppStateService appState) async {
    final memberId = (appState.currentUser?['id'] ?? '').toString();
    if (memberId.isEmpty) {
      _showSnack('Không xác định được tài khoản để tham gia hoạt động');
      return;
    }

    final result = await ApiService.checkInMember(
      eventId: _event.id,
      memberId: memberId,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      _showSnack('Tham gia hoạt động thành công');
      await appState.refreshEvents();
      await _loadActivity();
      return;
    }

    _showSnack(result['message'] ?? 'Tham gia hoạt động thất bại');
  }

  Future<void> _submitOfficerAttendance(AppStateService appState) async {
    if (appState.isEventRegistered(_event.id)) {
      await _checkInOfficer(appState);
      return;
    }

    await _registerAndJoinOfficer(appState);
  }

  Future<void> _registerAndJoinOfficer(AppStateService appState) async {
    final registerResult = await ApiService.registerEvent(_event.id.toString());
    if (!mounted) return;

    if (registerResult['code'] != 200) {
      _showSnack(registerResult['message'] ?? 'Không thể đăng ký hoạt động');
      return;
    }

    await appState.refreshEvents();
    await _loadActivity();
    if (!mounted) return;

    await _checkInOfficer(appState);
  }

  Future<void> _openRegisterDialog(AppStateService appState) async {
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
                    const Text(
                      'Đăng ký đoàn viên',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(_event.title, style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 230,
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
      eventId: _event.id,
      eventTitle: _event.title,
      officerId: officerId,
      officerName: officerName,
      officerUnit: officerUnit,
      memberIds: selectedMembers.map((m) => m.id.toString()).toList(),
      memberNames: selectedMembers.map((m) => m.fullName).toList(),
      note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
      invite: true,
    );

    if (!mounted) return;
    _showSnack('Đã gửi lời mời cho đoàn viên.');
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateService>(
      builder: (context, appState, _) {
        final event = appState.events.firstWhere(
          (e) => e.id == widget.event.id,
          orElse: () => _event,
        );

        final displayEvent = _isLoading ? _event : event;
        final now = DateTime.now();
        final isRegistered = appState.isEventRegistered(displayEvent.id);
        final isCheckedIn = appState.isEventCheckedIn(displayEvent.id);
        final canJoinActivity = !displayEvent.hasEnded &&
          (now.isAfter(displayEvent.dateTime) ||
            now.isAtSameMomentAs(displayEvent.dateTime));
        final isOngoing = displayEvent.isOngoing;
        final canRegister = !isRegistered &&
            displayEvent.isRegistrationOpen &&
            !displayEvent.isFull &&
            !displayEvent.hasEnded;
        final showRegisterActions = !displayEvent.hasEnded &&
            (!isOngoing || displayEvent.isRegistrationOpen);
        final canUnregister = isRegistered && !displayEvent.hasEnded && !displayEvent.isClosed;
        final registerButtonLabel = isRegistered
            ? 'Đã đăng ký'
            : canRegister
                ? 'Đăng ký tham gia'
                : 'Đã đóng đăng ký';
        final showMemberRegisterButton = !displayEvent.isRequired && showRegisterActions;

        return Scaffold(
          backgroundColor: AppColors.backgroundColor,
          appBar: AppBar(
            title: Text(
              'Chi tiết hoạt động',
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            backgroundColor: Colors.white,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
            actions: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.share_outlined),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 170),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHero(displayEvent),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _quickCard(
                        icon: Icons.calendar_today_outlined,
                        title: 'THỜI GIAN',
                        value: _formatDate(displayEvent.dateTime),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _quickCard(
                        icon: Icons.people_alt_outlined,
                        title: 'THAM GIA',
                        value: displayEvent.hasParticipantLimit
                            ? '${displayEvent.approvedCount}/${displayEvent.maxParticipants}'
                            : 'Không giới hạn',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Thông tin hoạt động',
                  style: GoogleFonts.manrope(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 10),
                _infoCard(
                  icon: Icons.watch_later_outlined,
                  label: 'Thời gian bắt đầu',
                  value: _formatDateTime(displayEvent.dateTime),
                ),
                const SizedBox(height: 10),
                if (displayEvent.endDateTime != null)
                  _infoCard(
                    icon: Icons.event_busy_outlined,
                    label: 'Thời gian kết thúc',
                    value: _formatDateTime(displayEvent.endDateTime!),
                    iconColor: const Color(0xFFDC2626),
                    iconBg: const Color(0xFFFEE2E2),
                  ),
                const SizedBox(height: 10),
                _infoCard(
                  icon: displayEvent.isRequired ? Icons.verified_outlined : Icons.volunteer_activism_outlined,
                  label: 'Loại hoạt động',
                  value: displayEvent.isRequired ? 'Bắt buộc' : 'Tự nguyện',
                  iconColor: displayEvent.isRequired ? const Color(0xFFDC2626) : const Color(0xFF2563EB),
                  iconBg: displayEvent.isRequired ? const Color(0xFFFEE2E2) : const Color(0xFFEFF6FF),
                ),
                const SizedBox(height: 16),
                Text(
                  'Mô tả sự kiện',
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Text(
                    displayEvent.description.isEmpty
                        ? 'Chưa có mô tả hoạt động.'
                        : displayEvent.description,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: canUnregister
                  ? Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _unregisterOfficer(appState),
                            icon: const Icon(Icons.close),
                            label: const Text('Hủy đăng ký'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFDC2626),
                              side: const BorderSide(color: Color(0xFFDC2626)),
                              backgroundColor: const Color(0xFFFEE2E2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    )
                  : displayEvent.isRequired && isRegistered
                      ? Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFDC2626), width: 1),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.verified_outlined, color: Color(0xFFDC2626), size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Hoạt động bắt buộc - Bạn đã được đăng ký tham gia',
                                  style: GoogleFonts.manrope(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFDC2626),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : showRegisterActions
                      ? Row(
                          children: [
                            if (showMemberRegisterButton)
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _openRegisterDialog(appState),
                                  icon: const Icon(Icons.group_add_outlined),
                                  label: const Text('Đăng ký đoàn viên'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF1D4ED8),
                                    side: const BorderSide(color: Color(0xFFBFDBFE)),
                                    backgroundColor: const Color(0xFFEFF6FF),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                ),
                              ),
                            if (showMemberRegisterButton) const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: canRegister
                                    ? () => _registerOfficer(appState)
                                    : null,
                                icon: const Icon(Icons.how_to_reg),
                                label: Text(registerButtonLabel),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0B2E86),
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: const Color(0xFFCBD5E1),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                          ],
                        )
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: isCheckedIn
                                ? null
                                : () => _submitOfficerAttendance(appState),
                            icon: Icon(
                              isCheckedIn
                                  ? Icons.check_circle_outline
                                  : Icons.fact_check_outlined,
                            ),
                            label: Text(
                              isCheckedIn ? 'Đã điểm danh' : 'Điểm danh',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0B2E86),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: const Color(0xFFCBD5E1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHero(Event event) {
    final image = _buildEventImage(event.imageUrl);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          SizedBox(height: 192, width: double.infinity, child: image),
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.fromARGB(40, 0, 0, 0),
                    Color.fromARGB(80, 0, 0, 0),
                    Color.fromARGB(180, 0, 0, 0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D4ED8),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    'KỸ THUẬT & CÔNG NGHỆ',
                    style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  event.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    height: 1.08,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.white),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        event.location,
                        style: GoogleFonts.manrope(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventImage(String? imageUrl) {
    final fallback = Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF0EA5E9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.event, color: Colors.white, size: 72),
      ),
    );

    final resolved = ApiService.resolveMediaUrl(imageUrl);
    if (resolved == null || resolved.isEmpty) {
      return fallback;
    }

    if (resolved.startsWith('http')) {
      return Image.network(
        resolved,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      );
    }

    return Image.asset(
      resolved,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallback,
    );
  }

  Widget _quickCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF1D4ED8)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 9,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String label,
    required String value,
    Color iconColor = const Color(0xFF1D4ED8),
    Color iconBg = const Color(0xFFDBEAFE),
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Icon(icon, size: 15, color: iconColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
