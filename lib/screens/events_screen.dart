import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../constants/colors.dart';
import '../models/event_model.dart';
import '../services/app_state_service.dart';
import 'officer_event_registration_screen.dart';
import 'event_detail_member_screen.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  String _activeFilter = 'Tất cả';
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      if (!mounted) return;
      final appState = Provider.of<AppStateService>(context, listen: false);
      await appState.refreshMyEventRegistrations();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Consumer<AppStateService>(
        builder: (context, appState, _) {
          final events = _filteredEvents(appState);

          return RefreshIndicator(
            onRefresh: appState.refreshEvents,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  _buildHeader(),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFilterRow(),
                        const SizedBox(height: 24),
                        if (appState.isLoadingEvents)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (events.isEmpty)
                          _buildEmptyState()
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: events.length,
                            itemBuilder: (context, index) {
                              final event = events[index];
                              final isJoined =
                                  appState.isEventRegistered(event.id);
                              return _buildEventCard(
                                event,
                                isJoined,
                                appState,
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Hoạt động',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Tham gia các hoạt động của đoàn',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('Tất cả', _activeFilter == 'Tất cả'),
          _buildFilterChip('Sắp tới', _activeFilter == 'Sắp tới'),
          _buildFilterChip('Đã tham gia', _activeFilter == 'Đã tham gia'),
        ],
      ),
    );
  }

  List<Event> _filteredEvents(AppStateService appState) {
    final now = DateTime.now();
    final events = appState.events;

    switch (_activeFilter) {
      case 'Sắp tới':
        return events.where((e) => e.isActive).toList();
      case 'Đã tham gia':
        return events.where((e) => appState.isEventRegistered(e.id)).toList();
      default:
        return events;
    }
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          setState(() {
            _activeFilter = label;
          });
        },
        backgroundColor: const Color(0xFFF1F5F9),
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            'Chưa có hoạt động phù hợp',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(
    Event event,
    bool isJoined,
    AppStateService appState,
  ) {
    final currentRole =
        (appState.currentUser?['role'] ?? '').toString().toLowerCase();
    final isStaff = currentRole == 'staff' || currentRole == 'admin';
    final registrationStatus =
        appState.getEventRegistrationStatus(event.id) ?? '';
    final isRegistered = isJoined || registrationStatus == 'registered';
    final isPending = registrationStatus == 'pending';
    final isInvited =
        appState.getMyEventRegistration(event.id)?['invited'] == true;
    final statusLabel = _statusLabel(event);
    final statusColor = _statusColor(event);
    final canJoin = !isRegistered &&
        !isPending &&
        event.isRegistrationOpen &&
        !event.isFull &&
        !event.hasEnded &&
        (event.isRequired || isInvited);
    final joinLabel = isRegistered
        ? 'Đã đăng ký'
        : isPending
            ? 'Đang chờ duyệt'
            : event.isRegistrationOpen
                ? 'Đăng ký'
                : 'Đóng đăng ký';

    return InkWell(
      onTap: () => _openEventDetail(event, appState),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: AppColors.surfaceColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: Stack(
                children: [
                  _buildEventImage(event.imageUrl),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (event.code != null && event.code!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Mã: ${event.code}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Text(
                        _formatDate(event.dateTime),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.location_on,
                          size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          event.location,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    event.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.people, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      if (event.hasParticipantLimit)
                        Text(
                          'Tối đa ${event.maxParticipants} người',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        )
                      else
                        Text(
                          event.isRequired ? 'Bắt buộc' : 'Tự nguyện',
                          style: TextStyle(
                            fontSize: 12,
                            color: event.isRequired
                                ? AppColors.danger
                                : Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      const Spacer(),
                      if (isStaff)
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const OfficerEventRegistrationScreen(),
                                      ),
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    side: const BorderSide(
                                        color: AppColors.primary),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  child: const Text(
                                    'ĐK đoàn viên',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                          ),
                        )
                      else
                        ElevatedButton(
                          onPressed: canJoin
                              ? () => _handleJoin(appState, event)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                canJoin ? const Color(0xFF1E3A8A) : Colors.grey,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: Text(
                            joinLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
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
      ),
    );
  }

  String _statusLabel(Event event) {
    if (event.isClosed || event.hasEnded) return 'Đã kết thúc';
    if (event.isOngoing) return 'Đang diễn ra';
    return 'Sắp tới';
  }

  Color _statusColor(Event event) {
    if (event.isClosed || event.hasEnded) return Colors.grey;
    if (event.isOngoing) return Colors.orange;
    return Colors.green;
  }

  Widget _buildEventImage(String? imageUrl) {
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    if (!hasImage) {
      return Container(
        height: 200,
        color: Colors.grey[200],
        child: Icon(Icons.image, size: 48, color: Colors.grey[400]),
      );
    }

    final isNetwork = imageUrl!.startsWith('http');
    final image = isNetwork
        ? Image.network(
            imageUrl,
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: 200,
              color: Colors.grey[200],
              child: Icon(Icons.image, size: 48, color: Colors.grey[400]),
            ),
          )
        : Image.asset(
            imageUrl,
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: 200,
              color: Colors.grey[200],
              child: Icon(Icons.image, size: 48, color: Colors.grey[400]),
            ),
          );
    return image;
  }

  void _openEventDetail(Event event, AppStateService appState) {
    final memberId = appState.currentUser?['id']?.toString() ?? '';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventDetailMemberScreen(
          event: event,
          memberId: memberId,
        ),
      ),
    );
  }

  Future<void> _handleJoin(AppStateService appState, Event event) async {
    final success = await appState.registerForEvent(event.id);
    if (!mounted) return;

    // Refresh registration status from backend
    await appState.refreshMyEventRegistrations();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Đăng ký thành công' : 'Đăng ký thất bại',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
