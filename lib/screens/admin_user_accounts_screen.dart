import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/colors.dart';
import '../models/user_item.dart';
import '../services/api_service.dart';

class AdminUserAccountsScreen extends StatefulWidget {
  const AdminUserAccountsScreen({super.key});

  @override
  State<AdminUserAccountsScreen> createState() => _AdminUserAccountsScreenState();
}

class _AdminUserAccountsScreenState extends State<AdminUserAccountsScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  String? _errorMessage;
  List<UserItem> _users = [];

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
      final results = await Future.wait([
        ApiService.getUnits(),
        ApiService.getUsers(limit: 500),
      ]);
      final units = results[0] as List<dynamic>;
      final users = results[1] as List<dynamic>;

      final unitMap = <int, String>{};
      for (final item in units) {
        if (item is! Map<String, dynamic>) continue;
        final id = item['id'];
        if (id is! int) continue;
        final name = item['name']?.toString() ?? '';
        final code = item['code']?.toString() ?? '';
        unitMap[id] = name.isNotEmpty ? name : code;
      }

      final mappedUsers = users
          .whereType<Map<String, dynamic>>()
          .map((item) => UserItem.fromApi(item, unitMap: unitMap))
          .toList()
        ..sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));

      if (!mounted) return;
      setState(() {
        _users = mappedUsers;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Không tải được danh sách tài khoản';
        _isLoading = false;
      });
    }
  }

  List<UserItem> get _filteredUsers {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _users;
    return _users.where((user) {
      return user.fullName.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query) ||
          user.phone.toLowerCase().contains(query) ||
          (user.unitName ?? '').toLowerCase().contains(query) ||
          _roleLabel(user.role).toLowerCase().contains(query) ||
          _statusLabel(user.status).toLowerCase().contains(query);
    }).toList();
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'staff':
        return 'Cán bộ';
      case 'member':
      default:
        return 'Đoàn viên';
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Chờ duyệt';
      case 'inactive':
        return 'Ngừng hoạt động';
      case 'alumni':
        return 'Cựu đoàn viên';
      case 'active':
      default:
        return 'Hoạt động';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'inactive':
        return const Color(0xFFDC2626);
      case 'alumni':
        return const Color(0xFF7C3AED);
      case 'active':
      default:
        return const Color(0xFF16A34A);
    }
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'admin':
        return const Color(0xFFDC3545);
      case 'staff':
        return const Color(0xFF2563EB);
      case 'member':
      default:
        return const Color(0xFF0EA5E9);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Quản lý người dùng'),
        backgroundColor: const Color(0xFFFFFFFF),
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              children: [
                const Icon(Icons.group, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  '${_users.length}',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _buildHeader(),
            const SizedBox(height: 14),
            _buildSearchField(),
            const SizedBox(height: 16),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null)
              _buildErrorCard()
            else if (_filteredUsers.isEmpty)
              _buildEmptyCard()
            else
              ..._filteredUsers.map(_buildUserCard),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Danh sách quản lý',
          style: GoogleFonts.manrope(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Quản lý người dùng trong hệ thống',
          style: GoogleFonts.manrope(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Tìm theo tên, email...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: IconButton(
            onPressed: () {},
            icon: const Icon(Icons.filter_alt_outlined, color: Colors.white),
          ),
        ),
      ],
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
        'Không tìm thấy tài khoản phù hợp.',
        style: GoogleFonts.manrope(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildUserCard(UserItem user) {
    final avatar = user.avatarUrl;
    final initials = user.fullName.trim().isEmpty
        ? '?'
        : user.fullName.trim().split(RegExp(r'\s+')).take(2).map((part) => part.isNotEmpty ? part[0] : '').join().toUpperCase();

    return GestureDetector(
      onTap: () => _showAccountSheet(user),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F0F172A),
              blurRadius: 14,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: avatar != null && avatar.isNotEmpty
                    ? Image.network(
                        avatar,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Text(
                            initials,
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          initials,
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildChip(_roleLabel(user.role), _roleColor(user.role), filled: true),
                      _buildChip(_statusLabel(user.status), _statusColor(user.status), filled: true),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color color, {bool filled = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: filled ? color : color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.manrope(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: filled ? Colors.white : color,
        ),
      ),
    );
  }

  void _showAccountSheet(UserItem user) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.fullName,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    user.email,
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSectionLabel('Thông tin tài khoản'),
                  const SizedBox(height: 8),
                  _detailRow('Vai trò', _roleLabel(user.role)),
                  _detailRow('Trạng thái', _statusLabel(user.status)),
                  _detailRow('Số điện thoại', user.phone.isEmpty ? '-' : user.phone),
                  _detailRow('Đơn vị', user.unitName?.isNotEmpty == true ? user.unitName! : '-'),
                  _detailRow('Mã sinh viên', user.studentCode?.isNotEmpty == true ? user.studentCode! : '-'),
                  const SizedBox(height: 16),
                  _buildSectionLabel('Thao tác nhanh'),
                  const SizedBox(height: 10),
                  _buildActionButton(
                    label: user.status == 'inactive' ? 'Mở tài khoản' : 'Khóa tài khoản',
                    icon: user.status == 'inactive' ? Icons.lock_open_outlined : Icons.lock_outline,
                    color: user.status == 'inactive' ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                    onTap: () async {
                      Navigator.pop(context);
                      await _toggleAccountStatus(user);
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildActionButton(
                    label: 'Reset mật khẩu',
                    icon: Icons.key_outlined,
                    color: const Color(0xFFF59E0B),
                    onTap: () async {
                      Navigator.pop(context);
                      await _resetPassword(user);
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildActionButton(
                    label: 'Xem chi tiết đầy đủ',
                    icon: Icons.info_outline,
                    color: AppColors.primary,
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Đóng'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
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

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.manrope(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: color),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withOpacity(0.45)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Future<void> _toggleAccountStatus(UserItem user) async {
    final targetStatus = user.status == 'inactive' ? 'active' : 'inactive';
    final actionLabel = targetStatus == 'active' ? 'mở' : 'khóa';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${targetStatus == 'active' ? 'Mở' : 'Khóa'} tài khoản'),
        content: Text('Bạn có chắc chắn muốn $actionLabel tài khoản của ${user.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await ApiService.updateUser(
      userId: user.id.toString(),
      status: targetStatus,
    );

    if (!mounted) return;
    if (result['success'] == false) {
      _showMessage(result['message']?.toString() ?? 'Cập nhật trạng thái thất bại');
      return;
    }

    _showMessage(
      targetStatus == 'active' ? 'Đã mở tài khoản' : 'Đã khóa tài khoản',
      success: true,
    );
    await _loadData();
  }

  Future<void> _resetPassword(UserItem user) async {
    final controller = TextEditingController();
    final password = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset mật khẩu'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Mật khẩu mới',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (password == null || password.isEmpty) return;

    final result = await ApiService.updateUser(
      userId: user.id.toString(),
      password: password,
    );

    if (!mounted) return;
    if (result['success'] == false) {
      _showMessage(result['message']?.toString() ?? 'Reset mật khẩu thất bại');
      return;
    }

    _showMessage('Đã reset mật khẩu', success: true);
  }

  void _showMessage(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? AppColors.success : AppColors.danger,
      ),
    );
  }
}
