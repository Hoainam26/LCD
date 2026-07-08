import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/colors.dart';
import '../models/event_model.dart';
import '../services/app_state_service.dart';
import 'event_detail_member_screen.dart';

class EventHistoryScreen extends StatelessWidget {
  const EventHistoryScreen({super.key});

  String _statusLabel(Event event, AppStateService appState) {
    if (!appState.isEventRegistered(event.id)) {
      return 'Chưa tham gia';
    }
    if (appState.isEventCheckedIn(event.id)) {
      return 'Đã điểm danh';
    }
    if (event.isOngoing) return 'Đang diễn ra';
    if (event.isUpcoming) return 'Sắp tới';
    if (event.isClosed || event.hasEnded) return 'Đã kết thúc';
    return 'Đã tham gia';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateService>(
      builder: (context, appState, _) {
        final memberId = appState.currentUser?['id']?.toString() ?? '';
        final historyEvents = appState.events
            .where((event) => appState.isEventRegistered(event.id))
            .toList()
          ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

        return Scaffold(
          backgroundColor: AppColors.backgroundColor,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: AppColors.surfaceColor,
            foregroundColor: AppColors.textPrimary,
            title: const Text('Lịch sử hoạt động'),
          ),
          body: historyEvents.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.history, size: 72, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Bạn chưa có hoạt động cũ nào đã tham gia.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: historyEvents.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final event = historyEvents[index];
                    return _buildHistoryTile(context, event, memberId, appState);
                  },
                ),
        );
      },
    );
  }

  Widget _buildHistoryTile(
    BuildContext context,
    Event event,
    String memberId,
    AppStateService appState,
  ) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EventDetailMemberScreen(
                event: event,
                memberId: memberId,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                event.dateTimeString,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 6),
              Text(
                event.location,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _statusLabel(event, appState),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
