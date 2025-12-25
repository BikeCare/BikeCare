import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
//import 'add_vehicle_page.dart';
import '../../helpers/utils.dart'; // Để lấy list xe từ DB

class GaragePage extends StatefulWidget {
  const GaragePage({super.key});

  @override
  State<GaragePage> createState() => _GaragePageState();
}

class _GaragePageState extends State<GaragePage> {
  // PageController để tạo hiệu ứng vuốt thẻ
  final PageController _pageController = PageController(viewportFraction: 0.9);

  int _selectedIndex = 0; // Card đang được chọn
  List<Map<String, dynamic>> _vehicles = [];
  bool _isLoading = true;
  final String _userId = "user_001"; // ID giả định

  // Recent repairs state
  List<Map<String, dynamic>> _recentRepairs = [];
  bool _loadingRepairs = true;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
    _loadRecentRepairs();
  }

  Future<void> _loadVehicles() async {
    // Lấy danh sách xe từ DB thật
    final data = await getUserVehicles(_userId);
    if (mounted) {
      setState(() {
        _vehicles = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRecentRepairs() async {
    // Nếu chưa có xe hoặc đang chọn card "Thêm xe"
    if (_vehicles.isEmpty || _selectedIndex >= _vehicles.length) {
      if (mounted) {
        setState(() {
          _recentRepairs = [];
          _loadingRepairs = false;
        });
      }
      return;
    }

    try {
      // Lấy vehicle_id của xe đang chọn
      final vehicleId = _vehicles[_selectedIndex]['vehicle_id'].toString();
      final data = await getRecentRepairsByVehicle(
        userId: _userId,
        vehicleId: vehicleId,
        limit: 2,
      );
      if (mounted) {
        setState(() {
          _recentRepairs = data;
          _loadingRepairs = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _recentRepairs = [];
          _loadingRepairs = false;
        });
      }
    }
  }

  // LOGIC TÍNH TOÁN "ĐẾN HẠN" (Mock Logic)
  bool _isDue(int index) {
    // Logic giả: Xe ở vị trí chẵn thì "Đến hạn", lẻ thì "Hoàn tất"
    // Sau này bạn thay bằng logic so sánh ngày tháng thật
    return index % 2 == 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Garage Của Tôi",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 20),
                // === 1. CAROUSEL XE ===
                SizedBox(
                  height: 220, // Chiều cao card xe
                  child: PageView.builder(
                    controller: _pageController,
                    // Số lượng item = số xe + 1 (thẻ Add cuối cùng)
                    itemCount: _vehicles.length + 1,
                    onPageChanged: (index) {
                      setState(() => _selectedIndex = index);
                      _loadRecentRepairs(); // Reload repairs khi chuyển xe
                    },
                    itemBuilder: (context, index) {
                      // Nếu là thẻ cuối cùng -> Hiển thị Card Thêm Xe
                      if (index == _vehicles.length) {
                        return _buildAddVehicleCard();
                      }
                      // Ngược lại -> Hiển thị Card Thông Tin Xe
                      return _buildVehicleCard(_vehicles[index], index);
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // === 2. NỘI DUNG THAY ĐỔI THEO CARD ===
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildBottomContent(),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // --- WIDGET: CARD XE THÔNG TIN ---
  Widget _buildVehicleCard(Map<String, dynamic> vehicle, int index) {
    bool isMaintenanceDue = _isDue(index); // Logic check hạn
    String imgPath = getVehicleImageByType(vehicle['vehicle_type']);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200], // Màu nền card xám nhẹ giống design
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          // Ảnh xe (Canh giữa)
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(imgPath, height: 100, fit: BoxFit.contain),
            ),
          ),

          // Tên & Model
          Positioned(
            bottom: 60,
            left: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  getVehicleDisplayName(vehicle).toUpperCase(), // Tên xe/Hãng
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFC8A037),
                  ), // Màu vàng nghệ
                ),
                Text(
                  "${vehicle['brand']} / ${vehicle['vehicle_type']}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  "Bảo hành: ${vehicle['warranty_end'] ?? 'N/A'}",
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),

          // Nút "Xem thêm"
          Positioned(
            right: 20,
            bottom: 80,
            child: TextButton(
              onPressed: () {
                // TODO: Mở trang chi tiết xe (vehicle_detail_page)
              },
              child: const Text(
                "Xem thêm",
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ),

          // Label "Đến hạn" / "Hoàn tất"
          Positioned(
            bottom: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isMaintenanceDue
                    ? const Color(0xFFFBC71C)
                    : const Color(0xFFA5D6A7), // Vàng hoặc Xanh
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isMaintenanceDue ? "Đến hạn" : "Hoàn tất",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isMaintenanceDue ? Colors.black : Colors.green[900],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET: CARD THÊM XE (+) ---
  Widget _buildAddVehicleCard() {
    return GestureDetector(
      onTap: () async {
        // === SỬA ĐOẠN NÀY ===
        // Dùng context.push của GoRouter thay vì Navigator.push
        // Chờ kết quả trả về (true nếu thêm thành công)
        final result = await context.push<bool>('/add-vehicle');

        if (result == true) {
          _loadVehicles(); // Reload lại danh sách xe nếu có xe mới
        }
      },

      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.grey.shade300,
            style: BorderStyle.solid,
            width: 2,
          ), // Viền nét đứt hoặc liền
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue[50],
              ),
              child: const Icon(Icons.add, size: 40, color: Colors.blue),
            ),
            const SizedBox(height: 10),
            const Text(
              "Thêm xe mới",
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- LOGIC HIỂN THỊ NỘI DUNG DƯỚI (LỊCH BẢO DƯỠNG) ---
  Widget _buildBottomContent() {
    // Trường hợp: Đang chọn card "Thêm xe" (Card cuối cùng)
    if (_selectedIndex == _vehicles.length) {
      return Center(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Image.asset(
              'images/motorbike.png',
              height: 100,
              color: Colors.grey.withOpacity(0.3),
            ),
            const SizedBox(height: 20),
            const Text(
              "Thêm xe vào garage thôi bạn ơi!",
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              "Quản lý lịch sử bảo dưỡng dễ dàng hơn.",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Trường hợp: Đang chọn 1 xe cụ thể
    // Lấy data giả (Draft) cho xe hiện tại
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- 1. Lịch bảo dưỡng sắp tới ---
        Row(
          children: [
            const Icon(Icons.calendar_month_outlined),
            const SizedBox(width: 8),
            const Text(
              "Lịch bảo dưỡng sắp tới",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Mock Data Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "20/01/2025",
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              RichText(
                text: const TextSpan(
                  style: TextStyle(color: Colors.black),
                  children: [
                    TextSpan(
                      text: "Ghi chú: ",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text:
                          "Bảo dưỡng định kỳ trong gói Bảo hành 2 năm tại Honda Minh Nguyệt - Quận 5.",
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // --- 2. Sửa chữa gần đây ---
        Row(
          children: [
            const Icon(Icons.build_outlined),
            const SizedBox(width: 8),
            const Text(
              "Sửa chữa gần đây",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward, color: Colors.grey),
          ],
        ),
        const SizedBox(height: 10),

        // Real Data from Database
        if (_loadingRepairs)
          const Center(child: CircularProgressIndicator())
        else if (_recentRepairs.isEmpty)
          const Text(
            'Chưa có lịch sử chi tiêu',
            style: TextStyle(color: Colors.grey),
          )
        else
          ..._recentRepairs.map((e) {
            final title =
                e['note']?.toString() ??
                e['category_name']?.toString() ??
                'Chi tiêu';
            final garageName = e['garage_name']?.toString() ?? 'Không rõ gara';
            final date = _formatDate(e['expense_date']);
            final amount = (e['amount'] ?? 0) as int;
            final price = '-${_formatMoney(amount)}';
            return _buildRepairItem(title, garageName, date, price);
          }),
      ],
    );
  }

  Widget _buildRepairItem(
    String title,
    String shop,
    String date,
    String price,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text("$shop", style: const TextStyle(color: Colors.black87)),
              Text(
                date,
                style: const TextStyle(color: Colors.blue, fontSize: 12),
              ),
            ],
          ),
          Text(
            price,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr.toString());
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateStr.toString();
    }
  }

  String _formatMoney(int amount) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(amount)}đ';
  }
}
