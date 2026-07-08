import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../constants/colors.dart';
import '../models/event_model.dart';
import '../services/api_service.dart';
import '../services/app_state_service.dart';

class EventDetailMemberScreen extends StatefulWidget {
  final Event event;
  final String memberId;

  const EventDetailMemberScreen({
    super.key,
    required this.event,
    required this.memberId,
  });

  @override
  State<EventDetailMemberScreen> createState() =>
      _EventDetailMemberScreenState();
}

class _DetailTileData {
  final IconData icon;
  final String label;
  final String value;

  const _DetailTileData(this.icon, this.label, this.value);
}

class _EventDetailMemberScreenState extends State<EventDetailMemberScreen> {
  late Event _currentEvent;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _currentEvent = widget.event;
    Future.microtask(() async {
      final appState = Provider.of<AppStateService>(context, listen: false);
      await appState.refreshMyEventRegistrations();
      _refreshEvent();
    });
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      if (!mounted) return;
      final appState = Provider.of<AppStateService>(context, listen: false);
      await appState.refreshMyEventRegistrations();
      if (!mounted) return;
      _refreshEvent();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _refreshEvent() {
    final appState = Provider.of<AppStateService>(context, listen: false);
    final updatedEvent = appState.events.firstWhere(
      (e) => e.id == widget.event.id,
      orElse: () => widget.event,
    );
    setState(() {
      _currentEvent = updatedEvent;
    });
  }

  String _getRegistrationStatusText(bool isRegistered) {
    return isRegistered ? 'Đã đăng ký' : 'Chưa đăng ký';
  }

  Color _getRegistrationStatusColor(bool isRegistered) {
    return isRegistered ? Colors.green : Colors.grey;
  }

  IconData _getRegistrationStatusIcon(bool isRegistered) {
    return isRegistered ? Icons.check_circle : Icons.info_outline;
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} lúc ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _registerForEvent(AppStateService appState) async {
    final noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.secondary, AppColors.accent],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.app_registration,
                              color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Đăng ký hoạt động',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Xác nhận thông tin trước khi gửi',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF1F5FF), Color(0xFFEFF6FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppColors.primary.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentEvent.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _formatDateTime(_currentEvent.dateTime),
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (_currentEvent.registerEndTime != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Đăng ký đến: ${_formatDateTime(_currentEvent.registerEndTime!)}',
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: noteController,
                      maxLines: 3,
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Ghi chú (tùy chọn)',
                        labelStyle: GoogleFonts.manrope(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                        hintText: 'Lý do tham gia, mong muốn...',
                        hintStyle: GoogleFonts.manrope(
                          fontSize: 12,
                          color: AppColors.textSecondary.withOpacity(0.7),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              'Hủy',
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: _buildGradientAction(
                            label: 'Xác nhận',
                            icon: Icons.check,
                            onPressed: () async {
                              Navigator.pop(context);
                              final note = noteController.text.trim();
                              final success = await appState.registerForEvent(
                                _currentEvent.id,
                                note: note.isEmpty ? null : note,
                              );
                              if (!mounted) return;
                              _refreshEvent();

                              // Refresh registration status from backend to check if admin approved
                              await appState.refreshMyEventRegistrations();
                              if (!mounted) return;

                              final status = appState
                                      .getEventRegistrationStatus(
                                          _currentEvent.id)
                                      ?.toLowerCase() ??
                                  '';

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success
                                        ? (status == 'pending'
                                            ? 'Đã gửi yêu cầu chờ duyệt'
                                            : 'Đăng ký thành công')
                                        : 'Đăng ký thất bại',
                                  ),
                                  backgroundColor: success
                                      ? AppColors.secondary
                                      : AppColors.danger,
                                  behavior: SnackBarBehavior.floating,
                                  margin: const EdgeInsets.all(16),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateService>(context);
    final registrationState = appState.getMyEventRegistration(_currentEvent.id);
    final registrationStatus =
        appState.getEventRegistrationStatus(_currentEvent.id) ??
            (appState.isEventRegistered(_currentEvent.id) ? 'registered' : '');
    final isRegistered = registrationStatus == 'registered';
    final isCheckedIn = appState.isEventCheckedIn(_currentEvent.id);
    final isInvited = registrationState?['invited'] == true;
    final hasEnded = _currentEvent.hasEnded || _currentEvent.isClosed;
    final canRegister = !isRegistered &&
      !_currentEvent.isRequired &&
      _currentEvent.isRegistrationOpen &&
      !_currentEvent.isFull &&
      !hasEnded &&
      isInvited;
    final canUnregister =
        isRegistered && !hasEnded && !_currentEvent.isClosed;
    final canCheckIn = isRegistered &&
        _currentEvent.isCheckInTimeActive &&
        !isCheckedIn &&
        !hasEnded;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F6FC),
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: const Color(0xFFF5F6FC),
        title: Text(
          'Chi tiết hoạt động',
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.share_outlined),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.bookmark_border),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailHero(_currentEvent),
                  const SizedBox(height: 14),
                  _buildDetailGrid(),
                  const SizedBox(height: 16),
                  if (hasEnded) ...[
                    _buildSectionTitle('Kết quả cá nhân'),
                    const SizedBox(height: 10),
                    _buildPersonalResultCard(isRegistered, isCheckedIn),
                    const SizedBox(height: 16),
                  ],
                  _buildSectionTitle('Chi tiết hoạt động'),
                  const SizedBox(height: 10),
                  _buildActivityDetailSection(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (canCheckIn)
                _buildPrimaryActionButton(
                  label: 'Tham gia hoạt động',
                  icon: Icons.assignment_turned_in,
                  onPressed: () => _checkInForEvent(appState),
                )
              else if (canRegister)
                _buildPrimaryActionButton(
                  label: 'Đăng ký tham gia ngay →',
                  icon: null,
                  onPressed: () => _registerForEvent(appState),
                )
              else if (canUnregister)
                _buildSecondaryActionButton(
                  label: 'Hủy đăng ký',
                  icon: Icons.close,
                  onPressed: () => _unregisterForEvent(appState),
                )
              else if (hasEnded)
                _buildEndedStatusChip(
                  isRegistered: isRegistered,
                  isCheckedIn: isCheckedIn,
                )
              else
                _buildStatusActionChip(
                  isRegistered: isRegistered,
                  isCheckedIn: isCheckedIn,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _unregisterForEvent(AppStateService appState) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy đăng ký'),
        content:
            const Text('Bạn có chắc muốn hủy đăng ký hoạt động này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Không'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hủy đăng ký'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await appState.unregisterFromEvent(_currentEvent.id);
    if (!mounted) return;
    _refreshEvent();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Đã hủy đăng ký' : 'Hủy đăng ký thất bại'),
        backgroundColor: success ? AppColors.secondary : AppColors.danger,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _checkInForEvent(AppStateService appState) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with gradient background
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Xác nhận tham gia hoạt động',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentEvent.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event details with icons
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.access_time,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'THỜI GIAN',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDateTime(_currentEvent.dateTime),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Location
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.location_on,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ĐỊA ĐIỂM',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _currentEvent.location ?? 'Chưa xác định',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Confirmation message
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.05),
                      border: Border.all(color: Colors.blue.withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Bạn xác nhận đã tham gia hoạt động này?',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Buttons
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Xác nhận',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Hủy',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    // Perform check-in
    final result = await ApiService.checkInMember(
      eventId: _currentEvent.id,
      memberId: appState.currentUser?['id']?.toString() ?? '',
    );

    if (!mounted) return;

    // Refresh registration status
    await appState.refreshMyEventRegistrations();
    if (!mounted) return;
    _refreshEvent();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result['success'] == true
              ? 'Điểm danh thành công!'
              : (result['message'] ?? 'Điểm danh thất bại, vui lòng thử lại'),
        ),
        backgroundColor: result['success'] == true ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
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

  Widget _buildDetailHero(Event event) {
    final status = _statusLabel();
    final statusColor = _statusColor();
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          SizedBox(
            height: 240,
            width: double.infinity,
            child: _buildEventImage(event.imageUrl),
          ),
          Container(
            height: 240,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.55),
                ],
              ),
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.95),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                status,
                style: GoogleFonts.manrope(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          // Date pill removed per UX request (show date in other places)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.55),
                  ],
                ),
              ),
              child: Text(
                event.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.manrope(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailGrid() {
    final detailItems = [
      _DetailTileData(Icons.access_time, 'Thời gian', _formatDateTime(_currentEvent.dateTime)),
      _DetailTileData(Icons.location_on_outlined, 'Địa điểm', _currentEvent.location),
      const _DetailTileData(Icons.workspace_premium_outlined, 'Quyền lợi', '+5 Điểm RL'),
      _DetailTileData(Icons.assignment_outlined, 'Phân loại', _currentEvent.isRequired ? 'Bắt buộc' : 'Tự nguyện'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 10.0;
        final isSingleColumn = constraints.maxWidth < 360;
        final tileWidth = isSingleColumn
            ? constraints.maxWidth
            : (constraints.maxWidth - spacing) / 2;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: detailItems
              .map(
                (item) => SizedBox(
                  width: tileWidth,
                  child: _buildDetailTile(item.icon, item.label, item.value),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildDetailTile(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  

  Widget _buildActivityDetailSection() {
    final description = _currentEvent.description.trim().isNotEmpty
        ? _currentEvent.description.trim()
        : 'Hoạt động được tổ chức nhằm tạo môi trường giao lưu, học tập và phát triển kỹ năng cho đoàn viên.';

    const programItems = [
      'Tổng kết hoạt động phong trào quý.',
      'Talkshow: Cơ hội nghề nghiệp trong kỷ nguyên AI.',
      'Hướng dẫn đăng ký tham gia các cuộc thi học thuật sắp tới.',
      'Giao lưu văn nghệ và teambuilding nhẹ giữa các chi đoàn.',
    ];

    final participationRequirement = _currentEvent.isRequired
        ? 'Đây là hoạt động bắt buộc, đoàn viên cần tham gia đầy đủ và điểm danh đúng thời gian quy định.'
        : 'Khuyến khích đoàn viên mặc đồng phục phù hợp, mang theo thẻ sinh viên và tham gia đầy đủ để được ghi nhận kết quả rèn luyện.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          description,
          style: GoogleFonts.manrope(
            fontSize: 15,
            height: 1.5,
            color: const Color(0xFF4B5563),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Nội dung chương trình:',
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        ...programItems.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 7),
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: Color(0xFF6B7280),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item,
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      height: 1.45,
                      color: const Color(0xFF4B5563),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Yêu cầu tham dự:',
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          participationRequirement,
          style: GoogleFonts.manrope(
            fontSize: 15,
            height: 1.5,
            color: const Color(0xFF4B5563),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalResultCard(bool isRegistered, bool isCheckedIn) {
    final title = isCheckedIn ? 'Đã tham gia' : isRegistered ? 'Đã đăng ký' : 'Không tham gia';
    final statusColor = isCheckedIn
        ? AppColors.success
        : isRegistered
            ? AppColors.warning
            : Colors.grey;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.04),
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
              Expanded(
                child: Text(
                  'Kết quả cá nhân',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.14),
                  border: Border.all(color: statusColor.withOpacity(0.35)),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _buildResultMetric('Điểm nhận', isCheckedIn ? '+5.0' : '0', Alignment.centerLeft)),
              _buildMetricDivider(),
              Expanded(child: _buildResultMetric('Vai trò', isCheckedIn ? 'Cộng tác viên' : '-', Alignment.center)),
              _buildMetricDivider(),
              Expanded(child: _buildResultMetric('Chứng nhận', isCheckedIn ? 'Đã cấp' : 'N/A', Alignment.centerRight)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricDivider() {
    return Container(
      width: 1,
      height: 40,
      color: const Color(0xFFE9ECF5),
      margin: const EdgeInsets.symmetric(horizontal: 10),
    );
  }

  Widget _buildResultMetric(String label, String value, Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 10,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryActionButton({
    required String label,
    required IconData? icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2D5AA0), Color(0xFF1D3D91)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              child: icon != null
                  ? ElevatedButton.icon(
                      onPressed: onPressed,
                      icon: Icon(icon, size: 18),
                      label: Text(
                        label,
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        shadowColor: Colors.transparent,
                        elevation: 0,
                      ),
                    )
                  : Center(
                      child: Text(
                        label,
                        style: GoogleFonts.manrope(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18, color: AppColors.danger),
        label: Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.danger,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFF2B8B5)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusActionChip({
    required bool isRegistered,
    required bool isCheckedIn,
  }) {
    final isMandatory = _currentEvent.isRequired && !isRegistered && !isCheckedIn;
    final color = isMandatory ? AppColors.warning : _getRegistrationStatusColor(isRegistered || isCheckedIn);
    final label = isCheckedIn
        ? 'Đã điểm danh'
      : isMandatory
        ? 'Hoạt động bắt buộc'
        : _getRegistrationActionLabel(isRegistered);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Icon(
            isMandatory ? Icons.verified_outlined : _getRegistrationStatusIcon(isRegistered || isCheckedIn),
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEndedStatusChip({
    required bool isRegistered,
    required bool isCheckedIn,
  }) {
    final label = _getEndedEventStatusLabel(isRegistered, isCheckedIn);
    final color = _getEndedEventStatusColor(isRegistered, isCheckedIn);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Icon(_getEndedEventStatusIcon(isRegistered, isCheckedIn), color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getEndedEventStatusLabel(bool isRegistered, bool isCheckedIn) {
    if (isCheckedIn) return 'Bạn đã tham gia hoạt động này';
    if (isRegistered) return 'Bạn đã đăng ký nhưng chưa điểm danh';
    return 'Bạn không tham gia hoạt động này';
  }

  Color _getEndedEventStatusColor(bool isRegistered, bool isCheckedIn) {
    if (isCheckedIn) return AppColors.success;
    if (isRegistered) return AppColors.warning;
    return Colors.grey;
  }

  IconData _getEndedEventStatusIcon(bool isRegistered, bool isCheckedIn) {
    if (isCheckedIn) return Icons.check_circle;
    if (isRegistered) return Icons.schedule;
    return Icons.block;
  }

  Widget _buildEventImage(String? imageUrl) {
    final fallback = Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF17A2B8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        color: Colors.black.withOpacity(0.04),
      ),
      child: Center(
        child: Icon(
          Icons.event,
          size: 64,
          color: Colors.white.withOpacity(0.3),
        ),
      ),
    );

    if (imageUrl == null || imageUrl.isEmpty) {
      return fallback;
    }

    final isNetwork = imageUrl.startsWith('http');
    if (isNetwork) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      );
    }

    return Image.asset(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallback,
    );
  }

  String _statusLabel() {
    if (_currentEvent.isClosed || _currentEvent.hasEnded) return 'Đã kết thúc';
    if (_currentEvent.isOngoing) return 'Đang diễn ra';
    return 'Sắp tới';
  }

  Color _statusColor() {
    if (_currentEvent.isClosed || _currentEvent.hasEnded) return Colors.grey;
    if (_currentEvent.isOngoing) return AppColors.warning;
    return AppColors.success;
  }

  String _getRegistrationActionLabel(bool isRegistered) {
    if (isRegistered) {
      return _getRegistrationStatusText(isRegistered);
    }
    if (_currentEvent.isRequired) {
      return 'Hoạt động bắt buộc';
    }
    return 'Chờ cán bộ đoàn đăng ký';
  }

  Widget _buildGradientAction({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.secondary, AppColors.accent],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
