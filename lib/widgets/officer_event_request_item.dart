import 'package:flutter/material.dart';
import '../services/officer_event_registration_service.dart';

class OfficerEventRequestItem extends StatelessWidget {
  final OfficerEventRegistrationRequest request;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const OfficerEventRequestItem({
    super.key,
    required this.request,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    request.eventTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusChip(),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Cán bộ gửi: ${request.officerName}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'Đoàn viên: ${request.memberNames.join(', ')}',
              style: const TextStyle(fontSize: 14),
            ),
            if (request.note != null && request.note!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Ghi chú: ${request.note}',
                style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
              ),
            ],
            if (request.reviewNote != null && request.reviewNote!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Ý kiến duyệt: ${request.reviewNote}',
                style: const TextStyle(fontSize: 14, color: Colors.blue),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Thời gian: ${request.createdAt.toLocal().toString().split('.')[0]}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (request.status == 'pending') ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: onReject,
                    child: const Text('Từ chối'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: onApprove,
                    child: const Text('Duyệt'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    Color color;
    String label;

    switch (request.status) {
      case 'approved':
        color = Colors.green;
        label = 'Đã duyệt';
        break;
      case 'rejected':
        color = Colors.red;
        label = 'Đã từ chối';
        break;
      default:
        color = Colors.orange;
        label = 'Chờ duyệt';
    }

    return Chip(
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
      padding: EdgeInsets.zero,
    );
  }
}
