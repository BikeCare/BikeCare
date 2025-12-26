import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import intl để format ngày
import '../helpers/utils.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'terms_of_service_page.dart';
import 'privacy_policy_page.dart';

// --- STYLE CONSTANTS (Đồng bộ) ---
const Color kPrimaryColor = Color(0xFF2E8EC7);
const Color kTextDark = Color(0xFF111111);
const Color kTextGrey = Color(0xFF636E72);
const Color kBorderColor = Color(0xFFE0E0E0);

class UserProfilePage extends StatefulWidget {
  final Map<String, dynamic> user;
  final Function(int)? onSwitchTab;

  const UserProfilePage({
    super.key,
    required this.user,
    this.onSwitchTab,
  });

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  bool _isEditing = false;
  bool _isSaving = false;

  late final String userId;

  final _phoneCtl = TextEditingController();
  final _locationCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  
  // Controller hiển thị ngày sinh (dạng dd/MM/yyyy)
  final _dobDisplayCtl = TextEditingController(); 
  
  String _fullName = '';
  String? _avatarPath;

  // Biến lưu giá trị thực tế để gửi đi
  DateTime? _selectedDate;
  String? _selectedGender; 

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
    _dobDisplayCtl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    // Gọi hàm lấy dữ liệu thật từ DB
    final u = await getUserById(userId);
    final vehicles = await getUserVehicles(userId);

    if (!mounted) return;

    setState(() {
      // Load các trường text thông thường
      _fullName = (u?['full_name'] ?? widget.user['full_name'] ?? '').toString();
      _phoneCtl.text = (u?['phone'] ?? '').toString();
      _locationCtl.text = (u?['location'] ?? '').toString();
      _emailCtl.text = (u?['email'] ?? widget.user['email'] ?? '').toString();
      _avatarPath = (u?['avatar_image'] ?? widget.user['avatar_image'] ?? '').toString();

      // --- Xử lý Ngày Sinh ---
      String dobRaw = (u?['date_of_birth'] ?? '').toString();
      if (dobRaw.isNotEmpty) {
        try {
          // Parse từ ISO string (YYYY-MM-DD)
          _selectedDate = DateTime.parse(dobRaw);
          _dobDisplayCtl.text = DateFormat('dd/MM/yyyy').format(_selectedDate!);
        } catch (_) {
          _dobDisplayCtl.text = dobRaw; // Fallback nếu lỗi format
        }
      } else {
        _dobDisplayCtl.text = '';
        _selectedDate = null;
      }

      // --- Xử lý Giới Tính ---
      String genderRaw = (u?['gender'] ?? '').toString();
      // Chỉ nhận các giá trị hợp lệ, nếu không thì để null (hiện hint)
      if (['Nam', 'Nữ', 'Khác'].contains(genderRaw)) {
        _selectedGender = genderRaw;
      } else {
        _selectedGender = null;
      }

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
        // Lưu ngày sinh dạng chuẩn ISO
        dateOfBirth: _selectedDate?.toIso8601String(),
        gender: _selectedGender,
        avatarImage: _avatarPath,
      );

      if (!mounted) return;
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã lưu thông tin')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi lưu thông tin: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickDate() async {
    if (!_isEditing) return; // Chỉ cho chọn khi đang ở chế độ sửa

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: kPrimaryColor, // Màu header lịch
              onPrimary: Colors.white,
              onSurface: kTextDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dobDisplayCtl.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text('Thay đổi ảnh đại diện', style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: kPrimaryColor),
              title: Text('Chọn từ Thư viện', style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
              onTap: () async {
                Navigator.pop(context);
                final picker = ImagePicker();
                final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                if (image != null) _handleImageSelected(image.path);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: kPrimaryColor),
              title: Text('Chụp ảnh mới', style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
              onTap: () async {
                Navigator.pop(context);
                final picker = ImagePicker();
                final XFile? image = await picker.pickImage(source: ImageSource.camera);
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
      if (!_isEditing) _isEditing = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Thông tin của bạn",
          style: TextStyle(
            color: kTextDark,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: kBorderColor, height: 1),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadProfile,
          color: kPrimaryColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
            child: Column(
              children: [
                // Avatar
                Stack(
                  alignment: Alignment.center,
                  children: [
                    InkWell(
                      onTap: _pickImage,
                      borderRadius: BorderRadius.circular(70),
                      child: _buildAvatar(),
                    ),
                    Positioned(
                      right: 0, bottom: 0,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(15),
                        onTap: () {
                          if (_isEditing) _save();
                          else setState(() => _isEditing = true);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: kPrimaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(color: kPrimaryColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: _isSaving
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                              : Icon(_isEditing ? Icons.check : Icons.edit_rounded, size: 18, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                
                // Tên người dùng
                Text(
                  _fullName.isEmpty ? '---' : _fullName,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: kTextDark,
                  ),
                ),

                const SizedBox(height: 24),
                _buildStatsRow(),
                const SizedBox(height: 30),

                _buildSectionTitle('Thông tin cá nhân'),
                const SizedBox(height: 15),

                _input(_phoneCtl, label: 'Số điện thoại', icon: Icons.phone_android_rounded, enabled: _isEditing),
                const SizedBox(height: 15),
                _input(_locationCtl, label: 'Vị trí', icon: Icons.location_on_rounded, enabled: _isEditing),
                const SizedBox(height: 15),
                _input(_emailCtl, label: 'Email', icon: Icons.email_rounded, enabled: _isEditing),
                const SizedBox(height: 15),
                
                // Hàng Ngày sinh & Giới tính (Sửa lại UI)
                Row(
                  children: [
                    // Date Picker Input
                    Expanded(
                      child: GestureDetector(
                        onTap: _pickDate,
                        child: AbsorbPointer( // Chặn bàn phím hiện lên
                          child: _input(
                            _dobDisplayCtl, 
                            label: 'Ngày sinh', 
                            icon: Icons.cake_rounded, 
                            enabled: _isEditing // Vẫn enable visual, nhưng chặn tap bởi GestureDetector
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    
                    // Gender Dropdown
                    Expanded(
                      child: _genderDropdown(enabled: _isEditing),
                    ),
                  ],
                ),

                const SizedBox(height: 30),
                _buildSectionTitle('Hỗ trợ & Pháp lý'),
                const SizedBox(height: 10),
                _buildActionItem('Điều khoản dịch vụ', Icons.description_outlined, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const TermsOfServicePage()));
                }),
                _buildActionItem('Chính sách quyền riêng tư', Icons.security_outlined, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacyPolicyPage()));
                }),

                const SizedBox(height: 35),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/login'),
                    icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                    label: const Text('Đăng xuất', style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.redAccent, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      backgroundColor: Colors.redAccent.withOpacity(0.05),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _genderDropdown({required bool enabled}) {
    return DropdownButtonFormField<String>(
      value: _selectedGender,
      decoration: InputDecoration(
        labelText: 'Giới tính',
        prefixIcon: const Icon(Icons.person_outline_rounded, size: 20, color: kPrimaryColor),
        labelStyle: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w500),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kBorderColor)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kBorderColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kPrimaryColor, width: 1.5)),
      ),
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kTextDark),
      icon: const Icon(Icons.keyboard_arrow_down, color: kPrimaryColor),
      items: ['Nam', 'Nữ', 'Khác'].map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: enabled ? (newValue) {
        setState(() {
          _selectedGender = newValue;
        });
      } : null, // Disable dropdown if not editing
    );
  }

  Widget _input(TextEditingController controller, {required String label, required IconData icon, required bool enabled}) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kTextDark),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: kPrimaryColor),
        labelStyle: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w500),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kBorderColor)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kBorderColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kPrimaryColor, width: 1.5)),
        disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[100]!)),
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
          color: kTextDark,
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
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: Colors.grey[700], size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kTextDark)),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
    );
  }

  Widget _buildAvatar() {
    final avatar = _avatarPath ?? '';
    ImageProvider? provider;
    if (avatar.isNotEmpty) {
      if (avatar.startsWith('http')) provider = NetworkImage(avatar);
      else if (File(avatar).existsSync()) provider = FileImage(File(avatar));
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: kPrimaryColor.withOpacity(0.2), width: 1),
      ),
      child: CircleAvatar(
        radius: 65,
        backgroundColor: Colors.grey.shade100,
        backgroundImage: provider,
        child: provider == null
            ? ClipOval(
                child: Image.asset(
                  'images/avatar.png',
                  width: 130, height: 130, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 70, color: Colors.grey),
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
        _statColumn(Icons.directions_bike_rounded, '$_vehicleCount xe', () => widget.onSwitchTab?.call(1)),
        _statColumn(Icons.favorite_rounded, 'Yêu thích', () => context.push('/favorites', extra: widget.user)),
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
            Icon(icon, color: const Color(0xFF64B5F6), size: 32), 
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: kTextDark,
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false, initialChildSize: 0.6, maxChildSize: 0.9,
          builder: (context, scrollController) {
            return FutureBuilder<List<Map<String, dynamic>>>(
              future: getUserReviews(_fullName),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
                final reviews = snapshot.data ?? [];
                if (reviews.isEmpty) return const Center(child: Text('Bạn chưa có đánh giá nào', style: TextStyle(fontSize: 16, color: Colors.grey)));

                return Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(width: 40, height: 4, decoration: BoxDecoration(color: kPrimaryColor, borderRadius: BorderRadius.circular(2))),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('Đánh giá của bạn (${reviews.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryColor)),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: reviews.length,
                        itemBuilder: (context, index) {
                          final r = reviews[index];
                          return ListTile(
                            leading: const CircleAvatar(backgroundColor: Colors.amber, child: Icon(Icons.star, color: Colors.white)),
                            title: Text(r['garage_name'] ?? 'Gara không xác định', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r['comment'] ?? ''),
                                const SizedBox(height: 4),
                                Text(r['created_at'] != null ? r['created_at'].substring(0, 10) : '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                            trailing: Text('${r['rating'] ?? 0} ★', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
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
}