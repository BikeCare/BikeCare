import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../helpers/utils.dart';

class GarageListPage extends StatefulWidget {
  const GarageListPage({super.key});

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
      // 1. Cố gắng lấy vị trí thật
      Position position = await _determinePosition();
      // 2. Lấy data và tính khoảng cách
      final data = await getNearestGarages(
        position.latitude,
        position.longitude,
      );

      if (mounted) {
        setState(() {
          _garages = data;
        });
      }
    } catch (e) {
      // FALLBACK: Nếu lỗi GPS thì dùng toạ độ mặc định Quận 10
      debugPrint("Lỗi GPS/Data: $e -> Dùng toạ độ mặc định Quận 10");
      try {
        final data = await getNearestGarages(10.771450, 106.666980);
        if (mounted) {
          setState(() {
            _garages = data;
          });
        }
      } catch (e2) {
        debugPrint("Lỗi Fatal khi load data fallback: $e2");
      }
    } finally {
      if (mounted) {
        setState(() {
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

  // === 2. HÀM HIỆN POPUP GỌI ĐIỆN ===
  void _showCallPopup(String? phone) {
    if (phone == null || phone.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Liên hệ cửa hàng"),
        content: Text("Số điện thoại: $phone\nBạn có muốn gọi ngay không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context); // Đóng popup trước
              final Uri launchUri = Uri(scheme: 'tel', path: phone);
              if (await canLaunchUrl(launchUri)) {
                await launchUrl(launchUri);
              }
            },
            icon: const Icon(Icons.call),
            label: const Text("Gọi ngay"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Hàm lọc danh sách
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
    // Dùng Container nền trắng thay vì Scaffold (để tránh 2 lớp AppBar nếu lồng trong MainScreen)
    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // THANH TÌM KIẾM
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

            // DANH SÁCH GARA
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
      onTap: () => context.push('/garage/detail', extra: garage),
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
            // === ẢNH ĐẠI DIỆN ĐỒNG NHẤT (FRAME CHUNG) ===
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 90,
                height: 90, // Khung ảnh vuông cố định
                color: Colors.grey[100],
                child: garage['image'].toString().startsWith('http')
                    ? Image.network(
                        garage['image'],
                        fit: BoxFit.cover,
                      ) // Ảnh mạng -> Cắt đầy khung (Cover)
                    : Image.asset(
                        garage['image'] ?? 'images/garage.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.store, color: Colors.grey),
                      ),
              ),
            ),
            const SizedBox(width: 12),

            // THÔNG TIN BÊN PHẢI
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tên + Rating
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

                  // NÚT GỌI & ĐẶT LỊCH (Style mới)
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _showCallPopup(garage['phone']),
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
                          onTap: () {}, // Logic đặt lịch
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

  // Widget nút bấm nhỏ dùng chung
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
