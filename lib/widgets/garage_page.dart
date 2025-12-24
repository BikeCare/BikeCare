import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'add_vehicle_page.dart';
import '../../helpers/utils.dart'; // Để lấy list xe từ DB
import 'package:intl/intl.dart';

class GaragePage extends StatefulWidget {
  final Map<String, dynamic> user; // KHÔI PHỤC USER
  final Function(int)? onSwitchTab; // Thêm callback để chuyển tab
  const GaragePage({super.key, required this.user, this.onSwitchTab});

  @override
  State<GaragePage> createState() => GaragePageState();
}

class GaragePageState extends State<GaragePage> {
  // CHO PHÉP TRUY CẬP ĐỂ RELOAD
  void refresh() {
    _loadVehicles();
  }

  // PageController để tạo hiệu ứng vuốt thẻ
  final PageController _pageController = PageController(viewportFraction: 0.9);

  int _selectedIndex = 0; // Card đang được chọn
  List<Map<String, dynamic>> _vehicles = [];
  bool _isLoading = true;
  List<Map<String, dynamic>> _recentRepairs = [];
  bool _loadingRepairs = true;

  final _money = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  String _fmtMoney(int v) => _money.format(v).replaceAll('₫', 'đ');

  String _fmtDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      return DateFormat('d/M/yyyy', 'vi_VN').format(d);
    } catch (_) {
      return iso;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    final userId = widget.user['user_id'].toString();
    final data = await getUserVehicles(userId);
    if (mounted) {
      setState(() {
        _vehicles = data;
        _isLoading = false;
      });
      await _loadRecentRepairs();
    }
  }

  Future<void> _loadRecentRepairs() async {
    // Nếu chưa có xe hoặc đang ở thẻ cuối "Thêm xe"
    if (_vehicles.isEmpty || _selectedIndex >= _vehicles.length) {
      if (!mounted) return;
      setState(() {
        _recentRepairs = [];
        _loadingRepairs = false;
      });
      return;
    }

    final vehicleId = _vehicles[_selectedIndex]['vehicle_id'].toString();
    final userId = widget.user['user_id'].toString();

    if (!mounted) return;
    setState(() => _loadingRepairs = true);

    final data = await getRecentRepairsByVehicle(
      userId: userId,
      vehicleId: vehicleId,
      limit: 2,
    );

    if (mounted) {
      setState(() {
        _recentRepairs = data;
        _loadingRepairs = false;
      });
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
                    onPageChanged: (index) async {
                      setState(() => _selectedIndex = index);
                      await _loadRecentRepairs();
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
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            if (widget.onSwitchTab != null) {
              widget.onSwitchTab!(3); // Chuyển sang tab Lịch sử
            } else {
              context.push('/history', extra: widget.user);
            }
          },
          child: Row(
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
        ),
        const SizedBox(height: 10),

        if (_loadingRepairs)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_recentRepairs.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                "Chưa có lịch sử sửa chữa cho xe này.",
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          )
        else
          ..._recentRepairs.map((e) {
            final title = (e['note']?.toString().trim().isNotEmpty ?? false)
                ? e['note'].toString()
                : (e['category_name']?.toString() ?? 'Sửa chữa');

            final garageName =
                (e['garage_name']?.toString().trim().isNotEmpty ?? false)
                ? e['garage_name'].toString()
                : "Không rõ gara";

            final date = _fmtDate(e['expense_date'].toString());
            final amount = (e['amount'] ?? 0) is int
                ? (e['amount'] as int)
                : int.tryParse(e['amount'].toString()) ?? 0;

            final price = "-${_fmtMoney(amount)}";

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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (shop.isNotEmpty)
                  Text(
                    shop,
                    style: const TextStyle(color: Colors.black54, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                Text(
                  date,
                  style: const TextStyle(color: Colors.blue, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            price,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Color.fromARGB(255, 9, 9, 9),
            ),
          ),
        ],
      ),
    );
  }
}
