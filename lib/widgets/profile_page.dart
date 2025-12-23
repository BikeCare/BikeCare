import 'package:flutter/material.dart';
import '../helpers/utils.dart';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import 'app_bottom_nav.dart';

class UserProfilePage extends StatefulWidget {
  final Map<String, dynamic> user; // nhận user từ router extra
  const UserProfilePage({super.key, required this.user});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  bool _isEditing = false;
  bool _isSaving = false;

  late final String userId;

  // controllers
  final _phoneCtl = TextEditingController();
  final _locationCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  final _dobCtl = TextEditingController();
  final _genderCtl = TextEditingController();
  String _fullName = '';

  int _vehicleCount = 0;

  @override
  void initState() {
    super.initState();
    userId = widget.user['user_id'].toString();
    _loadProfile();
  }

  @override
  void dispose() {
    _phoneCtl.dispose();
    _locationCtl.dispose();
    _emailCtl.dispose();
    _dobCtl.dispose();
    _genderCtl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final u = await getUserById(userId);
    final vehicles = await getUserVehicles(userId);

    if (!mounted) return;

    setState(() {
      _fullName = (u?['full_name'] ?? widget.user['full_name'] ?? '')
          .toString();
      _phoneCtl.text = (u?['phone'] ?? '').toString();
      _locationCtl.text = (u?['location'] ?? '').toString();
      _emailCtl.text = (u?['email'] ?? widget.user['email'] ?? '').toString();
      _dobCtl.text = (u?['date_of_birth'] ?? '').toString();
      _genderCtl.text = (u?['gender'] ?? '').toString();

      _vehicleCount = vehicles.length;
    });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await updateUserProfile(
        userId: userId,
        phone: _phoneCtl.text.trim(),
        location: _locationCtl.text.trim(),
        email: _emailCtl.text.trim(),
        dateOfBirth: _dobCtl.text.trim(),
        gender: _genderCtl.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        _isEditing = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã lưu thông tin')));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi lưu thông tin: $e')));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: AppBottomNav(user: widget.user),
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Text(
                'Tài khoản người dùng',
                style: GoogleFonts.nunito(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3C9CC3),
                ),
              ),
            ),
            // Card trắng bên dưới
            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Avatar + nút edit ở góc phải
                      Stack(
                        children: [
                          Center(child: _buildAvatar()),
                          Positioned(
                            right: 0,
                            top: 8,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                if (_isEditing) {
                                  _save();
                                } else {
                                  setState(() => _isEditing = true);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.black,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.white,
                                ),
                                child: _isSaving
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.black,
                                              ),
                                        ),
                                      )
                                    : Icon(
                                        _isEditing
                                            ? Icons.check
                                            : Icons.edit_outlined,
                                        size: 22,
                                        color: Colors.black,
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Tên màu vàng
                      Text(
                        _fullName.isEmpty ? '---' : _fullName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFF2C94C),
                        ),
                      ),

                      const SizedBox(height: 14),
                      _buildStatsRow(),
                      const SizedBox(height: 18),

                      // Form fields
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _label('Số điện thoại'),
                      ),
                      _input(
                        _phoneCtl,
                        hint: '0908XXXXXX',
                        enabled: _isEditing,
                      ),

                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _label('Vị trí'),
                      ),
                      _input(
                        _locationCtl,
                        hint: 'Nhập vị trí của bạn',
                        enabled: _isEditing,
                      ),

                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _label('Email'),
                      ),
                      _input(
                        _emailCtl,
                        hint: 'Nhập email của bạn',
                        enabled: _isEditing,
                      ),

                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _label('Ngày sinh'),
                      ),
                      _input(_dobCtl, hint: '11/12/20XX', enabled: _isEditing),

                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _label('Giới tính'),
                      ),
                      _input(_genderCtl, hint: 'Nữ', enabled: _isEditing),

                      const SizedBox(height: 18),

                      // Links
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Hỗ trợ và phản hồi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _linkItem('Điều khoản dịch vụ'),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _linkItem('Chính sách quyền riêng tư'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // AVATAR WIDGET  ✅ DÁN Ở ĐÂY
  // =========================
  Widget _buildAvatar() {
    final avatar = (widget.user['avatar_image'] ?? '').toString();

    ImageProvider? provider;
    if (avatar.isNotEmpty) {
      if (avatar.startsWith('http')) {
        provider = NetworkImage(avatar);
      } else if (File(avatar).existsSync()) {
        provider = FileImage(File(avatar));
      }
    }

    return CircleAvatar(
      radius: 60,
      backgroundColor: Colors.grey.shade300,
      backgroundImage: provider,
      child: provider == null
          ? ClipOval(
              child: Image.asset(
                'images/avatar.png',
                width: 120,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.person, size: 60, color: Colors.white),
              ),
            )
          : null,
    );
  }

  Widget _buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _statItem(Icons.directions_bike, '$_vehicleCount xe'),
        _statItem(Icons.favorite, 'Yêu thích'),
        _statItem(Icons.stars_rounded, 'Đánh giá'),
      ],
    );
  }

  Widget _statItem(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF92D6E3), size: 30),
        const SizedBox(height: 6),
        Text(
          text,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      t,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
    ),
  );

  Widget _input(
    TextEditingController c, {
    required String hint,
    required bool enabled,
  }) {
    return TextField(
      controller: c,
      enabled: enabled,
      decoration: InputDecoration(
        hintText: hint,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF92D6E3)),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  Widget _linkItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chức năng sẽ cập nhật sau')),
          );
        },
        child: Text(
          text,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
      ),
    );
  }
}
