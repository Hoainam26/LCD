import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';

import '../constants/colors.dart';
import '../models/user_item.dart';
import '../services/api_service.dart';

class UnionOfficerDetailScreen extends StatelessWidget {
  final UserItem? officer;
  final String fallbackName;
  final String fallbackRole;
  final String fallbackSlogan;
  final String? fallbackAvatarUrl;
  final String? fallbackEmail;
  final String? fallbackPhone;

  const UnionOfficerDetailScreen({
    super.key,
    required this.officer,
    required this.fallbackName,
    required this.fallbackRole,
    required this.fallbackSlogan,
    required this.fallbackAvatarUrl,
    required this.fallbackEmail,
    required this.fallbackPhone,
  });

  String get _name => officer?.fullName.isNotEmpty == true
      ? officer!.fullName
      : fallbackName;

  String get _role => _firstNonEmpty([
        officer?.position,
        fallbackRole,
        _roleLabel(officer?.role ?? ''),
      ]);

  String get _slogan => fallbackSlogan;

  String get _unit => _firstNonEmpty([
        officer?.unitName,
        'Ban Chấp hành',
      ]);

  String get _email => _firstNonEmpty([
        officer?.email,
      fallbackEmail,
        '-',
      ]);

  String get _phone => _firstNonEmpty([
        officer?.phone,
      fallbackPhone,
        '-',
      ]);

  String? get _avatarUrl => officer?.avatarUrl ?? fallbackAvatarUrl;

  String _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return '-';
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Quản trị';
      case 'staff':
        return 'Cán bộ';
      case 'member':
        return 'Đoàn viên';
      default:
        return role.trim().isEmpty ? 'Thành viên BCH' : role;
    }
  }

  Color _roleColor() {
    final role = officer?.role.toLowerCase() ?? '';
    switch (role) {
      case 'admin':
        return const Color(0xFFB45309);
      case 'staff':
        return const Color(0xFF2563EB);
      default:
        return AppColors.primary;
    }
  }

  Widget _buildAvatar() {
    final avatar = ApiService.resolveAvatarUrl(_avatarUrl) ?? 'assets/images/logo.jpg';
    final isNetwork = avatar.startsWith('http');
    final image = isNetwork
        ? Image.network(
            avatar,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildAvatarFallback(),
          )
        : Image.asset(
            avatar,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildAvatarFallback(),
          );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 124,
          height: 124,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipOval(child: image),
        ),
        Positioned(
          right: 2,
          bottom: 2,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(Icons.verified, size: 13, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarFallback() {
    return Container(
      color: const Color(0xFFF0F4FF),
      child: Image.asset(
        'assets/images/logo.jpg',
        fit: BoxFit.cover,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roleColor = _roleColor();

    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFBFF),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 6),
              Center(child: _buildAvatar()),
              const SizedBox(height: 16),
              Text(
                _name,
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: roleColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _role,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: roleColor,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF0FF).withOpacity(0.72),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFD8E2FF)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.format_quote, color: roleColor.withOpacity(0.40), size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '“$_slogan”',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              height: 1.45,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.format_quote, color: roleColor.withOpacity(0.40), size: 22),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _buildSectionCard(
                title: 'THÔNG TIN TỔ CHỨC',
                icon: Icons.account_balance_outlined,
                children: [
                  _buildInfoRow('Đơn vị', _unit),
                  const Divider(height: 1),
                  _buildInfoRow('Chức vụ', _role),
                ],
              ),
              const SizedBox(height: 14),
              _buildContactSection(),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: const Color(0xFF26418F), size: 20),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF26418F),
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.alternate_email, color: Color(0xFF26418F), size: 20),
                ),
                const SizedBox(width: 10),
                Text(
                  'LIÊN HỆ',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF26418F),
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildContactItem(
              icon: Icons.mail_outline,
              label: 'Email',
              value: _email,
            ),
            const SizedBox(height: 16),
            _buildContactItem(
              icon: Icons.phone_outlined,
              label: 'Số điện thoại',
              value: _phone,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF26418F), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
