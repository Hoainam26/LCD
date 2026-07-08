import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/colors.dart';
import '../services/api_service.dart';
import '../utils/validators.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _fullNameError = false;
  bool _emailError = false;
  bool _passwordError = false;
  bool _confirmError = false;

  String _fullNameErrorMessage = '';
  String _emailErrorMessage = '';
  String _passwordErrorMessage = '';
  String _confirmErrorMessage = '';

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  void _validateFullName() {
    setState(() {
      if (!Validators.isNotEmpty(_fullNameController.text)) {
        _fullNameError = true;
        _fullNameErrorMessage = 'Vui lòng nhập họ và tên!';
      } else {
        _fullNameError = false;
        _fullNameErrorMessage = '';
      }
    });
  }

  void _validateEmail() {
    setState(() {
      if (!Validators.isNotEmpty(_emailController.text)) {
        _emailError = true;
        _emailErrorMessage = 'Vui lòng nhập email!';
      } else if (!Validators.isValidEmail(_emailController.text)) {
        _emailError = true;
        _emailErrorMessage = 'Email không hợp lệ!';
      } else {
        _emailError = false;
        _emailErrorMessage = '';
      }
    });
  }

  void _validatePassword() {
    setState(() {
      if (!Validators.isNotEmpty(_passwordController.text)) {
        _passwordError = true;
        _passwordErrorMessage = 'Vui lòng nhập mật khẩu!';
      } else if (!Validators.isValidPassword(_passwordController.text)) {
        _passwordError = true;
        _passwordErrorMessage = 'Mật khẩu phải có ít nhất 6 ký tự!';
      } else {
        _passwordError = false;
        _passwordErrorMessage = '';
      }
    });
  }

  void _validateConfirmPassword() {
    setState(() {
      if (!Validators.isNotEmpty(_confirmPasswordController.text)) {
        _confirmError = true;
        _confirmErrorMessage = 'Vui lòng nhập lại mật khẩu!';
      } else if (_confirmPasswordController.text != _passwordController.text) {
        _confirmError = true;
        _confirmErrorMessage = 'Mật khẩu xác nhận không khớp!';
      } else {
        _confirmError = false;
        _confirmErrorMessage = '';
      }
    });
  }

  Future<void> _handleSignup() async {
    _validateFullName();
    _validateEmail();
    _validatePassword();
    _validateConfirmPassword();

    if (_fullNameError || _emailError || _passwordError || _confirmError) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await ApiService.signup(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      fullName: _fullNameController.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result['success'] == false) {
      final message = result['message'] ?? 'Đăng ký thất bại';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đăng ký thành công. Vui lòng đăng nhập.'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );

    Navigator.pop(context);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Tạo tài khoản',
          style: GoogleFonts.playfairDisplay(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1E3A8A),
              Color(0xFF3B82F6),
              Color(0xFF14B8A6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đăng ký đoàn viên mới',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tạo tài khoản để tham gia các hoạt động đoàn và xem điểm rèn luyện.',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Họ và tên'),
                      const SizedBox(height: 10),
                      _buildTextField(
                        controller: _fullNameController,
                        hintText: 'Nhập họ và tên',
                        icon: Icons.person_outline,
                        hasError: _fullNameError,
                        onClear: () {
                          _fullNameController.clear();
                          setState(() {
                            _fullNameError = false;
                            _fullNameErrorMessage = '';
                          });
                        },
                      ),
                      if (_fullNameError) _buildError(_fullNameErrorMessage),
                      const SizedBox(height: 16),
                      _buildLabel('Email'),
                      const SizedBox(height: 10),
                      _buildTextField(
                        controller: _emailController,
                        hintText: 'Nhập email',
                        icon: Icons.email_outlined,
                        hasError: _emailError,
                        onClear: () {
                          _emailController.clear();
                          setState(() {
                            _emailError = false;
                            _emailErrorMessage = '';
                          });
                        },
                      ),
                      if (_emailError) _buildError(_emailErrorMessage),
                      const SizedBox(height: 16),
                      _buildLabel('Mật khẩu'),
                      const SizedBox(height: 10),
                      _buildPasswordField(
                        controller: _passwordController,
                        hintText: 'Nhập mật khẩu',
                        obscureText: _obscurePassword,
                        hasError: _passwordError,
                        onToggle: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      if (_passwordError) _buildError(_passwordErrorMessage),
                      const SizedBox(height: 16),
                      _buildLabel('Xác nhận mật khẩu'),
                      const SizedBox(height: 10),
                      _buildPasswordField(
                        controller: _confirmPasswordController,
                        hintText: 'Nhập lại mật khẩu',
                        obscureText: _obscureConfirmPassword,
                        hasError: _confirmError,
                        onToggle: () {
                          setState(() {
                            _obscureConfirmPassword =
                                !_obscureConfirmPassword;
                          });
                        },
                      ),
                      if (_confirmError) _buildError(_confirmErrorMessage),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSignup,
                          child: _isLoading
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                )
                              : const Text('Đăng ký'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return RichText(
      text: TextSpan(
        children: [
          const TextSpan(
            text: '* ',
            style: TextStyle(
              color: AppColors.danger,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(
            text: text,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required bool hasError,
    required VoidCallback onClear,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: (_) {
          setState(() {});
        },
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Icon(
              icon,
              color: hasError ? AppColors.danger : Colors.grey[400],
              size: 20,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 0,
            minHeight: 0,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: GestureDetector(
                    onTap: onClear,
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.grey[400],
                      size: 20,
                    ),
                  ),
                )
              : null,
          suffixIconConstraints: const BoxConstraints(
            minWidth: 0,
            minHeight: 0,
          ),
          filled: true,
          fillColor: const Color(0xFFF1F5F9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: hasError ? AppColors.danger : AppColors.borderColor,
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: hasError ? AppColors.danger : AppColors.borderColor,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: AppColors.primary,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    required bool obscureText,
    required bool hasError,
    required VoidCallback onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        onChanged: (_) {
          setState(() {});
        },
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Icon(
              Icons.lock_outline,
              color: hasError ? AppColors.danger : Colors.grey[400],
              size: 20,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 0,
            minHeight: 0,
          ),
          suffixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: GestureDetector(
              onTap: onToggle,
              child: Icon(
                obscureText ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey[400],
                size: 20,
              ),
            ),
          ),
          suffixIconConstraints: const BoxConstraints(
            minWidth: 0,
            minHeight: 0,
          ),
          filled: true,
          fillColor: const Color(0xFFF1F5F9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: hasError ? AppColors.danger : AppColors.borderColor,
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: hasError ? AppColors.danger : AppColors.borderColor,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: AppColors.primary,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildError(String message) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.danger, size: 16),
            const SizedBox(width: 6),
            Text(
              message,
              style: const TextStyle(
                color: AppColors.danger,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
