import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/colors.dart';
import '../services/api_service.dart';
import '../services/app_state_service.dart';

class AccountEditProfileScreen extends StatefulWidget {
  const AccountEditProfileScreen({super.key});

  @override
  State<AccountEditProfileScreen> createState() =>
      _AccountEditProfileScreenState();
}

class _AccountEditProfileScreenState extends State<AccountEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingAvatar = false;

  String _fullName = '';
  String _email = '';
  String _roleLabel = '';
  String _genderValue = 'other';
  DateTime? _dateOfBirth;
  String? _avatarUrl;

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
      _showSnack(result['message']?.toString() ?? 'Không thể tải thông tin', success: false);
      Navigator.pop(context);
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
    final phone = _pickString(profile, ['phone', 'mobile', 'phone_number']) ??
        _pickString(user, ['phone', 'mobile', 'phone_number']) ??
        '';
    final address = _pickString(profile, ['address', 'home_address']) ??
        _pickString(user, ['address', 'home_address']) ??
        '';
    final gender = _pickString(profile, ['gender']) ??
        _pickString(user, ['gender']) ??
        '';
    final dateOfBirthText = _pickString(profile, [
          'date_of_birth',
          'dateOfBirth',
          'dob',
        ]) ??
        _pickString(user, ['date_of_birth', 'dateOfBirth', 'dob']) ??
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

    _phoneController.text = phone;
    _addressController.text = address;

    setState(() {
      _fullName = fullName;
      _email = email;
      _roleLabel = _roleDisplay(role);
      _genderValue = _normalizeGender(gender);
      _dateOfBirth = _parseDate(dateOfBirthText);
      _avatarUrl = ApiService.resolveAvatarUrl(avatar);
      _isLoading = false;
    });
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
      _showSnack(result['message']?.toString() ?? 'Cập nhật ảnh thất bại');
    } else {
      _showSnack('Cập nhật ảnh thành công', success: true);
      await _loadProfile();
    }

    if (!mounted) return;
    setState(() {
      _isUploadingAvatar = false;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final result = await ApiService.updateAccountProfile(
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      address: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      gender: _genderValue,
      dateOfBirth: _dateOfBirth,
    );

    if (!mounted) return;

    if (result['success'] == false) {
      _showSnack(result['message']?.toString() ?? 'Cập nhật thông tin thất bại', success: false);
      setState(() {
        _isSaving = false;
      });
    } else {
      _showSnack('Cập nhật thông tin thành công', success: true);
      await Provider.of<AppStateService>(context, listen: false).refreshCurrentUser();
      if (!mounted) return;
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) Navigator.pop(context);
      });
    }
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

  String _normalizeGender(String? value) {
    switch (value) {
      case 'male':
      case 'female':
      case 'other':
        return value!;
      default:
        return 'other';
    }
  }

  String _genderLabel(String value) {
    switch (value) {
      case 'male':
        return 'Nam';
      case 'female':
        return 'Nữ';
      default:
        return 'Khác';
    }
  }

  DateTime? _parseDate(String value) {
    if (value.trim().isEmpty) return null;
    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '---';
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    return '$day/$month/$year';
  }

  void _showSnack(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? AppColors.success : AppColors.danger,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Hồ sơ cá nhân',
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        ),
      ),
      body: ColoredBox(
        color: Colors.white,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAvatarSection(),
                        const SizedBox(height: 18),
                        _buildSectionHeader('THÔNG TIN CƠ BẢN'),
                        const SizedBox(height: 12),
                        _buildProfileCard(
                          children: [
                            _buildReadOnlyField(
                              label: 'Họ và tên',
                              value: _fullName,
                              icon: Icons.person_outline,
                            ),
                            const SizedBox(height: 14),
                            _buildReadOnlyField(
                              label: 'Email',
                              value: _email,
                              icon: Icons.email_outlined,
                            ),
                            const SizedBox(height: 14),
                            _buildEditableField(
                              label: 'Số điện thoại',
                              controller: _phoneController,
                              icon: Icons.phone_outlined,
                              hintText: 'Nhập số điện thoại',
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return null;
                                }
                                if (value.trim().length < 9) {
                                  return 'Số điện thoại không hợp lệ';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _buildSectionHeader('THÔNG TIN CÔNG TÁC'),
                        const SizedBox(height: 12),
                        _buildProfileCard(
                          children: [
                            _buildReadOnlyField(
                              label: 'Chức vụ',
                              value: _roleLabel,
                              icon: Icons.badge_outlined,
                            ),
                            const SizedBox(height: 14),
                            _buildEditableField(
                              label: 'Địa chỉ',
                              controller: _addressController,
                              icon: Icons.location_on_outlined,
                              hintText: 'Nhập địa chỉ',
                              validator: (value) => null,
                            ),
                            const SizedBox(height: 14),
                            _buildGenderField(),
                            const SizedBox(height: 14),
                            _buildDateOfBirthField(),
                          ],
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F3B8F),
                              padding: const EdgeInsets.symmetric(vertical: 17),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 8,
                              shadowColor: const Color(0xFF0F3B8F).withOpacity(0.35),
                            ),
                            child: _isSaving
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Đang lưu...',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  )
                                : const Text(
                                    'Lưu thay đổi',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hintText,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF2563EB),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(
              icon,
              color: const Color(0xFF64748B),
              size: 20,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFD7DDE8)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFD7DDE8), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.danger, width: 2),
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFF),
            hintStyle: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 13,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF2563EB),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFD7DDE8), width: 1),
            borderRadius: BorderRadius.circular(14),
            color: const Color(0xFFF8FAFF),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: const Color(0xFF64748B),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value.isEmpty ? '---' : value,
                  style: TextStyle(
                    fontSize: 14,
                    color: value.isEmpty
                        ? const Color(0xFF94A3B8)
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarSection() {
    final avatar = _avatarUrl;
    return Center(
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
                  border: Border.all(color: const Color(0xFF1E40AF), width: 3),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A1E40AF),
                      blurRadius: 14,
                      offset: Offset(0, 6),
                    ),
                  ],
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
                bottom: 2,
                right: 6,
                child: InkWell(
                  onTap: _isUploadingAvatar ? null : _pickAvatar,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E40AF),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
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
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'THAY ĐỔI ẢNH ĐẠI DIỆN',
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Giới tính',
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF2563EB),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFD7DDE8), width: 1),
            borderRadius: BorderRadius.circular(14),
            color: const Color(0xFFF8FAFF),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _genderValue,
              icon: const SizedBox.shrink(),
              isExpanded: true,
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _genderValue = value;
                });
              },
              items: const [
                DropdownMenuItem(value: 'male', child: Text('Nam')),
                DropdownMenuItem(value: 'female', child: Text('Nữ')),
                DropdownMenuItem(value: 'other', child: Text('Khác')),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateOfBirthField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ngày sinh',
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF2563EB),
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final now = DateTime.now();
            final initialDate = _dateOfBirth ?? DateTime(now.year - 18, 1, 1);
            final picked = await showDatePicker(
              context: context,
              initialDate: initialDate,
              firstDate: DateTime(1900, 1, 1),
              lastDate: DateTime(now.year, now.month, now.day),
            );
            if (picked == null) return;
            setState(() {
              _dateOfBirth = picked;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFD7DDE8), width: 1),
              borderRadius: BorderRadius.circular(14),
              color: const Color(0xFFF8FAFF),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.cake_outlined,
                  color: Color(0xFF64748B),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _formatDate(_dateOfBirth),
                    style: TextStyle(
                      fontSize: 14,
                      color: _dateOfBirth == null
                          ? const Color(0xFF94A3B8)
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5ECF7)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F1E40AF),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }
}
