import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/colors.dart';
import '../services/api_service.dart';
import '../services/app_state_service.dart';
import 'account_change_password_screen.dart';
import 'account_email_screen.dart';
import 'account_edit_profile_screen.dart';
import 'admin_contact_inbox_screen.dart';
import 'contact_screen.dart';
import 'login_screen.dart';
import 'training_score_my_screen.dart';

class AccountProfileScreen extends StatefulWidget {
  const AccountProfileScreen({super.key});

  @override
  State<AccountProfileScreen> createState() => _AccountProfileScreenState();
}

class _AccountProfileScreenState extends State<AccountProfileScreen> {
  bool _isLoading = true;
  bool _isUploadingAvatar = false;

  String _fullName = '';
  String _email = '';
  String _username = '';
  String _roleValue = '';
  String _roleLabel = '';
  String _studentCode = '';
  String _cohortLabel = '';
  String? _avatarUrl;

  bool get _isMember => _roleValue.trim().toLowerCase() == 'member';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
    });

    final result = await ApiService.getAccountProfile();
    if (!mounted) return;

    if (result['success'] == false) {
      _showSnack(result['message']?.toString() ?? 'Không thể tải thông tin');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final profile = _extractProfile(result);
    final user = _extractUser(result);
    final fullName = _pickString(profile, [
          'full_name',
          'fullName',
          'name',
        ]) ??
        '';
    final email = _pickString(profile, ['email', 'mail']) ?? '';
    final username = _pickString(profile, [
          'username',
          'external_username',
          'userName',
          'user_name',
          'account',
          'login',
        ]) ??
        _pickString(user, [
          'external_username',
          'email',
          'student_code',
          'username',
          'account',
          'login',
        ]) ??
        '';
    final role = _pickString(profile, [
      'role',
      'user_role',
      'userRole',
      'roleName',
      'role_name',
    ]) ??
        _pickString(user, ['role', 'user_role', 'userRole', 'roleName']);

    final avatar = _pickString(profile, [
      'avatar_url',
      'avatarUrl',
      'avatar',
      'photoUrl',
      'imageUrl',
    ]);
    final studentCode = _pickString(profile, ['student_code', 'studentCode', 'mssv']) ??
      _pickString(user, ['student_code', 'studentCode', 'mssv']) ??
      '';
    var cohort = _pickString(profile, ['course', 'cohort', 'entry_year', 'academic_year']) ??
      _pickString(user, ['course', 'cohort', 'entry_year', 'academic_year']) ??
      '';
    
    // If cohort is still empty, try to extract from student code
    if (cohort.isEmpty) {
      cohort = _extractCohortFromStudentCode(studentCode);
    }

    setState(() {
      _fullName = fullName;
      _email = email;
      _username = username;
      _roleValue = role ?? '';
      _roleLabel = _roleDisplay(role);
      _studentCode = studentCode;
      _cohortLabel = cohort;
      _avatarUrl = ApiService.resolveAvatarUrl(avatar);
      _isLoading = false;
    });

    await Provider.of<AppStateService>(context, listen: false)
        .refreshCurrentUser();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 85,
    );

    if (file == null || !mounted) return;

    setState(() {
      _isUploadingAvatar = true;
    });

    final bytes = await file.readAsBytes();
    final result = await ApiService.updateAccountAvatar(
      bytes: bytes,
      filename: file.name.isNotEmpty ? file.name : 'avatar.jpg',
    );

    if (!mounted) return;

    if (result['success'] == false) {
      _showSnack(result['message']?.toString() ?? 'Cập nhật ảnh đại diện thất bại');
    } else {
      _showSnack('Cập nhật ảnh đại diện thành công', success: true);
      await _loadProfile();
    }

    if (!mounted) return;
    setState(() {
      _isUploadingAvatar = false;
    });
  }

  Map<String, dynamic> _extractProfile(Map<String, dynamic> result) {
    final data = result['data'];
    if (data is Map<String, dynamic>) {
      final profile = data['profile'];
      if (profile is Map<String, dynamic>) return profile;
      final user = data['user'];
      if (user is Map<String, dynamic>) return user;
      return data;
    }

    final profile = result['profile'];
    if (profile is Map<String, dynamic>) return profile;
    final user = result['user'];
    if (user is Map<String, dynamic>) return user;

    return {};
  }

  Map<String, dynamic> _extractUser(Map<String, dynamic> result) {
    final data = result['data'];
    if (data is Map<String, dynamic>) {
      final user = data['user'];
      if (user is Map<String, dynamic>) return user;
    }

    final user = result['user'];
    if (user is Map<String, dynamic>) return user;

    return {};
  }

  String? _pickString(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  String _roleDisplay(String? value) {
    switch (value) {
      case 'admin':
        return 'Admin';
      case 'staff':
        return 'Cán bộ';
      case 'member':
        return 'Đoàn viên';
      default:
        return value ?? '';
    }
  }

  String _extractCohortFromStudentCode(String studentCode) {
    final code = (studentCode).trim();
    if (code.length < 2) return '';
    final prefix = code.substring(0, 2);
    final prefixNum = int.tryParse(prefix);
    if (prefixNum == null) return '';
    if (prefixNum == 16) return '2024';
    if (prefixNum == 17) return '2025';
    if (prefixNum == 18) return '2026';
    if (prefixNum == 19) return '2027';
    return '';
  }

  void _showSnack(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? AppColors.success : AppColors.danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: SafeArea(
          bottom: false,
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            color: const Color(0xFFF5F6FC),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back, size: 22, color: AppColors.textPrimary),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
                Text(
                  _roleValue.trim().toLowerCase() == 'admin'
                      ? 'Hồ sơ quản trị viên'
                      : _roleValue.trim().toLowerCase() == 'staff'
                          ? 'Hồ sơ cán bộ'
                          : 'Hồ sơ cá nhân',
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 36),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfile,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  _buildAvatarSection(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Tùy chỉnh'),
                  const SizedBox(height: 12),
                  _buildAccountActionButton(
                    label: 'Chỉnh sửa thông tin cá nhân',
                    icon: Icons.edit_outlined,
                    onTap: _openEditProfile,
                  ),
                  _buildAccountActionButton(
                    label: 'Đổi mật khẩu',
                    icon: Icons.lock_outline,
                    onTap: _openChangePassword,
                  ),
                  if (_isMember)
                    _buildAccountActionButton(
                      label: 'Điểm rèn luyện',
                      icon: Icons.assignment_outlined,
                      onTap: _openTrainingScores,
                    ),
                  // Removed 'Thông báo của tôi' and 'Trợ giúp & Hỗ trợ' for members per request
                  _buildAccountActionButton(
                    label: _isMember ? 'Liên hệ' : 'Liên hệ và góp ý',
                    icon: Icons.support_agent_outlined,
                    onTap: _openContact,
                  ),
                  const SizedBox(height: 16),
                  _buildLogoutButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildAvatarSection() {
    final avatar = _avatarUrl;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 108,
                height: 108,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 2.2),
                ),
                child: ClipOval(
                  child: avatar != null && avatar.isNotEmpty
                      ? Image.network(
                          avatar,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              'assets/images/logo.jpg',
                              fit: BoxFit.cover,
                            );
                          },
                        )
                        : Image.asset(
                          'assets/images/logo.jpg',
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              if (_isUploadingAvatar)
                Container(
                  width: 108,
                  height: 108,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.35),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
              Positioned(
                bottom: 4,
                right: 4,
                child: InkWell(
                  onTap: _isUploadingAvatar ? null : _pickAvatar,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _fullName.isNotEmpty ? _fullName : 'Chưa cập nhật họ tên',
            style: GoogleFonts.manrope(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            _email.isNotEmpty ? _email : 'Chưa cập nhật email',
            style: GoogleFonts.manrope(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          if (_isMember)
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildRoleBadge(
                  'MSSV: ${_studentCode.isNotEmpty ? _studentCode : _username.isNotEmpty ? _username : '---'}',
                  const Color(0xFF2F6FE4),
                ),
                _buildRoleBadge(
                  _cohortLabel.isNotEmpty ? 'Khóa $_cohortLabel' : 'Khóa ---',
                  const Color(0xFF8B5E34),
                ),
              ],
            )
          else if (_roleValue.trim().toLowerCase() == 'admin')
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildRoleBadge('Quản trị viên hệ thống', AppColors.primary),
                _buildRoleBadge('Ban Chấp hành Đoàn', AppColors.adminPrimary),
              ],
            )
          else
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildRoleBadge('Cán bộ Đoàn', AppColors.adminPrimary),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.manrope(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF6B7280),
      ),
    );
  }

  Widget _buildRoleBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.manrope(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  void _showUnavailable() {
    _showSnack('Tính năng đang được cập nhật', success: false);
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    final displayValue = value.trim().isEmpty ? 'Chưa cập nhật' : value.trim();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  displayValue,
                  style: GoogleFonts.manrope(
                    fontSize: 15,
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

  Widget _buildAccountActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE6E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A0F172A),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF0FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openUpdateEmail() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AccountEmailScreen()),
    );
    if (!mounted) return;
    await _loadProfile();
  }

  Future<void> _openEditProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AccountEditProfileScreen()),
    );
    if (!mounted) return;
    await _loadProfile();
  }

  Future<void> _openChangePassword() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AccountChangePasswordScreen()),
    );
  }

  Future<void> _openContact() async {
    if (_isMember) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ContactScreen()),
      );
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminContactInboxScreen()),
    );
  }

  Future<void> _openTrainingScores() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TrainingScoreMyScreen()),
    );
  }

  bool _canOpenContactInbox() {
    final role = _roleValue.trim().toLowerCase();
    return role == 'admin' || role == 'staff';
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _confirmSignout,
        icon: const Icon(Icons.logout, size: 18),
        label: const Text('Đăng xuất'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.danger,
          side: const BorderSide(color: Color(0xFFF3B4B4)),
          padding: const EdgeInsets.symmetric(vertical: 13),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmSignout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final result = await ApiService.signout();
    if (!mounted) return;

    if (result['success'] == false) {
      _showSnack(result['message']?.toString() ?? 'Đăng xuất thất bại');
      return;
    }

    await Provider.of<AppStateService>(context, listen: false)
        .refreshCurrentUser();

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}
