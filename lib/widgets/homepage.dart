import 'package:flutter/material.dart';
import '../helpers/utils.dart';

class HomePage extends StatefulWidget {
  final Map<String, dynamic> user;

  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _vehicles = [];
  bool _loadingVehicles = true;

  late final String userId;

  @override
  void initState() {
    super.initState();

    userId = widget.user['user_id'].toString();
    _loadVehicles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: _buildBottomNav(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildMonthlyExpense(),
              _buildUtilities(),
              _buildMyVehicles(), // 👈 giờ dùng _vehicles
            ],
          ),
        ),
      ),
    );
  }

  /* ================= HEADER ================= */

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: const Color(0xFF4F6472),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Xin chào, ${widget.user['full_name']}!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'TP.HCM, 08/11/2000',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              '300 m\nTrạm sửa chữa',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  /* ================= MONTHLY EXPENSE ================= */

  Widget _buildMonthlyExpense() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chi tiêu trong tháng này',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _fakePieChart(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _legendItem('Bảo dưỡng xe định kỳ', Colors.blue.shade300),
                    _legendItem('Sửa chữa khẩn cấp', Colors.blueGrey),
                    _legendItem('Nâng cấp & Tân trang', Colors.lightBlue),
                    _legendItem('Phụ tùng mua ngoài', Colors.teal),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF41ACD8),
                        foregroundColor: const Color(0xFFFBC71C),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Xem lịch sử chi tiêu',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fakePieChart() {
    return Container(
      width: 120,
      height: 120,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF7BAEC8),
      ),
      child: const Center(
        child: Text(
          'Pie\nChart',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _legendItem(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          CircleAvatar(radius: 6, backgroundColor: color),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  /* ================= UTILITIES ================= */

  Widget _buildUtilities() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Các tiện ích khác',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// CỨU HỘ KHẨN CẤP
              Expanded(
                flex: 2,
                child: Container(
                  height: 240,
                  decoration: _boxDecoration(),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'images/emergency.png',
                        errorBuilder: (context, error, stackTrace) {
                          return const Text(
                            'LOAD IMAGE FAIL',
                            style: TextStyle(color: Colors.red),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Cứu hộ khẩn cấp',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              /// NHÓM TIỆN ÍCH PHẢI
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    Row(
                      children: [
                        _utilityItem(
                          'images/calendar.png',
                          'Đặt lịch bảo dưỡng',
                        ),
                        const SizedBox(width: 12),
                        _utilityItem(
                          'images/garage.png',
                          'Gara yêu thích',
                          imageSize: 55,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _utilityItem(
                          'images/tips.png',
                          'Mẹo bảo dưỡng',
                          imageSize: 58,
                        ),
                        const SizedBox(width: 12),
                        _utilityItem('images/search.png', 'Tra cứu phạt nguội'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _utilityItem(
    String imagePath,
    String label, {
    double imageSize = 46, // ⬅ mặc định
  }) {
    return Expanded(
      child: Container(
        height: 114,
        decoration: _boxDecoration(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(imagePath, height: imageSize, fit: BoxFit.contain),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.grey.shade300),
    );
  }

  /* ================= MY VEHICLES ================= */

  Widget _buildMyVehicles() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Xe của tôi',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          if (_loadingVehicles)
            const Center(child: CircularProgressIndicator())
          else if (_vehicles.isEmpty)
            const Text('Bạn chưa thêm xe nào')
          else
            SizedBox(
              height: 150,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _vehicles.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final vehicle = _vehicles[index];

                  final title = getVehicleDisplayName(vehicle);
                  final imagePath = getVehicleImageByType(
                    vehicle['vehicle_type'],
                  );

                  return _vehicleCard(title: title, imagePath: imagePath);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _vehicleCard({required String title, required String imagePath}) {
    return Container(
      width: 280,
      height: 190,
      decoration: _boxDecoration(),
      child: Stack(
        clipBehavior: Clip.none, // 👈 cho phép lấn ra ngoài
        children: [
          /// TEXT
          Positioned(
            top: 10,
            left: 16,
            right: 16,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 35,
                fontWeight: FontWeight.bold,
                color: Colors.amber,
              ),
            ),
          ),

          /// IMAGE (LỚN + ĐÈ LÊN CHỮ)
          Positioned(
            bottom: -10, // 👈 lấn ra ngoài card 1 chút
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                imagePath,
                height: 140, // 🔥 ảnh to
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.directions_bike,
                    size: 80,
                    color: Colors.grey,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /* ================= BOTTOM NAV ================= */

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.black,
      selectedItemColor: const Color(0xFF92D6E3),
      unselectedItemColor: Colors.white,
      showUnselectedLabels: true,
      items: [
        _bottomItem('images/home.png', 'Trang chủ'),
        _bottomItem('images/gara.png', 'Garage'),
        _bottomItem('images/find.png', 'Tìm'),
        _bottomItem('images/history.png', 'Lịch sử'),
        _bottomItem('images/profile.png', 'Thông tin'),
      ],
    );
  }

  BottomNavigationBarItem _bottomItem(String iconPath, String label) {
    return BottomNavigationBarItem(
      icon: Image.asset(
        iconPath,
        height: 24,
        color: Colors.white, // OFF
      ),
      activeIcon: Image.asset(
        iconPath,
        height: 24,
        color: const Color(0xFF92D6E3), // ON
      ),
      label: label,
    );
  }

  Future<void> _loadVehicles() async {
    final result = await getUserVehicles(userId);

    setState(() {
      _vehicles = result;
      _loadingVehicles = false;
    });
  }
}
