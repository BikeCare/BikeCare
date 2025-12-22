import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../helpers/utils.dart';

class VerifyEmailPage extends StatefulWidget {
  final Map<String, dynamic> data;

  const VerifyEmailPage({super.key, required this.data});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  Timer? _timer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startChecking();
  }

  void _startChecking() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      await FirebaseAuth.instance.currentUser?.reload();
      final user = FirebaseAuth.instance.currentUser;

      if (user != null && user.emailVerified) {
        timer.cancel();
        _saveToLocalDatabase();
      }
    });
  }

  Future<void> _saveToLocalDatabase() async {
    setState(() => _isLoading = true);

    await registerUser(
      username: widget.data['username'],
      email: widget.data['email'],
      password: widget.data['password'],
      fullName: widget.data['fullName'],
      brand: widget.data['brand'],
      vehicleType: widget.data['vehicleType'],
    );

    if (!mounted) return;

    setState(() => _isLoading = false);
    context.go('/register-success');
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

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
              const SizedBox(height: 24),
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
                    onPressed: () => context.go('/register'),
                  ),
                  const Spacer(),
                  Text(
                    'Xác thực Email',
                    style: GoogleFonts.nunito(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: primaryBlue,
                    ),
                  ),
                  const Spacer(flex: 2),
                ],
              ),

              const SizedBox(height: 48),

              // ===== TEXT =====
              Center(
                child: Text(
                  'Chúng tôi đã gửi email xác thực đến',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(fontSize: 16),
                ),
              ),

              const SizedBox(height: 8),

              Center(
                child: Text(
                  widget.data['email'],
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 24),
              // ===== ICON =====
              Center(
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: borderBlue.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    'images/email_verify.png',
                    width: 80,
                    height: 80,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Center(
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(
                        '(Hãy kiểm tra trong thư mục Spam nếu bạn không nhận được thư của chúng tôi)',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
