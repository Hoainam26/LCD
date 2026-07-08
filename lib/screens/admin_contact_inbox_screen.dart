import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/colors.dart';
import '../services/api_service.dart';

class AdminContactInboxScreen extends StatefulWidget {
  final String? initialMessageId;

  const AdminContactInboxScreen({super.key, this.initialMessageId});

  @override
  State<AdminContactInboxScreen> createState() => _AdminContactInboxScreenState();
}

class _AdminContactInboxScreenState extends State<AdminContactInboxScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  String? _errorMessage;
  List<_ContactMessageItem> _items = [];
  String _selectedCategory = 'Tất cả';
  String _selectedStatus = 'all';
  String _searchQuery = '';
  bool _didOpenDeepLink = false;

  static const _statusOptions = ['new', 'in_progress', 'resolved'];
  static const _categories = [
    'Tất cả',
    'Hoạt động Đoàn',
    'Điểm rèn luyện',
    'Tài khoản',
    'Khác',
  ];
  static const _statusFilters = ['all', 'new', 'in_progress', 'resolved'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await ApiService.getContactMessages(limit: 200);
      final items = results
          .whereType<Map<String, dynamic>>()
          .map(_ContactMessageItem.fromApi)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (!mounted) return;
      setState(() {
        _items = items;
        _isLoading = false;
      });
      _openInitialMessageIfNeeded(items);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Không tải được liên hệ';
        _isLoading = false;
      });
    }
  }

  void _openInitialMessageIfNeeded(List<_ContactMessageItem> items) {
    if (_didOpenDeepLink) return;
    final targetId = widget.initialMessageId;
    if (targetId == null || targetId.trim().isEmpty) return;

    _ContactMessageItem? matchedItem;
    for (final item in items) {
      if (item.id.toString() == targetId) {
        matchedItem = item;
        break;
      }
    }

    if (matchedItem == null) return;
    _didOpenDeepLink = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showDetailSheet(matchedItem!);
    });
  }

  List<_ContactMessageItem> get _filteredItems {
    return _items.where((item) {
      final needle = _searchQuery.trim().toLowerCase();
      final matchesSearch = needle.isEmpty
          ? true
          : item.fullName.toLowerCase().contains(needle) ||
              item.email.toLowerCase().contains(needle) ||
              item.topic.toLowerCase().contains(needle) ||
              item.content.toLowerCase().contains(needle);
      final matchesCategory = _selectedCategory == 'Tất cả'
          ? true
          : item.topicGroup == _selectedCategory;
      final matchesStatus = _selectedStatus == 'all'
          ? true
          : item.status == _selectedStatus;
      return matchesSearch && matchesCategory && matchesStatus;
    }).toList();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'new':
        return const Color(0xFF2563EB);
      case 'in_progress':
        return const Color(0xFFF59E0B);
      case 'resolved':
        return const Color(0xFF16A34A);
      default:
        return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Liên hệ'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          children: [
            _buildSearchField(),
            const SizedBox(height: 16),
            _buildStatusSelector(),
            const SizedBox(height: 16),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null)
              _buildErrorCard()
            else if (_filteredItems.isEmpty)
              _buildEmptyCard()
            else
              ..._filteredItems.map(_buildMessageCard),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        style: GoogleFonts.manrope(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'Tìm kiếm theo tên hoặc nội dung...',
          hintStyle: GoogleFonts.manrope(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
          prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textSecondary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((label) {
          final isSelected = _selectedCategory == label;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedCategory = label),
              selectedColor: AppColors.primary,
              backgroundColor: Colors.white,
              labelStyle: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatusSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _statusFilters.map((status) {
          final isSelected = _selectedStatus == status;
          final label = status == 'all' ? 'Tất cả' : _statusLabel(status);
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedStatus = status),
              selectedColor: AppColors.primary,
              backgroundColor: const Color(0xFFF8FAFC),
              labelStyle: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
          );
        }).toList(),
      ),
    );
  }


  Widget _buildErrorCard() {
    return Container(
      margin: const EdgeInsets.only(top: 48),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        _errorMessage ?? 'Đã xảy ra lỗi',
        style: GoogleFonts.manrope(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildEmptyCard() {
    return Container(
      margin: const EdgeInsets.only(top: 48),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        'Không có liên hệ phù hợp.',
        style: GoogleFonts.manrope(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildMessageCard(_ContactMessageItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showDetailSheet(item),
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.fullName,
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.email,
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _statusColor(item.status).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    item.statusLabel,
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _statusColor(item.status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTag(item.topicGroup),
                _buildTag(item.createdAtLabel),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              item.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: AppColors.textPrimary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showDetailSheet(item),
                  icon: const Icon(Icons.reply_outlined, size: 16),
                  label: const Text('Phản hồi'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  item.topic,
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.manrope(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'new':
        return 'Mới';
      case 'in_progress':
        return 'Đang xử lý';
      case 'resolved':
        return 'Đã xử lý';
      default:
        return status;
    }
  }

  void _showDetailSheet(_ContactMessageItem item) {
    Navigator.of(context)
        .push<bool>(
          MaterialPageRoute(
            builder: (_) => AdminContactReplyScreen(item: item),
          ),
        )
        .then((didSubmit) {
          if (didSubmit == true && mounted) {
            _loadData();
          }
        });
  }

}

class AdminContactReplyScreen extends StatefulWidget {
  final _ContactMessageItem item;

  const AdminContactReplyScreen({super.key, required this.item});

  @override
  State<AdminContactReplyScreen> createState() => _AdminContactReplyScreenState();
}

class _AdminContactReplyScreenState extends State<AdminContactReplyScreen> {
  final TextEditingController _responseController = TextEditingController();
  static const List<String> _quickReplies = [
    'Đã tiếp nhận',
    'Yêu cầu bổ sung',
    'Hẹn gặp trực tiếp',
  ];

  bool _markAsProcessed = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _responseController.text = widget.item.response ?? '';
  }

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  String _formattedSentTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    return 'Gửi lúc $hour:$minute, $day/$month/${dateTime.year}';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'new':
        return const Color(0xFF3B82F6);
      case 'in_progress':
        return const Color(0xFFF59E0B);
      case 'resolved':
        return const Color(0xFF16A34A);
      default:
        return const Color(0xFF64748B);
    }
  }

  String _nextStatusValue() {
    if (_markAsProcessed) return 'resolved';
    if (widget.item.status == 'resolved') return 'in_progress';
    return widget.item.status == 'new' ? 'in_progress' : widget.item.status;
  }

  Future<void> _submitReply() async {
    final response = _responseController.text.trim();
    if (response.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập nội dung phản hồi.')),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    final result = await ApiService.respondToContactMessage(
      id: widget.item.id.toString(),
      response: response,
      status: _nextStatusValue(),
    );

    if (!mounted) return;

    setState(() {
      _isSending = false;
    });

    if (result['success'] == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']?.toString() ?? 'Phản hồi thất bại'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    Navigator.of(context).pop(true);
  }

  void _applyQuickReply(String reply) {
    setState(() {
      _responseController.text = reply;
      _responseController.selection = TextSelection.fromPosition(
        TextPosition(offset: reply.length),
      );
    });
  }

  Widget _buildQuickReplyChip(String label) {
    final isSelected = _responseController.text.trim() == label;
    return ActionChip(
      label: Text(label),
      onPressed: () => _applyQuickReply(label),
      backgroundColor: isSelected ? AppColors.primary : Colors.white,
      side: BorderSide(
        color: isSelected ? AppColors.primary : const Color(0xFFD1D5DB),
      ),
      labelStyle: GoogleFonts.manrope(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: isSelected ? Colors.white : AppColors.textSecondary,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final statusColor = _statusColor(item.status);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F5FF),
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: const Color(0xFFF7F5FF),
        foregroundColor: AppColors.textPrimary,
        leadingWidth: 52,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(false),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        ),
        title: Text(
          'Phản hồi liên hệ',
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A0F172A),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: const Color(0xFFE2E8F0),
                      child: Text(
                        item.fullName.isNotEmpty
                            ? item.fullName.trim().substring(0, 1).toUpperCase()
                            : '?',
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.fullName,
                            style: GoogleFonts.manrope(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formattedSentTime(item.createdAt),
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  '"${item.content}"',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    height: 1.55,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Nội dung phản hồi',
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x080F172A),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _responseController,
                  maxLines: 6,
                  onChanged: (_) => setState(() {}),
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    height: 1.4,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Nhập nội dung câu trả lời của bạn tại đây...',
                    hintStyle: GoogleFonts.manrope(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _quickReplies
                      .map(
                        (reply) => Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: _buildQuickReplyChip(reply),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.check_circle_outline, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Đánh dấu đã xử lý',
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Chuyển trạng thái sang hoàn tất',
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _markAsProcessed,
                      onChanged: (value) => setState(() => _markAsProcessed = value),
                      activeColor: Colors.white,
                      activeTrackColor: AppColors.primary,
                    ),
                  ],
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
              onPressed: _isSending ? null : _submitReply,
              icon: _isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_outlined),
              label: Text(
                _isSending ? 'Đang gửi...' : 'Gửi phản hồi',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactMessageItem {
  final int id;
  final String fullName;
  final String email;
  final String topic;
  final String content;
  final String status;
  final String? response;
  final DateTime createdAt;

  const _ContactMessageItem({
    required this.id,
    required this.fullName,
    required this.email,
    required this.topic,
    required this.content,
    required this.status,
    required this.createdAt,
    this.response,
  });

  factory _ContactMessageItem.fromApi(Map<String, dynamic> json) {
    return _ContactMessageItem(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      fullName: json['full_name']?.toString() ?? json['fullName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      topic: json['topic']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      status: json['status']?.toString() ?? 'new',
      response: json['response']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? json['createdAt']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  String get topicGroup {
    final lower = topic.toLowerCase();
    if (lower.contains('hoạt động') || lower.contains('hoat dong')) {
      return 'Hoạt động Đoàn';
    }
    if (lower.contains('điểm') || lower.contains('diem')) {
      return 'Điểm rèn luyện';
    }
    if (lower.contains('tài khoản') || lower.contains('tai khoan') || lower.contains('account')) {
      return 'Tài khoản';
    }
    return 'Khác';
  }

  String get statusLabel {
    switch (status) {
      case 'new':
        return 'Mới';
      case 'in_progress':
        return 'Đang xử lý';
      case 'resolved':
        return 'Đã xử lý';
      default:
        return status;
    }
  }

  String get createdAtLabel {
    final day = createdAt.day.toString().padLeft(2, '0');
    final month = createdAt.month.toString().padLeft(2, '0');
    return '$day/$month/${createdAt.year}';
  }
}
