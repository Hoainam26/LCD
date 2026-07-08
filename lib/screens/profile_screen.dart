import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (result == true) {
      await ApiService.signout();

      // Đóng ProfileScreen nếu có
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Điều hướng về Login và xóa toàn bộ stack
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Cá nhân'),
        backgroundColor: AppColors.surfaceColor,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
                const CircleAvatar(
                  radius: 32,
                  backgroundImage: AssetImage('assets/images/logo.jpg'),
                ),
                colors: [AppColors.primary, AppColors.primaryLight],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 32,
                  backgroundImage: AssetImage('assets/images/logo.jpg'),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nguyễn Văn A',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'CNTT 1601 • 1694081',
                        style: TextStyle(fontSize: 13, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.verified, color: Colors.white),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _buildSection(
            title: 'Tài khoản',
            children: [
              _buildItem(Icons.person_outline, 'Thông tin cá nhân'),
              _buildItem(Icons.lock_outline, 'Đổi mật khẩu'),
            ],
          ),
          const SizedBox(height: 12),

          _buildSection(
            title: 'Khác',
            children: [
              _buildItem(
                Icons.logout,
                'Đăng xuất',
                isDanger: true,
                onTap: () => _logout(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              title,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildItem(
    IconData icon,
    String title, {
    VoidCallback? onTap,
    bool isDanger = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDanger ? AppColors.danger : AppColors.primary,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDanger ? AppColors.danger : AppColors.textPrimary,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
