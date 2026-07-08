import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/colors.dart';
import '../services/app_state_service.dart';
import '../services/officer_event_registration_service.dart';

class AdminOfficerEventRequestsScreen extends StatefulWidget {
  final String? initialRequestId;

  const AdminOfficerEventRequestsScreen({super.key, this.initialRequestId});

  @override
  State<AdminOfficerEventRequestsScreen> createState() =>
      _AdminOfficerEventRequestsScreenState();
}

class _AdminOfficerEventRequestsScreenState
    extends State<AdminOfficerEventRequestsScreen> {
  bool _isLoading = false;
  List<OfficerEventRegistrationRequest> _requests = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadData);
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final requests = await OfficerEventRegistrationService.getAllRequests();
    if (!mounted) return;
    setState(() {
      _requests = requests
          .where((request) => request.status == 'pending')
          .toList();
      _isLoading = false;
    });
  }

  Future<void> _review(
    OfficerEventRegistrationRequest request,
    String status,
  ) async {
    final result = await OfficerEventRegistrationService.updateStatus(
      requestId: request.id,
      status: status,
      reviewedBy: 'admin',
      reviewNote: status == 'approved'
          ? 'Admin đã duyệt yêu cầu đăng ký.'
          : 'Admin từ chối yêu cầu đăng ký.',
    );

    if (result['success'] != true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']?.toString() ?? 'Duyệt thất bại')),
      );
      return;
    }

    if (!mounted) return;
    final appState = Provider.of<AppStateService>(context, listen: false);
    // Refresh events and registration status for all members to ensure immediate update
    await appState.refreshEvents();
    if (!mounted) return;
    // Explicitly refresh registration statuses to ensure members see the update
    await appState.refreshMyEventRegistrations();
    if (!mounted) return;
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Duyệt đăng ký từ cán bộ'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: _requests.isEmpty
                    ? [
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                            child: Text('Chưa có yêu cầu nào từ cán bộ đoàn.'),
                          ),
                        ),
                      ]
                    : _requests
                        .map(
                          (request) => _buildRequestCard(request),
                        )
                        .toList(),
              ),
            ),
    );
  }

  Widget _buildRequestCard(OfficerEventRegistrationRequest request) {
    final isPending = request.status == 'pending';
    final isHighlighted = widget.initialRequestId == request.id;

    final statusColor = switch (request.status) {
      'approved' => Colors.green,
      'rejected' => Colors.red,
      _ => Colors.orange,
    };

    final statusLabel = switch (request.status) {
      'approved' => 'Đã duyệt',
      'rejected' => 'Từ chối',
      _ => 'Chờ duyệt',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isHighlighted
              ? AppColors.primary
              : statusColor.withOpacity(0.25),
          width: isHighlighted ? 1.8 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  request.eventTitle,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Cán bộ: ${request.officerName} (${request.officerUnit})'),
          Text('Số đoàn viên đăng ký: ${request.memberIds.length}'),
          if (request.memberNames.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Danh sách: ${request.memberNames.join(', ')}'),
            ),
          if (request.note != null && request.note!.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Ghi chú cán bộ: ${request.note!}'),
            ),
          if (request.reviewNote != null && request.reviewNote!.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Phản hồi admin: ${request.reviewNote!}'),
            ),
          if (isPending) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _review(request, 'rejected'),
                    icon: const Icon(Icons.close),
                    label: const Text('Từ chối'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _review(request, 'approved'),
                    icon: const Icon(Icons.check),
                    label: const Text('Duyệt'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
