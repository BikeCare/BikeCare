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
  final _accountController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _accountController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /* ===================== HANDLERS ===================== */

  Future<void> _handleLogin() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final user = await loginUser(
        username: _accountController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;

      if (user != null) {
        context.go(
          '/homepage',
          extra: user, //
        );
      } else {
        _showMessage('Sai username hoặc mật khẩu');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  /* ===================== UI ===================== */

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF41ACD8);
    const Color borderBlue = Color(0xFF59CBEF);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== PROGRESS =====
              const SizedBox(height: 24),
              Container(
                height: 6,
                width: 120,
                decoration: BoxDecoration(
                  color: primaryBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              const SizedBox(height: 100),

              // ===== TITLE =====
              Center(
                child: Text(
                  'Đăng nhập',
                  style: GoogleFonts.nunito(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: primaryBlue,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              _label('Tài khoản*'),
              _input(_accountController, borderBlue),

              const SizedBox(height: 20),

              _label('Mật khẩu*'),
              _input(_passwordController, borderBlue, obscure: true),

              const SizedBox(height: 36),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Quên mật khẩu',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),

              const SizedBox(height: 36),

              // ===== LOGIN BUTTON =====
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
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
              ),

              const SizedBox(height: 24),

              // ===== REGISTER LINK =====
              Row(
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  /* ===================== UI REUSE ===================== */

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
      decoration: _inputDecoration(borderColor),
    );
  }

  InputDecoration _inputDecoration(Color borderColor) {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor, width: 2),
      ),
    );
  }
}
