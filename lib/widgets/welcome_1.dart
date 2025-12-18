import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class WelcomePage1 extends StatefulWidget {
  const WelcomePage1({super.key});

  @override
  State<WelcomePage1> createState() => _WelcomePage1State();
}

class _WelcomePage1State extends State<WelcomePage1> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,

        // ===== BACKGROUND GRADIENT =====
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF59CBEF), Color(0xFF252525)],
            stops: [0.0, 0.58],
          ),
        ),

        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== TEXT AREA =====
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    // by BikeCare
                    Text(
                      'by BikeCare',
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // TITLE
                    Text(
                      'Theo Dõi & Nhắc\nLịch Bảo Dưỡng Xe\nDễ Dàng',
                      style: GoogleFonts.nunito(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.25,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // BUTTON
                    ElevatedButton(
                      onPressed: () {
                        context.push('/welcome-2'); // hoặc route bạn muốn
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF59CBEF),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Bắt đầu',
                        style: GoogleFonts.nunito(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ===== ILLUSTRATION =====
              Expanded(
                child: Center(
                  child: Image.asset(
                    'images/illustration.png',
                    height: 500, // có thể tăng/giảm
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
