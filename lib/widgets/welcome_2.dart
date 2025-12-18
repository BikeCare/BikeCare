import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class WelcomePage2 extends StatefulWidget {
  const WelcomePage2({super.key});

  @override
  State<WelcomePage2> createState() => _WelcomePage2State();
}

class _WelcomePage2State extends State<WelcomePage2> {
  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF6CB6E3);
    const Color imageBg = Color(0xFFEEEEEE);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ===== IMAGE AREA (FULL WIDTH) =====
            Container(
              width: double.infinity,
              color: imageBg,
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 450),
                  child: Image.asset(
                    'images/bike.png',
                    height: 300,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

            // ===== CONTENT AREA =====
            Align(
              alignment: Alignment.center,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 450),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                color: Colors.white,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // TITLE
                    Text(
                      'Xế êm, Lướt mượt !',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        fontSize: 35,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                        shadows: [
                          Shadow(
                            color: Colors.amber.withOpacity(0.8),
                            offset: const Offset(2, 2),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // DESCRIPTION
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: GoogleFonts.nunito(
                          fontSize: 20,
                          color: Colors.black87,
                          height: 1.4,
                          fontStyle: FontStyle.italic,
                        ),
                        children: const [
                          TextSpan(
                            text: 'Đừng để sự cố làm gián đoạn hành trình. ',
                          ),
                          TextSpan(text: 'Hãy để '),
                          TextSpan(
                            text: 'BikeCare',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text:
                                ' giúp bạn ghi nhớ lịch bảo dưỡng định kỳ.',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // LOGIN BUTTON
                    ElevatedButton(
                      onPressed: () => context.push('/login'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Đăng nhập',
                        style: GoogleFonts.nunito(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // REGISTER BUTTON
                    ElevatedButton(
                      onPressed: () => context.push('/register'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue.withOpacity(0.85),
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Đăng ký',
                        style: GoogleFonts.nunito(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
