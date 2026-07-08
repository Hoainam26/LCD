import 'package:flutter/material.dart';
import '../constants/colors.dart';
import 'member_login_screen.dart';
import 'officer_login_screen.dart';
import 'admin_login_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double maxWidth =
                  constraints.maxWidth > 600 ? 600 : constraints.maxWidth;

              return ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  child: Column(
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 20),
                      _buildTabs(),
                      const SizedBox(height: 16),
                      _buildLoginForm(),
                      const SizedBox(height: 20),
                      _buildFooter(context),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          'assets/images/logo12.png',
          width: 90,
          height: 90,
          fit: BoxFit.cover,
        ),
        const SizedBox(height: 12),
        Text(
          'Khoa CNTT trường Đại học Đại Nam',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Khoa CNTT trường Đại học Đại Nam',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: 64,
          height: 4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.accent],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return Column(
      children: [
        Row(
          children: [
            _buildTab('Đoàn viên', 0),
            _buildTab('Cán bộ Đoàn', 1),
            _buildTab('Admin', 2),
          ],
        ),
        Container(
          height: 1,
          color: AppColors.borderColor,
        ),
      ],
    );
  }

  Widget _buildTab(String title, int index) {
    final bool isSelected = _selectedTab == index;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color:
                  isSelected ? AppColors.primary : AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    if (_selectedTab == 0) {
      return const MemberLoginScreen();
    }
    if (_selectedTab == 1) {
      return const OfficerLoginScreen();
    }
    return const AdminLoginScreen();
  }

  Widget _buildFooter(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),
        const Text(
          '© 2026 Khoa Công nghệ Thông tin - Đoàn TNCS Hồ Chí Minh',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
