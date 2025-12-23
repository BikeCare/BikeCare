import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';


class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // ================= CONTROLLERS =================
  final TextEditingController _usernameCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _brandCtrl = TextEditingController();
  final TextEditingController _fullNameCtrl = TextEditingController();

  String? _vehicleType; // <175cc | >=175cc
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _fullNameCtrl.dispose();
    _passwordCtrl.dispose();
    _emailCtrl.dispose();
    _brandCtrl.dispose();
    super.dispose(); //
  }

  // ================= SUBMIT =================
  Future<void> _handleRegister() async {
    // ===== VALIDATE =====
    if (_usernameCtrl.text.isEmpty ||
        _passwordCtrl.text.isEmpty ||
        _fullNameCtrl.text.isEmpty ||
        _emailCtrl.text.isEmpty ||
        _brandCtrl.text.isEmpty ||
        _vehicleType == null) {
      _showMessage('Vui lòng nhập đầy đủ thông tin');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1️⃣ Tạo user Firebase
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text.trim(),
          );

      // 2️⃣ Gửi email xác thực
      await credential.user!.sendEmailVerification();

      if (!mounted) return;
      setState(() => _isLoading = false);

      // 3️⃣ Chuyển sang trang chờ xác thực
      context.push(
        '/verify-email',
        extra: {
          'username': _usernameCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'password': _passwordCtrl.text.trim(),
          'fullName': _fullNameCtrl.text.trim(),
          'brand': _brandCtrl.text.trim(),
          'vehicleType': _vehicleType!,
        },
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      switch (e.code) {
        case 'email-already-in-use':
          _showMessage('Email đã được sử dụng');
          break;
        case 'weak-password':
          _showMessage('Mật khẩu quá yếu');
          break;
        case 'invalid-email':
          _showMessage('Email không hợp lệ');
          break;
        default:
          _showMessage('Đăng ký thất bại');
      }
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    const Color borderBlue = Color(0xFF59CBEF);
    const Color primaryBlue = Color(0xFF41ACD8);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== PROGRESS =====
              Container(
                height: 6,
                width: 120,
                decoration: BoxDecoration(
                  color: primaryBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              const SizedBox(height: 24),

              // ===== BACK + TITLE =====
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, size: 26),
                    onPressed: () => context.go('/welcome-2'),
                  ),
                  const Spacer(),
                  Text(
                    'Đăng ký',
                    style: GoogleFonts.nunito(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: primaryBlue,
                    ),
                  ),
                  const Spacer(flex: 2),
                ],
              ),

              const SizedBox(height: 32),

              _label('Tài khoản*'),
              _input(_usernameCtrl, borderBlue),

              const SizedBox(height: 20),

              _label('Mật khẩu*'),
              _input(_passwordCtrl, borderBlue, obscure: true),

              const SizedBox(height: 20),

              _label('Họ tên*'),
              _input(_fullNameCtrl, borderBlue),

              const SizedBox(height: 20),

              _label('Email*'),
              _input(_emailCtrl, borderBlue),

              const SizedBox(height: 20),

              _label('Loại xe*'),
              _dropdown(borderBlue),

              const SizedBox(height: 20),

              _label('Hãng xe*'),
              _input(_brandCtrl, borderBlue),

              const SizedBox(height: 36),

              // ===== BUTTON =====
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Đăng ký',
                          style: GoogleFonts.nunito(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFFC107),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= UI WIDGETS =================

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

  Widget _dropdown(Color borderColor) {
    return DropdownButtonFormField<String>(
      initialValue: _vehicleType,
      hint: Text('Chọn loại xe', style: GoogleFonts.nunito(fontSize: 16)),
      style: GoogleFonts.nunito(fontSize: 16, color: Colors.black),
      items: const [
        DropdownMenuItem(value: '<175cc', child: Text('Dưới 175cc')),
        DropdownMenuItem(value: '>=175cc', child: Text('Từ 175cc trở lên')),
      ],
      onChanged: (value) {
        setState(() => _vehicleType = value);
      },
      decoration: _inputDecoration(borderColor).copyWith(
        suffixIcon: Container(
          margin: const EdgeInsets.only(right: 6),
          decoration: BoxDecoration(
            color: borderColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.arrow_drop_down,
            size: 40,
            color: Colors.black,
          ),
        ),
      ),
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
