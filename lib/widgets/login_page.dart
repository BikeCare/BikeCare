import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _accountController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Màu sắc chủ đạo (Giống trang đăng ký)
    const Color primaryColor = Color(0xFF1D3557);
    const Color cardColor = Color(0xFFA8DADC);
    return Scaffold(
      body: Align(
        alignment: Alignment.center,
        child: Container(
          // Giới hạn chiều rộng để đẹp hơn trên màn hình lớn
          constraints: BoxConstraints(maxWidth: 450),
          // Bọc thêm SingleChildScrollView để tránh lỗi khi bàn phím hiện
          child: SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    // Cập nhật shadow 
                    color: Colors.black,
                    blurRadius: 15,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Đăng nhập',
                    style: TextStyle(
                      fontSize: 30, 
                      fontWeight: FontWeight.bold,
                      color: primaryColor, 
                    ),
                  ),
                  SizedBox(height: 24),
                  TextField(
                    controller: _accountController,
                    decoration: InputDecoration(
                      labelText: 'Tên đăng nhập',
                      labelStyle: TextStyle(
                        fontSize: 16, 
                        color: primaryColor, 
                      ),
                      prefixIcon: Icon(Icons.person_outline, color: primaryColor),
                      filled: true,
                      fillColor: Colors.white, 
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      // Thêm viền khi focus
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryColor, width: 2),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      labelStyle: TextStyle(
                        fontSize: 16,
                        color: primaryColor, 
                      ),
                      prefixIcon: Icon(Icons.lock_outline, color: primaryColor),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      // Thêm viền khi focus
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryColor, width: 2),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      //Chuyển tới dashboard
                      context.go('/dashboard');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                      shadowColor: Colors.black26,
                      minimumSize: Size(double.infinity, 50),
                    ),
                    child: Text(
                      'Đăng nhập',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Chưa có tài khoản? ',
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 17
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          //Chuyển sang trang đăng ký
                          context.push('/register');
                        },
                        child: Text(
                          'Đăng ký ngay',
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
