import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/colors.dart';
import '../services/api_service.dart';
import '../services/app_state_service.dart';
import '../utils/validators.dart';

class AccountEmailScreen extends StatefulWidget {
  const AccountEmailScreen({super.key});

  @override
  State<AccountEmailScreen> createState() => _AccountEmailScreenState();
}

class _AccountEmailScreenState extends State<AccountEmailScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();

  bool _isUpdating = false;
  bool _isConfirming = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AppStateService>(context, listen: false)
          .currentUser;
      if (user != null) {
        _emailController.text = user['email']?.toString() ?? '';
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _updateEmail() async {
    final email = _emailController.text.trim();
    if (!Validators.isValidEmail(email)) {
      _showSnack('Email khong hop le');
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    final result = await ApiService.updateEmail(email: email);

    if (!mounted) return;

    if (result['success'] == false) {
      _showSnack(result['message']?.toString() ?? 'Cap nhat email that bai');
    } else {
      _showSnack('Cap nhat email thanh cong', success: true);
      await Provider.of<AppStateService>(context, listen: false)
          .refreshCurrentUser();
    }

    if (!mounted) return;
    setState(() {
      _isUpdating = false;
    });
  }

  Future<void> _confirmEmail() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      _showSnack('Vui long nhap ma xac nhan');
      return;
    }

    setState(() {
      _isConfirming = true;
    });

    final result = await ApiService.confirmEmail(code: code);

    if (!mounted) return;

    if (result['success'] == false) {
      _showSnack(result['message']?.toString() ?? 'Xac nhan email that bai');
    } else {
      _showSnack('Xac nhan email thanh cong', success: true);
    }

    if (!mounted) return;
    setState(() {
      _isConfirming = false;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Cap nhat email'),
        backgroundColor: AppColors.surfaceColor,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle('Email moi'),
          const SizedBox(height: 12),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email',
              prefixIcon: const Icon(Icons.email_outlined),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isUpdating ? null : _updateEmail,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isUpdating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Gui yeu cau'),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Xac nhan email'),
          const SizedBox(height: 12),
          TextField(
            controller: _codeController,
            decoration: InputDecoration(
              labelText: 'Ma xac nhan',
              prefixIcon: const Icon(Icons.verified_outlined),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isConfirming ? null : _confirmEmail,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isConfirming
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Xac nhan'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }
}
