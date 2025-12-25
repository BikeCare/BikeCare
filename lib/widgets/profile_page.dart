import 'package:flutter/material.dart';
import '../helpers/utils.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

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
  String? _avatarPath;

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
      _avatarPath = (u?['avatar_image'] ?? widget.user['avatar_image'] ?? '')
          .toString();

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
        avatarImage: _avatarPath,
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

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Thay đổi ảnh đại diện',
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(
                Icons.photo_library_rounded,
                color: Color(0xFF2E8EC7),
              ),
              title: Text(
                'Chọn từ Thư viện',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
              ),
              onTap: () async {
                Navigator.pop(context);
                final picker = ImagePicker();
                final XFile? image = await picker.pickImage(
                  source: ImageSource.gallery,
                );
                if (image != null) _handleImageSelected(image.path);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.camera_alt_rounded,
                color: Color(0xFF2E8EC7),
              ),
              title: Text(
                'Chụp ảnh mới',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
              ),
              onTap: () async {
                Navigator.pop(context);
                final picker = ImagePicker();
                final XFile? image = await picker.pickImage(
                  source: ImageSource.camera,
                );
                if (image != null) _handleImageSelected(image.path);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _handleImageSelected(String path) {
    setState(() {
      _avatarPath = path;
      if (!_isEditing) {
        _isEditing = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 15, 20, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x08000000),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hồ sơ của bạn',
                    style: GoogleFonts.nunito(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF2E8EC7),
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    'Quản lý thông tin cá nhân và xe của bạn',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Card trắng bên dưới
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                child: Column(
                  children: [
                    // Avatar + nút edit ở góc phải
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        InkWell(
                          onTap: _pickImage,
                          borderRadius: BorderRadius.circular(70),
                          child: _buildAvatar(),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(15),
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
                                color: const Color(0xFF2E8EC7),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF2E8EC7,
                                    ).withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : Icon(
                                      _isEditing
                                          ? Icons.check
                                          : Icons.edit_rounded,
                                      size: 18,
                                      color: Colors.white,
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
                      style: GoogleFonts.nunito(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF333333),
                      ),
                    ),

                    const SizedBox(height: 14),
                    _buildStatsRow(),
                    const SizedBox(height: 25),

                    _buildSectionTitle('Thông tin cá nhân'),
                    const SizedBox(height: 15),

                    _input(
                      _phoneCtl,
                      label: 'Số điện thoại',
                      icon: Icons.phone_android_rounded,
                      enabled: _isEditing,
                    ),
                    const SizedBox(height: 15),
                    _input(
                      _locationCtl,
                      label: 'Vị trí',
                      icon: Icons.location_on_rounded,
                      enabled: _isEditing,
                    ),
                    const SizedBox(height: 15),
                    _input(
                      _emailCtl,
                      label: 'Email',
                      icon: Icons.email_rounded,
                      enabled: _isEditing,
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: _input(
                            _dobCtl,
                            label: 'Ngày sinh',
                            icon: Icons.cake_rounded,
                            enabled: _isEditing,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _input(
                            _genderCtl,
                            label: 'Giới tính',
                            icon: Icons.person_outline_rounded,
                            enabled: _isEditing,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),
                    _buildSectionTitle('Hỗ trợ & Pháp lý'),
                    const SizedBox(height: 10),
                    _buildActionItem(
                      'Điều khoản dịch vụ',
                      Icons.description_outlined,
                      () {},
                    ),
                    _buildActionItem(
                      'Chính sách quyền riêng tư',
                      Icons.security_outlined,
                      () {},
                    ),

                    const SizedBox(height: 35),
                    // NÚT ĐĂNG XUẤT
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: () => context.go('/login'),
                        icon: const Icon(
                          Icons.logout_rounded,
                          color: Colors.redAccent,
                        ),
                        label: const Text(
                          'Đăng xuất',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Colors.redAccent,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: Colors.redAccent.withOpacity(0.05),
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

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: GoogleFonts.nunito(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF333333),
        ),
      ),
    );
  }

  Widget _buildActionItem(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.grey[700], size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
    );
  }

  // =========================
  // AVATAR WIDGET  ✅ DÁN Ở ĐÂY
  // =========================
  Widget _buildAvatar() {
    final avatar = _avatarPath ?? '';

    ImageProvider? provider;
    if (avatar.isNotEmpty) {
      if (avatar.startsWith('http')) {
        provider = NetworkImage(avatar);
      } else if (File(avatar).existsSync()) {
        provider = FileImage(File(avatar));
      }
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF2E8EC7).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: CircleAvatar(
        radius: 65,
        backgroundColor: Colors.grey.shade100,
        backgroundImage: provider,
        child: provider == null
            ? ClipOval(
                child: Image.asset(
                  'images/avatar.png',
                  width: 130,
                  height: 130,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.person, size: 70, color: Colors.grey),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _statColumn(Icons.directions_bike_rounded, '$_vehicleCount xe', () {}),
        _statColumn(
          Icons.favorite_rounded,
          'Yêu thích',
          () => context.push('/favorites'),
        ),
        _statColumn(Icons.star_rounded, 'Đánh giá', () => _showMyReviews()),
      ],
    );
  }

  Widget _statColumn(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF92D6E3), size: 32),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF333333),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMyReviews() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return FutureBuilder<List<Map<String, dynamic>>>(
              future: getUserReviews(_fullName), // Lấy review theo tên
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Lỗi: ${snapshot.error}'));
                }

                final reviews = snapshot.data ?? [];
                if (reviews.isEmpty) {
                  return const Center(
                    child: Text(
                      'Bạn chưa có đánh giá nào',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                return Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Đánh giá của bạn (${reviews.length})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: reviews.length,
                        itemBuilder: (context, index) {
                          final r = reviews[index];
                          return ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.amber,
                              child: Icon(Icons.star, color: Colors.white),
                            ),
                            title: Text(
                              r['garage_name'] ??
                                  'Gara không xác định', // Tên gara
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r['comment'] ?? ''),
                                const SizedBox(height: 4),
                                Text(
                                  r['created_at'] != null
                                      ? r['created_at'].substring(0, 10)
                                      : '',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${r['rating'] ?? 0} ★',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _input(
    TextEditingController controller, {
    required String label,
    required IconData icon,
    required bool enabled,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: const Color(0xFF2E8EC7)),
        labelStyle: TextStyle(
          color: Colors.grey[500],
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2E8EC7), width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[100]!),
        ),
      ),
    );
  }
}
