import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../helpers/utils.dart';

class FavoritePage extends StatefulWidget {
  const FavoritePage({super.key});

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  // Giả lập user hiện tại
  final String currentUserId = "user_001"; // Sau này thay bằng ID thật

  List<Map<String, dynamic>> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // === 1. LOAD DATA & TÍNH KHOẢNG CÁCH ===
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // A. Lấy danh sách yêu thích từ DB
      List<Map<String, dynamic>> rawData = await getFavoriteGarages(
        currentUserId,
      );

      // B. Lấy vị trí hiện tại để tính khoảng cách
      Position? currentPos;
      try {
        currentPos = await _determinePosition();
      } catch (e) {
        // Nếu không lấy được vị trí thì thôi (coi như user tắt GPS)
        print("Không lấy được vị trí: $e");
      }

      // C. Xử lý tính khoảng cách cho từng item
      List<Map<String, dynamic>> processedData = [];
      for (var item in rawData) {
        double distance = 0.0;
        if (currentPos != null) {
          double storeLat = item['lat'] ?? 0.0;
          double storeLng = item['lng'] ?? 0.0;
          if (storeLat != 0 && storeLng != 0) {
            double distMeters = Geolocator.distanceBetween(
              currentPos.latitude,
              currentPos.longitude,
              storeLat,
              storeLng,
            );
            distance = double.parse((distMeters / 1000).toStringAsFixed(1));
          }
        }

        // Clone ra map mới để thêm field distance
        processedData.add({
          ...item,
          'distance': distance, // Gán khoảng cách
        });
      }

      if (mounted) {
        setState(() {
          _favorites = processedData;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Lỗi load favorites: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Hàm lấy vị trí (Copy từ GarageListPage để đồng bộ)
  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('Location services are disabled.');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    return await Geolocator.getCurrentPosition();
  }

  // === 2. LOGIC GỌI ĐIỆN (POPUP) ===
  void _showCallPopup(String? phone) {
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Số điện thoại không khả dụng")),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Liên hệ cửa hàng"),
        content: Text("Số điện thoại: $phone\nBạn có muốn gọi ngay không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              final Uri launchUri = Uri(scheme: 'tel', path: phone);
              if (await canLaunchUrl(launchUri)) await launchUrl(launchUri);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Gara Yêu Thích",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.grey[50], // Màu nền nhẹ cho toàn trang
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _favorites.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _favorites.length,
              itemBuilder: (context, index) {
                return _buildFavoriteCard(_favorites[index]);
              },
            ),
    );
  }

  // Widget hiển thị khi danh sách trống
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            "Chưa có gara yêu thích nào",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  // === 3. CARD GIAO DIỆN (GIỐNG TRANG LIST) ===
  Widget _buildFavoriteCard(Map<String, dynamic> garage) {
    return GestureDetector(
      onTap: () async {
        // Chuyển sang trang detail, chờ quay về thì reload lại list (để lỡ user bỏ tim bên đó thì bên này cập nhật luôn)
        await context.push('/garage/detail', extra: garage);
        _loadData();
      },
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
            // Ảnh vuông bo góc
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 90,
                height: 90,
                color: Colors.grey[100],
                child: _buildImg(garage['image'] ?? ''),
              ),
            ),
            const SizedBox(width: 12),

            // Thông tin
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
                              "${garage['rating'] ?? 0}",
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

                  // Khoảng cách
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 12,
                        color: Colors.grey,
                      ),
                      Text(
                        " ${garage['distance']} km từ bạn",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Nút bấm (Style nền nhạt giống trang List)
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
                          onTap: () {}, // Đặt lịch placeholder
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

  // Helper Button (Dùng chung style)
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

  // Helper Image
  Widget _buildImg(String url) {
    if (url.startsWith('http')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.store, color: Colors.grey),
      );
    }
    return Image.asset(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const Icon(Icons.store, color: Colors.grey),
    );
  }
}
