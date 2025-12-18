import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class RegisterSuccessPage extends StatefulWidget {
  const RegisterSuccessPage({super.key});

  @override
  State<RegisterSuccessPage> createState() => _RegisterSuccessPageState();
}

class _RegisterSuccessPageState extends State<RegisterSuccessPage> {
  @override
  void initState() {
    super.initState();

    // ⏳ Sau 2.5 giây → chuyển về welcome-2
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        context.go('/welcome-2');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ===== ICON CHECK =====
            Container(
              width: 110,
              height: 110,
              decoration: const BoxDecoration(
                color: Color(0xFF7CCAF0),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                size: 60,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 24),

            // ===== TEXT =====
            Text(
              'Bạn đã đăng ký thành công',
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
