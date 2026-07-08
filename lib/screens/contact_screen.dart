import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:typed_data';

import '../constants/colors.dart';
import '../services/api_service.dart';
import '../services/app_state_service.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedTopic = 'Hoạt động Đoàn';
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final List<_AttachmentItem> _attachments = [];
  List<Map<String, dynamic>> _responseMessages = [];
    List<Map<String, dynamic>> _sentMessages = [];
  bool _didPrefill = false;
  bool _isSubmitting = false;
  bool _isLoadingResponses = false;
  bool _isPickingAttachment = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMyResponseMessages();
      _loadMySentMessages();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _prefillFromUser(AppStateService appState) {
    if (_didPrefill) return;
    final user = appState.currentUser;
    if (user == null) return;
    final fullName =
        user['full_name'] ?? user['fullName'] ?? user['name'] ?? '';
    final email = user['email'] ?? '';
    if (_nameController.text.isEmpty && fullName is String) {
      _nameController.text = fullName;
    }
    if (_emailController.text.isEmpty && email is String) {
      _emailController.text = email;
    }
    _didPrefill = true;
  }

  Future<void> _submitMessage() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final result = await ApiService.createContactMessage(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      topic: _selectedTopic,
      content: _contentController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result['success'] == false) {
      final message = result['message']?.toString() ??
          'Gửi liên hệ thất bại, vui lòng thử lại.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.danger),
      );
      return;
    }

    final appState = Provider.of<AppStateService>(context, listen: false);
    final memberId = appState.currentUser?['id']?.toString();
    if (memberId != null && memberId.isNotEmpty) {
      await appState.addNotificationForMember(
        memberId,
        'Liên hệ đã gửi',
        'Yêu cầu "$_selectedTopic" đã được gửi thành công.',
        'contact',
        null,
      );
    }

    _contentController.clear();
    _titleController.clear();
    _attachments.clear();
    await _loadMyResponseMessages();
    _showSuccessDialog();
  }

  Future<void> _pickAttachments() async {
    if (_isPickingAttachment || _attachments.length >= 3) return;
    setState(() => _isPickingAttachment = true);

    try {
      final picker = ImagePicker();
      final pickedFiles = await picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (!mounted) return;

      final remaining = 3 - _attachments.length;
      final selected = pickedFiles.take(remaining).toList();
      final newItems = <_AttachmentItem>[];
      for (final file in selected) {
        final bytes = await file.readAsBytes();
        newItems.add(_AttachmentItem(
          file: file,
          bytes: bytes,
          name: file.name.isNotEmpty ? file.name : 'attachment.jpg',
        ));
      }

      setState(() {
        _attachments.addAll(newItems);
      });
    } finally {
      if (mounted) {
        setState(() => _isPickingAttachment = false);
      }
    }
  }

  void _removeAttachmentAt(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  Future<void> _loadMyResponseMessages() async {
    if (!mounted) return;
    setState(() => _isLoadingResponses = true);
    if (!mounted) return;
    setState(() => _isLoadingResponses = true);

    final messages = await ApiService.getContactMessages(limit: 50);
    final responded = messages.where((item) {
      if (item is! Map<String, dynamic>) return false;
      final status = (item['status'] ?? '').toString().toLowerCase();
      final response = (item['response'] ?? '').toString().trim();
      return status == 'resolved' && response.isNotEmpty;
    }).map((item) => Map<String, dynamic>.from(item as Map)).toList()
      ..sort((a, b) {
        final aDate = DateTime.tryParse(
                (a['responded_at'] ?? a['respondedAt'] ?? '').toString()) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = DateTime.tryParse(
                (b['responded_at'] ?? b['respondedAt'] ?? '').toString()) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

    if (!mounted) return;
    setState(() {
      _responseMessages = responded;
      _isLoadingResponses = false;
    });
  }

  Future<void> _loadMySentMessages() async {
    if (!mounted) return;
    setState(() => _isLoadingResponses = true);

    final messages = await ApiService.getContactMessages(limit: 50);

    final appState = Provider.of<AppStateService>(context, listen: false);
    final memberEmail = appState.currentUser?['email'] ?? '';
    final memberId = appState.currentUser?['id'];

    final sent = messages.where((item) {
      if (item is! Map<String, dynamic>) return false;
      final email = (item['email'] ?? '').toString();
      final uid = item['user_id'];
      if (memberId != null && uid == memberId) return true;
      if (email.isNotEmpty && memberEmail.isNotEmpty && email == memberEmail) return true;
      return false;
    }).map((item) => Map<String, dynamic>.from(item as Map)).toList()
      ..sort((a, b) {
        final aDate = DateTime.tryParse((a['created_at'] ?? a['createdAt'] ?? '').toString()) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = DateTime.tryParse((b['created_at'] ?? b['createdAt'] ?? '').toString()) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

    if (!mounted) return;
    setState(() {
      _sentMessages = sent;
      _isLoadingResponses = false;
    });
  }

  void _openMessagesPanel() {
    final Map<dynamic, Map<String, dynamic>> byId = {};

    for (final m in _sentMessages) {
      byId[m['id']] = Map<String, dynamic>.from(m);
    }

    for (final r in _responseMessages) {
      final id = r['id'];
      if (byId.containsKey(id)) {
        byId[id]?['response'] = r['response'];
        byId[id]?['responded_at'] = r['responded_at'] ?? r['respondedAt'];
        byId[id]?['status'] = r['status'];
      } else {
        // A message that was responded but not in sent list (should not happen often)
        byId[id] = Map<String, dynamic>.from(r);
      }
    }

    final List<Map<String, dynamic>> list = byId.values.map((e) => Map<String, dynamic>.from(e)).toList();
    final items = byId.values
        .map((entry) => _ContactThreadItem.fromMap(Map<String, dynamic>.from(entry)))
        .toList()
      ..sort((a, b) => b.sortDate.compareTo(a.sortDate));

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ContactInboxThreadScreen(items: items),
      ),
    );
  }

  String _formatResponseTime(dynamic raw) {
    final parsed = DateTime.tryParse((raw ?? '').toString());
    if (parsed == null) return 'Vừa xong';
    final hour = parsed.hour.toString().padLeft(2, '0');
    final minute = parsed.minute.toString().padLeft(2, '0');
    return '${parsed.day}/${parsed.month}/${parsed.year} $hour:$minute';
  }

  Widget _buildResponseSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.mark_email_read, color: AppColors.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Phản hồi từ quản trị',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                onPressed: _loadMyResponseMessages,
                icon: const Icon(Icons.refresh),
                tooltip: 'Làm mới',
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_isLoadingResponses)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_responseMessages.isEmpty)
            Text(
              'Chưa có thư phản hồi từ admin.',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            )
          else
            Column(
              children: _responseMessages.map((item) {
                final topic = (item['topic'] ?? 'Liên hệ').toString();
                final response = (item['response'] ?? '').toString();
                final status = (item['status'] ?? '').toString();
                final respondedAt =
                    _formatResponseTime(item['responded_at'] ?? item['respondedAt']);

                return Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              topic,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              status == 'resolved' ? 'Đã phản hồi' : status,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF166534),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        response,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        respondedAt,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateService>(context);
    _prefillFromUser(appState);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.textPrimary,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        ),
        title: const Text(
          'Liên hệ & Góp ý',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Thư đã gửi & Phản hồi',
            onPressed: _openMessagesPanel,
            icon: const Icon(Icons.mail_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadMyResponseMessages,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            children: [
              _buildSenderCard(),
              const SizedBox(height: 18),
              _buildSectionTitle('CHỦ ĐỀ CẦN HỖ TRỢ'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildTopicChip('Hoạt động Đoàn', Icons.event),
                  _buildTopicChip('Điểm rèn luyện', Icons.star),
                  _buildTopicChip('Hỗ trợ kỹ thuật', Icons.support_agent),
                  _buildTopicChip('Khác', Icons.more_horiz),
                ],
              ),
              const SizedBox(height: 18),
              _buildSectionTitle('TIÊU ĐỀ LIÊN HỆ'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _titleController,
                hintText: 'Nhập tóm tắt vấn đề của bạn...',
                maxLines: 1,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tiêu đề';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
              _buildSectionTitle('NỘI DUNG CHI TIẾT'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _contentController,
                hintText: 'Mô tả chi tiết vấn đề hoặc ý kiến đóng góp của bạn...',
                maxLines: 6,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập nội dung';
                  }
                  if (value.length < 10) {
                    return 'Nội dung quá ngắn (tối thiểu 10 ký tự)';
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              Text(
                '${_contentController.text.length} ký tự',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionTitle('ĐÍNH KÈM MINH CHỨNG'),
                  Text(
                    '${_attachments.length.toString().padLeft(2, '0')}/03 ảnh',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 128,
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _attachments.length >= 3 ? null : _pickAttachments,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFD6D9E0),
                              style: BorderStyle.solid,
                              width: 1.3,
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isPickingAttachment ? Icons.hourglass_empty : Icons.add_a_photo_outlined,
                                  size: 30,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _isPickingAttachment ? 'Đang tải...' : 'Tải ảnh lên',
                                  style: GoogleFonts.manrope(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildAttachmentPreview(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Chấp nhận JPG, PNG, PDF (tối đa 5MB/tệp)',
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 96),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submitMessage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_outlined, size: 20),
              label: Text(
                _isSubmitting ? 'Đang gửi...' : 'Gửi yêu cầu',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSenderCard() {
    final appState = context.read<AppStateService>();
    final user = appState.currentUser;
    final mssv = user != null 
        ? (user['student_code'] ?? user['studentCode'] ?? user['mssv'] ?? '')
        : '';
    
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: const Icon(Icons.person_outline, size: 16, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _nameController.text.isNotEmpty ? _nameController.text : 'Nguyễn Văn A',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.badge_outlined, size: 15, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${mssv.isNotEmpty ? mssv : 'SV12345678'} • ${_emailController.text.isNotEmpty ? _emailController.text : 'mro@university.edu.vn'}',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required String? Function(String?) validator,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      onChanged: onChanged,
      validator: validator,
      style: GoogleFonts.manrope(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.manrope(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.manrope(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.2,
        color: AppColors.primary,
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 20),
              const Text('Gửi thành công!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text('Cảm ơn bạn đã liên hệ.\nChúng tôi sẽ phản hồi sớm nhất.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _formKey.currentState?.reset();
                    _contentController.clear();
                    setState(() {
                      _selectedTopic = 'Hoạt động Đoàn';
                    });
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Đóng'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  Widget _buildTopicChip(String label, IconData icon) {
    final isSelected = _selectedTopic == label;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedTopic = label;
        });
      },
      selectedColor: AppColors.primary,
      backgroundColor: const Color(0xFFF8FAFC),
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        color: isSelected ? Colors.white : AppColors.textSecondary,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      side: const BorderSide(color: Color(0xFFD1D5DB)),
    );
  }

  Widget _buildAttachmentPreview() {
    if (_attachments.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.memory(
            _attachments.first.bytes,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: InkWell(
            onTap: () => _removeAttachmentAt(0),
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 16,
                color: Colors.red,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _sendEmail(String email) async {
    final Uri launchUri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  Future<void> _openMap() async {
    final Uri launchUri = Uri.parse('https://maps.google.com/?q=Dai+hoc+Dai+Nam');
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openFacebook() async {
    final Uri launchUri = Uri.parse('https://facebook.com/doantncshcm.cntt');
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openYouTube() async {
    final Uri launchUri = Uri.parse('https://youtube.com/@doankhoaCNTT');
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri, mode: LaunchMode.externalApplication);
    }
  }
}

class ContactInboxThreadScreen extends StatefulWidget {
  final List<_ContactThreadItem> items;

  const ContactInboxThreadScreen({super.key, required this.items});

  @override
  State<ContactInboxThreadScreen> createState() => _ContactInboxThreadScreenState();
}

class _ContactInboxThreadScreenState extends State<ContactInboxThreadScreen> {
  String _selectedFilter = 'all';

  List<_ContactThreadItem> get _filteredItems {
    return widget.items.where((item) {
      if (_selectedFilter == 'all') return true;
      return item.status == _selectedFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.textPrimary,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        ),
        title: const Text(
          'Hộp thư phản hồi',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.person_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              Row(
                children: [
                  _buildFilterChip('all', 'Tất cả'),
                  const SizedBox(width: 10),
                  _buildFilterChip('new', 'Chưa xử lý'),
                  const SizedBox(width: 10),
                  _buildFilterChip('resolved', 'Đã xử lý'),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: _filteredItems.isEmpty
                    ? Center(
                        child: Text(
                          'Không có tin nhắn phù hợp.',
                          style: GoogleFonts.manrope(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _filteredItems.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = _filteredItems[index];
                          return _buildInboxCard(item);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedFilter = value),
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : const Color(0xFFF0F2F5),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: isSelected ? AppColors.primary : const Color(0xFFE0E3E8)),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInboxCard(_ContactThreadItem item) {
    final statusColor = item.statusColor;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: item.categoryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.categoryIcon, color: item.categoryColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.topic,
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            item.statusLabel,
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Gửi ngày: ${item.createdDateLabel}',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.contentPreview,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              fontSize: 13,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
          if (item.responsePreview.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F7FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Admin đã phản hồi',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.responsePreview,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ContactThreadDetailScreen(item: item),
                  ),
                );
              },
              icon: const Icon(Icons.chevron_right, size: 18),
              label: const Text('Xem chi tiết'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryLight,
                textStyle: GoogleFonts.manrope(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ContactThreadDetailScreen extends StatelessWidget {
  final _ContactThreadItem item;

  const ContactThreadDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final statusColor = item.statusColor;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.textPrimary,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        ),
        title: const Text(
          'Chi tiết phản hồi',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mã yêu cầu: ${item.code}',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Trạng thái hiện tại',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      item.statusLabel,
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.topic,
                          style: GoogleFonts.manrope(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        'Ngày gửi\n${item.createdDateLabel}',
                        textAlign: TextAlign.right,
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      item.content,
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        height: 1.55,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (item.attachmentsLabel.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Tệp đính kèm (${item.attachmentsLabel.length})',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        item.attachmentsLabel,
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF3FF),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFD8E1FF)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.14),
                        child: const Icon(Icons.person, size: 18, color: AppColors.primary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.adminName,
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.adminRole,
                              style: GoogleFonts.manrope(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        item.responseUpdatedLabel,
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      item.response.isNotEmpty ? item.response : 'Chưa có phản hồi từ quản trị.',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        height: 1.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: Color(0xFFD1D5DB)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Đóng'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Gửi phản hồi thêm'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactThreadItem {
  final dynamic id;
  final String topic;
  final String content;
  final String response;
  final String status;
  final DateTime sortDate;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final String code;

  const _ContactThreadItem({
    required this.id,
    required this.topic,
    required this.content,
    required this.response,
    required this.status,
    required this.sortDate,
    required this.createdAt,
    required this.code,
    this.respondedAt,
  });

  factory _ContactThreadItem.fromMap(Map<String, dynamic> data) {
    final createdAt = DateTime.tryParse(
          (data['created_at'] ?? data['createdAt'] ?? '').toString(),
        ) ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final respondedAt = DateTime.tryParse(
      (data['responded_at'] ?? data['respondedAt'] ?? '').toString(),
    );
    final status = (data['status'] ?? 'new').toString();
    return _ContactThreadItem(
      id: data['id'],
      topic: (data['topic'] ?? 'Liên hệ').toString(),
      content: (data['content'] ?? '').toString(),
      response: (data['response'] ?? '').toString(),
      status: status,
      sortDate: respondedAt ?? createdAt,
      createdAt: createdAt,
      respondedAt: respondedAt,
      code: '#${data['id']?.toString() ?? '-'}',
    );
  }

  String get createdDateLabel {
    final day = createdAt.day.toString().padLeft(2, '0');
    final month = createdAt.month.toString().padLeft(2, '0');
    return '$day/$month/${createdAt.year}';
  }

  String get responseUpdatedLabel {
    final value = respondedAt ?? createdAt;
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '${day}/${month}/${value.year}';
  }

  String get statusLabel {
    switch (status) {
      case 'new':
        return 'Chưa xử lý';
      case 'in_progress':
        return 'Đang xử lý';
      case 'resolved':
        return 'Đã xử lý';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'new':
        return const Color(0xFF9CA3AF);
      case 'in_progress':
        return const Color(0xFFF59E0B);
      case 'resolved':
        return const Color(0xFF16A34A);
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  String get contentPreview {
    return content;
  }

  String get responsePreview {
    return response;
  }

  String get attachmentsLabel => response.isNotEmpty ? 'screenshot_error.png • 1.2 MB' : '';

  String get adminName => 'Admin đã phản hồi';

  String get adminRole => 'Quản trị viên';

  String get topicGroup => topic;

  IconData get categoryIcon {
    final lower = topic.toLowerCase();
    if (lower.contains('điểm') || lower.contains('diem')) return Icons.school_outlined;
    if (lower.contains('tài khoản') || lower.contains('tai khoan')) return Icons.person_outline;
    if (lower.contains('kỹ thuật') || lower.contains('ky thuat')) return Icons.settings_outlined;
    return Icons.chat_bubble_outline;
  }

  Color get categoryColor {
    final lower = topic.toLowerCase();
    if (lower.contains('điểm') || lower.contains('diem')) return const Color(0xFFF59E0B);
    if (lower.contains('tài khoản') || lower.contains('tai khoan')) return const Color(0xFF3B82F6);
    if (lower.contains('kỹ thuật') || lower.contains('ky thuat')) return const Color(0xFFFB923C);
    return AppColors.primaryLight;
  }
}

class _AttachmentItem {
  final XFile file;
  final Uint8List bytes;
  final String name;

  const _AttachmentItem({
    required this.file,
    required this.bytes,
    required this.name,
  });
}
