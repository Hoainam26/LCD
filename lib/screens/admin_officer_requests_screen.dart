import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state_service.dart';
import '../services/officer_event_registration_service.dart';
import '../widgets/officer_event_request_item.dart';

class AdminOfficerRequestsScreen extends StatefulWidget {
  AdminOfficerRequestsScreen({super.key});

  @override
  State<AdminOfficerRequestsScreen> createState() => _AdminOfficerRequestsScreenState();
}

class _AdminOfficerRequestsScreenState extends State<AdminOfficerRequestsScreen> {
  List<OfficerEventRegistrationRequest> _requests = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final requests = await OfficerEventRegistrationService.getAllRequests();
      setState(() {
        _requests = requests
            .where((request) => request.status == 'pending')
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Không thể tải danh sách yêu cầu: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _reviewRequest(String requestId, String status, {String? note}) async {
    try {
      final result = await OfficerEventRegistrationService.updateStatus(
        requestId: requestId,
        status: status,
        reviewedBy: 'admin',
        reviewNote: status == 'approved'
            ? 'Admin đã duyệt yêu cầu đăng ký.'
            : 'Admin từ chối yêu cầu đăng ký.',
      );

      if (result['success'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message']?.toString() ?? 'Duyệt thất bại')),
        );
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã ${status == 'approved' ? 'duyệt' : 'từ chối'} yêu cầu')),
      );
      
      // Refresh events and registration status to ensure immediate update for members
      final appState = Provider.of<AppStateService>(context, listen: false);
      await appState.refreshEvents();
      if (!mounted) return;
      await appState.refreshMyEventRegistrations();
      if (!mounted) return;
      await _loadRequests();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi kết nối: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yêu cầu đăng ký từ cán bộ đoàn'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRequests,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadRequests,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : _requests.isEmpty
                  ? const Center(child: Text('Không có yêu cầu nào'))
                  : ListView.builder(
                      itemCount: _requests.length,
                      itemBuilder: (context, index) {
                        final request = _requests[index];
                        return OfficerEventRequestItem(
                          request: request,
                          onApprove: () => _reviewRequest(request.id, 'approved'),
                          onReject: () => _showRejectDialog(request.id),
                        );
                      },
                    ),
    );
  }

  void _showRejectDialog(String requestId) {
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Từ chối yêu cầu'),
        content: TextField(
          controller: noteController,
          decoration: const InputDecoration(
            labelText: 'Lý do từ chối (tùy chọn)',
            hintText: 'Nhập lý do...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _reviewRequest(requestId, 'rejected', note: noteController.text);
            },
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );
  }
}
