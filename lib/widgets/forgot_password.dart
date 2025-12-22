import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../helpers/utils.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  // ================= CONTROLLERS =================
  final TextEditingController _usernameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _newPasswordCtrl = TextEditingController();

  bool _isLoading = false;

  // ================= LIFECYCLE =================
  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _newPasswordCtrl.dispose();
    super.dispose();
  }

  // ================= HANDLER =================
  Future<void> _handleResetPassword() async {
    if (_isLoading) return;

    if (_usernameCtrl.text.isEmpty ||
        _emailCtrl.text.isEmpty ||
        _newPasswordCtrl.text.isEmpty) {
      _showMessage('Vui lòng nhập đầy đủ thông tin');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await resetPassword(
        username: _usernameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        newPassword: _newPasswordCtrl.text.trim(),
      );

      if (!mounted) return;

      if (success) {
        _showMessage('Đặt lại mật khẩu thành công');
        context.go('/login');
      } else {
        _showMessage('Username hoặc email không đúng');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF41ACD8);
    const borderBlue = Color(0xFF59CBEF);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 50),
              _buildProgress(primaryBlue),
              const SizedBox(height: 50),
              _buildTitle(context, primaryBlue),
              const SizedBox(height: 32),
              _buildForm(borderBlue),
              const SizedBox(height: 32),
              _buildResetButton(primaryBlue),
            ],
          ),
        ),
      ),
    );
  }

  // ================= UI SECTIONS =================

  Widget _buildProgress(Color color) => Container(
        height: 6,
        width: 120,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
      );

  Widget _buildTitle(BuildContext context, Color color) => Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 26),
            onPressed: () => context.go('/login'),
          ),
          const Spacer(),
          Text(
            'Quên mật khẩu',
            style: GoogleFonts.nunito(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const Spacer(flex: 2),
        ],
      );

  Widget _buildForm(Color borderColor) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Tài khoản*'),
          _input(_usernameCtrl, borderColor),
          const SizedBox(height: 20),
          _label('Email*'),
          _input(_emailCtrl, borderColor),
          const SizedBox(height: 20),
          _label('Mật khẩu mới*'),
          _input(_newPasswordCtrl, borderColor, obscure: true),
        ],
      );

  Widget _buildResetButton(Color color) => SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _handleResetPassword,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(
                  'Đặt lại mật khẩu',
                  style: GoogleFonts.nunito(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFFC107),
                  ),
                ),
        ),
      );

  // ================= REUSABLE =================

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  Widget _input(
    TextEditingController controller,
    Color borderColor, {
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: GoogleFonts.nunito(fontSize: 16),
      decoration: InputDecoration(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: _border(borderColor),
        enabledBorder: _border(borderColor),
        focusedBorder: _border(borderColor, width: 2),
      ),
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );
}
