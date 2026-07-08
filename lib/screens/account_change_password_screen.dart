import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../services/api_service.dart';
import '../utils/validators.dart';

class AccountChangePasswordScreen extends StatefulWidget {
  const AccountChangePasswordScreen({super.key});

  @override
  State<AccountChangePasswordScreen> createState() =>
      _AccountChangePasswordScreenState();
}

class _AccountChangePasswordScreenState
    extends State<AccountChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_currentController.text.trim() == _newController.text.trim()) {
      _showSnack('Mật khẩu mới không được trùng mật khẩu cũ');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final result = await ApiService.changePassword(
      currentPassword: _currentController.text,
      newPassword: _newController.text,
      confirmPassword: _confirmController.text,
    );

    if (!mounted) return;

    if (result['success'] == false) {
      _showSnack(
        result['message']?.toString() ?? 'Đổi mật khẩu thất bại',
      );
    } else {
      _showSnack('Đổi mật khẩu thành công', success: true);
      _currentController.clear();
      _newController.clear();
      _confirmController.clear();
    }

    if (!mounted) return;
    setState(() {
      _isSaving = false;
    });
  }

  void _showSnack(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? AppColors.success : AppColors.danger,
      ),
    );
  }

  String _passwordStrengthHint(String value) {
    if (value.trim().isEmpty) return '';
    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(value);
    final hasNumber = RegExp(r'\d').hasMatch(value);
    if (value.length < 8 || !hasLetter || !hasNumber) {
      return 'Mật khẩu bảo mật thấp. Nên có ít nhất 8 ký tự, chữ và số.';
    }
    return 'Mật khẩu đủ mạnh.';
  }

  @override
  Widget build(BuildContext context) {
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
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        ),
        title: const Text(
          'Đổi mật khẩu',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: false,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 14),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF1E3A8A),
              child: Icon(Icons.person, size: 18, color: Colors.white),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x140F172A),
                    blurRadius: 24,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPasswordField(
                    controller: _currentController,
                    label: 'Mật khẩu hiện tại',
                    obscure: _obscureCurrent,
                    onToggle: () {
                      setState(() {
                        _obscureCurrent = !_obscureCurrent;
                      });
                    },
                    onChanged: (_) => setState(() {}),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập mật khẩu hiện tại';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildPasswordField(
                    controller: _newController,
                    label: 'Mật khẩu mới',
                    obscure: _obscureNew,
                    onToggle: () {
                      setState(() {
                        _obscureNew = !_obscureNew;
                      });
                    },
                    onChanged: (_) => setState(() {}),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập mật khẩu mới';
                      }
                      if (value.trim() == _currentController.text.trim()) {
                        return 'Mật khẩu mới không được trùng mật khẩu cũ';
                      }
                      if (!Validators.isValidPassword(value)) {
                        return 'Mật khẩu tối thiểu 6 ký tự';
                      }
                      return null;
                    },
                  ),
                  if (_newController.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _passwordStrengthHint(_newController.text),
                        style: TextStyle(
                          fontSize: 12,
                          color: _passwordStrengthHint(_newController.text)
                                  .contains('thấp')
                              ? AppColors.danger
                              : AppColors.success,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  _buildPasswordField(
                    controller: _confirmController,
                    label: 'Xác nhận mật khẩu mới',
                    obscure: _obscureConfirm,
                    onToggle: () {
                      setState(() {
                        _obscureConfirm = !_obscureConfirm;
                      });
                    },
                    onChanged: (_) => setState(() {}),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng xác nhận mật khẩu';
                      }
                      if (value != _newController.text) {
                        return 'Mật khẩu không đúng, vui lòng thử lại';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Cập nhật mật khẩu',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    ValueChanged<String>? onChanged,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      style: const TextStyle(
        fontSize: 15,
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      controller: controller,
      obscureText: obscure,
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
        floatingLabelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
        prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: AppColors.textSecondary,
          ),
        ),
        filled: true,
        fillColor: const Color(0xFFF5F7FF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFF5F7FF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
