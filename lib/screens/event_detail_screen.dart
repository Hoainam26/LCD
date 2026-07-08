import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../constants/colors.dart';
import '../models/event_model.dart';
import '../services/api_service.dart';
import '../services/app_state_service.dart';
import 'activity_statistics_screen.dart';
import 'event_participants_screen.dart';

class EventDetailScreen extends StatefulWidget {
  final Event event;

  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Chi tiết hoạt động',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.surfaceColor,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Thống kê',
            onPressed: () => _openStatistics(_event),
            icon: const Icon(Icons.bar_chart),
          ),
        ],
      ),
      body: Consumer<AppStateService>(
        builder: (context, appState, _) {
          final event = appState.events.firstWhere(
            (e) => e.id == widget.event.id,
            orElse: () => widget.event,
          );
          final displayEvent = _isLoading ? _event : event;
          return _buildInfoTab(displayEvent);
        },
      ),
    );
  }

  Map<String, dynamic>? _extractMap(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    if (response['item'] is Map) {
      return Map<String, dynamic>.from(response['item'] as Map);
    }
    return null;
  }

  Widget _buildInfoTab(Event event) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 600),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHero(event),
            const SizedBox(height: 18),
            _buildSectionCard(
              title: 'Lịch trình',
              subtitle: 'Thời gian diễn ra hoạt động',
              child: Column(
                children: [
                  _buildInfoRow(Icons.calendar_today, 'Bắt đầu',
                      _formatDateTime(event.dateTime)),
                  if (event.endDateTime != null)
                    _buildInfoRow(Icons.event_available, 'Kết thúc',
                        _formatDateTime(event.endDateTime!)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _buildSectionCard(
              title: 'Thông tin hoạt động',
              subtitle: 'Mã, yêu cầu và địa điểm',
              child: Column(
                children: [
                  if (event.code != null && event.code!.isNotEmpty)
                    _buildInfoRow(Icons.tag, 'Mã hoạt động', event.code!),
                  _buildInfoRow(
                    Icons.verified,
                    'Loại hoạt động',
                    event.isRequired ? 'Bắt buộc' : 'Tự nguyện',
                  ),
                  _buildInfoRow(Icons.location_on, 'Địa điểm', event.location),
                  if (event.hasParticipantLimit)
                    _buildInfoRow(Icons.people, 'Số lượng',
                        '${event.maxParticipants} người'),
                  _buildInfoRow(Icons.person, 'Người tạo', event.createdBy),
                  _buildInfoRow(Icons.info_outline, 'Trạng thái',
                      _statusLabel(event)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _buildSectionCard(
              title: 'Mô tả',
              subtitle: 'Thông tin chi tiết về hoạt động',
              child: Text(
                event.description,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.6,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildPrimaryButton(
              icon: Icons.people_alt,
              label: 'Danh sách tham gia & điểm danh',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EventParticipantsScreen(event: event),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            _buildSecondaryButton(
              icon: Icons.bar_chart,
              label: 'Thống kê hoạt động',
              onPressed: () => _openStatistics(event),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(Event event) {
    final status = _statusLabel(event);
    final statusColor = _statusColor(event);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            left: -20,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      status,
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 16, color: Colors.white.withOpacity(0.9)),
                  const SizedBox(width: 8),
                  Text(
                    _formatDateTime(event.dateTime),
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.location_on,
                      size: 16, color: Colors.white.withOpacity(0.9)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      event.location,
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 20),
        label: Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, 48),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: AppColors.primary, size: 18),
      label: Text(
        label,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.primary),
        minimumSize: const Size(double.infinity, 46),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  void _openStatistics(Event event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActivityStatisticsScreen(
          eventId: event.id,
          title: event.title,
          attendanceMode: true,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.manrope(
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
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _statusLabel(Event event) {
    if (event.isClosed || event.hasEnded) return 'Đã kết thúc';
    if (event.isOngoing) return 'Đang diễn ra';
    return 'Sắp tới';
  }

  Color _statusColor(Event event) {
    if (event.isClosed || event.hasEnded) return Colors.white70;
    if (event.isOngoing) return AppColors.accent;
    return Colors.white;
  }
}
