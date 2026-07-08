import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../constants/colors.dart';
import '../models/event_model.dart';
import '../services/api_service.dart';
import '../services/app_state_service.dart';
import '../services/officer_event_registration_service.dart';
import 'activity_statistics_screen.dart';

class EventParticipantsScreen extends StatefulWidget {
  final Event event;

  const EventParticipantsScreen({super.key, required this.event});

  @override
  State<EventParticipantsScreen> createState() =>
      _EventParticipantsScreenState();
}

class _EventParticipantsScreenState extends State<EventParticipantsScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  List<dynamic> _participants = [];
  bool _isAddingMembers = false;
  bool _isLoadingOfficerRequests = false;
  List<OfficerEventRegistrationRequest> _officerRequests = [];
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _loadParticipants();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadParticipants() async {
    setState(() => _isLoading = true);
    final items = await ApiService.getEventParticipants(widget.event.id);
    if (!mounted) return;
    setState(() {
      _participants = items;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = _participants.length;
    final attended =
        _participants.where((p) => _normalizeStatus(p) == 'attended').length;
    final registered =
        _participants.where((p) => _normalizeStatus(p) == 'registered').length;
    final absent =
        _participants.where((p) => _normalizeStatus(p) == 'absent').length;
    final baseTheme = Theme.of(context);
    final textTheme = GoogleFonts.manropeTextTheme(baseTheme.textTheme);

    return Theme(
      data: baseTheme.copyWith(textTheme: textTheme),
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: AppBar(
          title: Text(
            'Điểm danh hoạt động',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          backgroundColor: AppColors.surfaceColor,
          foregroundColor: AppColors.textPrimary,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(28),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.event.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'Thêm đăng ký',
              onPressed: _isAddingMembers ? null : _openAddMembers,
              icon: _isAddingMembers
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.group_add),
            ),
            IconButton(
              tooltip: 'Thống kê',
              onPressed: _openStatistics,
              icon: const Icon(Icons.bar_chart),
            ),
            IconButton(
              tooltip: 'Yêu cầu từ cán bộ đoàn',
              onPressed: _openOfficerRequests,
              icon: _isLoadingOfficerRequests
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.assignment_turned_in),
            ),
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF5F7FF), Color(0xFFFDFEFF)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              final slide = Tween<Offset>(
                begin: const Offset(0, 0.02),
                end: Offset.zero,
              ).animate(animation);
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(position: slide, child: child),
              );
            },
            child: _isLoading
                ? _buildLoadingState(key: const ValueKey('loading'))
                : _buildLoadedState(
                    total: total,
                    registered: registered,
                    attended: attended,
                    absent: absent,
                    key: const ValueKey('loaded'),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadedState({
    required int total,
    required int registered,
    required int attended,
    required int absent,
    Key? key,
  }) {
    return RefreshIndicator(
      key: key,
      onRefresh: _loadParticipants,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSummary(total, registered, attended, absent),
          const SizedBox(height: 16),
          if (_participants.isEmpty)
            _buildEmptyState()
          else
            ..._participants.map((item) => _buildParticipantCard(item)),
        ],
      ),
    );
  }

  Widget _buildLoadingState({Key? key}) {
    return ListView(
      key: key,
      padding: const EdgeInsets.all(16),
      children: [
        _buildSkeletonSummary(),
        const SizedBox(height: 16),
        _buildSkeletonParticipantCard(),
        const SizedBox(height: 12),
        _buildSkeletonParticipantCard(),
      ],
    );
  }

  Widget _buildSummary(
    int total,
    int registered,
    int attended,
    int absent,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 520 ? 4 : 2;
        final ratio = columns == 4 ? 2.3 : 1.8;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceColor,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                blurRadius: 10,
                offset: Offset(0, 4),
                color: Colors.black12,
              ),
            ],
          ),
          child: GridView.count(
            crossAxisCount: columns,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: ratio,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildSummaryItem('Tổng', total, AppColors.primary, Icons.groups),
              _buildSummaryItem(
                'Đã đăng ký',
                registered,
                AppColors.info,
                Icons.how_to_reg,
              ),
              _buildSummaryItem(
                'Tham gia',
                attended,
                AppColors.success,
                Icons.check_circle,
              ),
              _buildSummaryItem(
                'Vắng',
                absent,
                AppColors.danger,
                Icons.cancel,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryItem(
    String label,
    int value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.group_off, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            'Chưa có đăng ký nào',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantCard(Map<String, dynamic> participant) {
    final user = (participant['member'] ??
        participant['user'] ??
        participant['User'] ??
        {}) as Map<String, dynamic>;
    final fullName = user['fullName']?.toString() ??
        user['full_name']?.toString() ??
        'Đoàn viên';
    final email =
        user['email']?.toString() ?? participant['email']?.toString() ?? '';
    final phone =
        user['phone']?.toString() ?? user['phoneNumber']?.toString() ?? '';
    final memberId = _getMemberId(participant);
    final status = _normalizeStatus(participant);
    final checkInAt = participant['check_in_at']?.toString() ??
        participant['checkInAt']?.toString();
    final checkOutAt = participant['check_out_at']?.toString() ??
        participant['checkOutAt']?.toString();
    final statusColor = _statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(
                      fullName.isNotEmpty ? fullName.substring(0, 1) : '?',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (email.isNotEmpty)
                          Text(
                            email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  _buildStatusMenu(participant, status, statusColor),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (phone.isNotEmpty)
                    _buildInfoChip(Icons.phone, phone, AppColors.info),
                  if (checkInAt != null)
                    _buildInfoChip(
                      Icons.login,
                      'Check-in ${_formatDate(checkInAt)}',
                      AppColors.success,
                    ),
                  if (checkOutAt != null)
                    _buildInfoChip(
                      Icons.logout,
                      'Check-out ${_formatDate(checkOutAt)}',
                      AppColors.warning,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (status == 'pending')
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _updateStatus(participant, 'registered'),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Duyệt'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _updateStatus(participant, 'canceled'),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Từ chối'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        side: BorderSide(color: AppColors.danger),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                )
              else if (memberId != null)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _checkIn(memberId),
                      icon: const Icon(Icons.login, size: 16),
                      label: const Text('Check-in'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _checkOut(memberId),
                      icon: const Icon(Icons.logout, size: 16),
                      label: const Text('Check-out'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        side: BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              _buildStatusMenu(participant, status, statusColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusMenu(
    Map<String, dynamic> participant,
    String status,
    Color statusColor,
  ) {
    return PopupMenuButton<String>(
      onSelected: (value) => _updateStatus(participant, value),
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'registered', child: Text('Đã đăng ký')),
        PopupMenuItem(value: 'attended', child: Text('Đã tham gia')),
        PopupMenuItem(value: 'absent', child: Text('Vắng')),
        PopupMenuItem(value: 'canceled', child: Text('Hủy')),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          _statusLabel(status),
          style: TextStyle(fontSize: 11, color: statusColor),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(fontSize: 11, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonSummary() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 520 ? 4 : 2;
        final ratio = columns == 4 ? 2.3 : 1.8;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceColor,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                blurRadius: 10,
                offset: Offset(0, 4),
                color: Colors.black12,
              ),
            ],
          ),
          child: GridView.count(
            crossAxisCount: columns,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: ratio,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: List.generate(4, (_) => _buildSkeletonBox(height: 50)),
          ),
        );
      },
    );
  }

  Widget _buildSkeletonParticipantCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            children: [
              _buildSkeletonBox(width: 40, height: 40, radius: 12),
              const SizedBox(width: 12),
              Expanded(child: _buildSkeletonBox(height: 14)),
              const SizedBox(width: 12),
              _buildSkeletonBox(width: 60, height: 20, radius: 999),
            ],
          ),
          const SizedBox(height: 10),
          _buildSkeletonBox(height: 12),
          const SizedBox(height: 6),
          _buildSkeletonBox(width: 180, height: 12),
          const SizedBox(height: 12),
          _buildSkeletonBox(width: 220, height: 32, radius: 10),
        ],
      ),
    );
  }

  Widget _buildSkeletonBox({
    double width = double.infinity,
    double height = 12,
    double radius = 8,
  }) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final base = const Color(0xFFE5E7EB);
        final highlight = const Color(0xFFF3F4F6);
        final color = Color.lerp(base, highlight, _pulseController.value)!;
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(radius),
          ),
        );
      },
    );
  }

  Future<void> _updateStatus(
      Map<String, dynamic> participant, String status) async {
    final userId = _getMemberId(participant);
    if (userId == null) return;

    final result = await ApiService.updateEventParticipantStatus(
      eventId: widget.event.id,
      userId: userId,
      status: status,
    );

    if (!mounted) return;
    if (result['success'] == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']?.toString() ?? 'Cập nhật thất bại'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Refresh app state to update member's registration status immediately
    final appState = Provider.of<AppStateService>(context, listen: false);
    await appState.refreshMyEventRegistrations();
    if (!mounted) return;
    
    await _loadParticipants();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã cập nhật trạng thái')),
    );
  }

  Future<void> _loadOfficerRequests() async {
    setState(() => _isLoadingOfficerRequests = true);
    final allRequests = await OfficerEventRegistrationService.getAllRequests();
    if (!mounted) return;
    setState(() {
      _officerRequests = allRequests
          .where((request) => request.eventId == widget.event.id)
          .where((request) => request.status == 'pending')
          .toList();
      _isLoadingOfficerRequests = false;
    });
  }

  Future<void> _openOfficerRequests() async {
    final appState = Provider.of<AppStateService>(context, listen: false);
    final currentRole =
        (appState.currentUser?['role'] ?? '').toString().toLowerCase();
    await _loadOfficerRequests();
    if (!mounted) return;
    if (_officerRequests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có yêu cầu nào từ cán bộ đoàn.')),
      );
      return;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Yêu cầu đăng ký cán bộ đoàn',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _officerRequests.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final request = _officerRequests[index];
                    return Card(
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              request.eventTitle,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('Cán bộ: ${request.officerName}'),
                            const SizedBox(height: 6),
                            Text(
                                'Đoàn viên: ${request.memberNames.join(', ')}'),
                            if (request.note != null &&
                                request.note!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text('Ghi chú: ${request.note}'),
                            ],
                            const SizedBox(height: 12),
                            if (currentRole == 'admin')
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () async {
                                        final result =
                                            await OfficerEventRegistrationService
                                                .updateStatus(
                                          requestId: request.id,
                                          status: 'rejected',
                                          reviewedBy: 'admin',
                                          reviewNote: 'Từ chối yêu cầu',
                                        );
                                        if (!mounted) return;
                                        if (result['success'] != true) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(result['message']
                                                      ?.toString() ??
                                                  'Từ chối thất bại'),
                                            ),
                                          );
                                          return;
                                        }
                                        Navigator.pop(context);
                                        await _loadOfficerRequests();
                                        await _loadParticipants();
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                      child: const Text('Từ chối'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        final result =
                                            await OfficerEventRegistrationService
                                                .updateStatus(
                                          requestId: request.id,
                                          status: 'approved',
                                          reviewedBy: 'admin',
                                          reviewNote: 'Duyệt yêu cầu',
                                        );
                                        if (!mounted) return;
                                        if (result['success'] != true) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(result['message']
                                                      ?.toString() ??
                                                  'Duyệt thất bại'),
                                            ),
                                          );
                                          return;
                                        }
                                        Navigator.pop(context);
                                        await _loadOfficerRequests();
                                        await _loadParticipants();
                                      },
                                      child: const Text('Duyệt'),
                                    ),
                                  ),
                                ],
                              )
                            else
                              const Text(
                                'Chỉ admin mới có quyền duyệt yêu cầu này.',
                                style: TextStyle(color: Colors.redAccent),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openAddMembers() async {
    setState(() => _isAddingMembers = true);
    final appState = Provider.of<AppStateService>(context, listen: false);
    if (appState.members.isEmpty) {
      await appState.refreshMembers();
    }
    if (!mounted) return;
    setState(() => _isAddingMembers = false);

    final existingIds = _participants
        .map<String?>((p) => _getMemberId(p))
        .whereType<String>()
        .toSet();
    final allMembers = appState.members;
    final availableMembers = allMembers
        .where((m) => !existingIds.contains(m.id.toString()))
        .toList();

    if (availableMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không còn đoàn viên nào để thêm.')),
      );
      return;
    }

    final selected = <String>{};
    final searchController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final keyword = searchController.text.trim().toLowerCase();
            final filtered = keyword.isEmpty
                ? availableMembers
                : availableMembers.where((m) {
                    return m.fullName.toLowerCase().contains(keyword) ||
                        m.email.toLowerCase().contains(keyword) ||
                        (m.studentCode ?? '').toLowerCase().contains(keyword);
                  }).toList();

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                    child: Row(
                      children: [
                        const Icon(Icons.group_add, color: AppColors.primary),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Thêm đoàn viên vào danh sách',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Tìm theo tên, email, MSSV',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (_) => setModalState(() {}),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 360,
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final member = filtered[index];
                        final id = member.id.toString();
                        final checked = selected.contains(id);
                        return CheckboxListTile(
                          value: checked,
                          onChanged: (_) {
                            setModalState(() {
                              if (checked) {
                                selected.remove(id);
                              } else {
                                selected.add(id);
                              }
                            });
                          },
                          title: Text(member.fullName),
                          subtitle: Text(
                            member.email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          secondary: const Icon(Icons.person_outline),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Hủy'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.check),
                            onPressed: selected.isEmpty
                                ? null
                                : () => Navigator.pop(ctx, selected.toList()),
                            label: Text('Thêm ${selected.length}'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((value) async {
      if (value is List<String> && value.isNotEmpty) {
        await _registerMembers(value);
      }
    });

    searchController.dispose();
  }

  Future<void> _registerMembers(List<String> memberIds) async {
    setState(() => _isAddingMembers = true);
    for (final id in memberIds) {
      await ApiService.registerEvent(widget.event.id, memberId: id);
    }
    if (!mounted) return;
    setState(() => _isAddingMembers = false);
    await _loadParticipants();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Đã thêm ${memberIds.length} đoàn viên vào danh sách')),
    );
  }

  void _openStatistics() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActivityStatisticsScreen(
          eventId: widget.event.id,
          title: widget.event.title,
          attendanceMode: true,
        ),
      ),
    );
  }

  String? _getMemberId(Map<String, dynamic> participant) {
    final user =
        participant['member'] ?? participant['user'] ?? participant['User'];
    return participant['memberId']?.toString() ??
        participant['member_id']?.toString() ??
        participant['user_id']?.toString() ??
        (user is Map ? user['id']?.toString() : null);
  }

  Future<void> _checkIn(String memberId) async {
    final result = await ApiService.checkInMember(
      eventId: widget.event.id,
      memberId: memberId,
    );

    if (!mounted) return;
    if (result['success'] == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']?.toString() ?? 'Check-in thất bại'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await _loadParticipants();
  }

  Future<void> _checkOut(String memberId) async {
    final result = await ApiService.checkOutMember(
      eventId: widget.event.id,
      memberId: memberId,
    );

    if (!mounted) return;
    if (result['success'] == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']?.toString() ?? 'Check-out thất bại'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await _loadParticipants();
  }

  String _normalizeStatus(Map<String, dynamic> participant) {
    final raw = participant['status'] ??
        participant['attendanceStatus'] ??
        participant['attendance_status'];
    final text = raw?.toString().toLowerCase() ?? '';
    if (text == 'pending') {
      return 'pending';
    }
    if (['attended', 'checked_in', 'checkin', 'present'].contains(text)) {
      return 'attended';
    }
    if (['absent', 'missed'].contains(text)) {
      return 'absent';
    }
    if (['canceled', 'cancelled', 'rejected'].contains(text)) {
      return 'canceled';
    }
    return 'registered';
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Chờ duyệt';
      case 'attended':
        return 'Đã tham gia';
      case 'absent':
        return 'Vắng';
      case 'canceled':
        return 'Hủy';
      case 'registered':
      default:
        return 'Đã đăng ký';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'attended':
        return const Color(0xFF16A34A);
      case 'absent':
        return const Color(0xFFDC2626);
      case 'canceled':
        return Colors.grey;
      case 'registered':
      default:
        return const Color(0xFF2563EB);
    }
  }

  String _formatDate(String raw) {
    try {
      final date = DateTime.parse(raw);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }
}
