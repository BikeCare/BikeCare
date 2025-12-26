import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../helpers/utils.dart';

class GarageListPage extends StatefulWidget {
  final Map<String, dynamic> user;
  const GarageListPage({super.key, required this.user});

  @override
  State<GarageListPage> createState() => _GarageListPageState();
}

class _GarageListPageState extends State<GarageListPage> {
  List<Map<String, dynamic>> _garages = [];
  bool _isLoading = true;
  String _searchKeyword = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initData();
  }

  // === 1. CÁC HÀM LOGIC DATA  ===
  Future<void> _initData() async {
    try {
      Position position = await _determinePosition();
      final data = await getNearestGarages(
        position.latitude,
        position.longitude,
      );

      if (mounted) {
        setState(() {
          _garages = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Lỗi GPS: $e -> Dùng toạ độ mặc định Quận 10");
      final data = await getNearestGarages(10.771450, 106.666980);

      if (mounted) {
        setState(() {
          _garages = data;
          _isLoading = false;
        });
      }
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
      timeLimit: const Duration(seconds: 5),
    );
  }

  // === 2. HÀM GỌI ĐIỆN (ĐÃ SỬA LOGIC LAUNCHER) ===
  void _showCallBottomSheet(String? phone, String garageName) {
    if (phone == null || phone.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Liên hệ cửa hàng",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Chọn số điện thoại để gọi nhanh",
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 20),

                // Item số điện thoại
                InkWell(
                  onTap: () async {
                    Navigator.pop(context); // Đóng sheet trước
                    
                    // [FIX] Xóa khoảng trắng và ký tự lạ, chỉ giữ số
                    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
                    final Uri launchUri = Uri(scheme: 'tel', path: cleanPhone);
                    
                    try {
                      // [FIX] Dùng externalApplication để mở app Phone
                      if (await canLaunchUrl(launchUri)) {
                        await launchUrl(launchUri);
                      } else {
                        // Fallback: Thử launch không check canLaunch (đôi khi máy ảo báo false ảo)
                        await launchUrl(launchUri, mode: LaunchMode.externalApplication);
                      }
                    } catch (e) {
                      print("Lỗi gọi điện: $e");
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.phone_in_talk,
                          size: 30,
                          color: Color(0xFF5D4037),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                garageName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                phone,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 30, thickness: 1, color: Color(0xFFEEEEEE)),
                
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF59CBEF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "Hủy bỏ",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> get _filteredGarages {
    if (_searchKeyword.isEmpty) return _garages;
    return _garages.where((g) {
      return g['name'].toString().toLowerCase().contains(
            _searchKeyword.toLowerCase(),
          ) ||
          g['address'].toString().toLowerCase().contains(
            _searchKeyword.toLowerCase(),
          );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchKeyword = value),
                  decoration: const InputDecoration(
                    hintText: "Tìm kiếm cửa hàng",
                    prefixIcon: Icon(Icons.search, color: Colors.blue),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredGarages.length,
                      itemBuilder: (context, index) {
                        return _buildGarageCard(_filteredGarages[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGarageCard(Map<String, dynamic> garage) {
    return GestureDetector(
      onTap: () => context.push(
        '/garage/detail',
        extra: {'garage': garage, 'user': widget.user},
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 90,
                height: 90,
                color: Colors.grey[100],
                child: garage['image'].toString().startsWith('http')
                    ? Image.network(garage['image'], fit: BoxFit.cover)
                    : Image.asset(
                        garage['image'] ?? 'images/garage.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.store, color: Colors.grey),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          garage['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Text(
                              "${garage['rating']}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 12,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${garage['distance']} km từ bạn",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _showCallBottomSheet(garage['phone'], garage['name']),
                          child: _actionButton(
                            Icons.call,
                            "Gọi điện",
                            const Color(0xFFA5D6A7),
                            Colors.green.shade800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () => context.push('/booking'),
                          child: _actionButton(
                            Icons.calendar_today,
                            "Đặt lịch",
                            const Color(0xFF90CAF9),
                            Colors.blue.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(
    IconData icon,
    String label,
    Color bgColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.4),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}