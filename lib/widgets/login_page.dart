import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../helpers/utils.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // ================= CONTROLLERS =================
  final TextEditingController _accountCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();

  bool _isLoading = false;

  // ================= LIFECYCLE =================
  @override
  void dispose() {
    _accountCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ================= HANDLER =================
  Future<void> _handleLogin() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final user = await loginUser(
        username: _accountCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );

      if (!mounted) return;

      if (user != null) {
        context.go('/homepage', extra: user);
      } else {
        _showMessage('Sai username hoặc mật khẩu');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
              const SizedBox(height: 24),
              _buildLoginButton(primaryBlue),
              const SizedBox(height: 24),
              _buildRegisterLink(),
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
        onPressed: () => context.go('/welcome-2'),
      ),
      const Spacer(),
      Text(
        'Đăng nhập',
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
      _input(_accountCtrl, borderColor),
      const SizedBox(height: 20),
      _label('Mật khẩu*'),
      _input(_passwordCtrl, borderColor, obscure: true),
      const SizedBox(height: 10),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: () => context.push('/forgot-password'),
          child: const Text(
            'Quên mật khẩu',
            style: TextStyle(decoration: TextDecoration.underline),
          ),
        ),
      ),
    ],
  );

  Widget _buildLoginButton(Color color) => SizedBox(
    width: double.infinity,
    height: 56,
    child: ElevatedButton(
      onPressed: _isLoading ? null : _handleLogin,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      child: _isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : Text(
              'Đăng nhập',
              style: GoogleFonts.nunito(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFFC107),
              ),
            ),
    ),
  );

  Widget _buildRegisterLink() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Text('Bạn chưa có tài khoản?'),
      TextButton(
        onPressed: () => context.push('/register'),
        child: const Text(
          'Đăng ký',
          style: TextStyle(color: Color(0xFFFFC107)),
        ),
      ),
    ],
  );

  // ================= REUSABLE =================

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w600),
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
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
