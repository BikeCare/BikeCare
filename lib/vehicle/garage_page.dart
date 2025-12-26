import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../helpers/utils.dart'; 

class GaragePage extends StatefulWidget {
  final Map<String, dynamic> user;
  final Function(int)? onSwitchTab;

  const GaragePage({
    super.key,
    required this.user,
    this.onSwitchTab,
  });

  @override
  State<GaragePage> createState() => _GaragePageState();
}

class _GaragePageState extends State<GaragePage> {
  final PageController _pageController = PageController(viewportFraction: 0.9);

  int _selectedIndex = 0;
  List<Map<String, dynamic>> _vehicles = [];
  bool _isLoading = true;
  late final String _userId;

  List<Map<String, dynamic>> _recentRepairs = [];
  bool _loadingRepairs = false; // Mặc định false để không xoay lúc đầu

  List<Map<String, dynamic>> _upcomingBookings = [];
  bool _isLoadingBookings = true;

  @override
  void initState() {
    super.initState();
    _userId = widget.user['user_id'] as String;
    _loadAllData();
  }

  // Hàm gọi chung khi khởi tạo hoặc refresh
  Future<void> _loadAllData() async {
    await _loadVehicles(); // Load xe trước
    await _loadUpcomingBookings(); // Load lịch
    // Sau khi có xe thì mới load sửa chữa cho xe đầu tiên (nếu có)
    _loadRecentRepairs(); 
  }

  Future<void> _loadVehicles() async {
    final data = await getUserVehicles(_userId);
    if (mounted) {
      setState(() {
        _vehicles = data;
        _isLoading = false;
      });
    }
  }

  // Logic: Load sửa chữa dựa trên card đang chọn (_selectedIndex)
  Future<void> _loadRecentRepairs() async {
    // 1. Nếu đang ở card "Thêm xe" (Index cuối cùng) hoặc chưa có xe -> Không làm gì
    if (_vehicles.isEmpty || _selectedIndex >= _vehicles.length) {
      if (mounted) setState(() => _recentRepairs = []);
      return;
    }

    // 2. Nếu đang chọn 1 xe -> Load sửa chữa của xe đó
    if (mounted) setState(() => _loadingRepairs = true);
    
    try {
      final vehicleId = _vehicles[_selectedIndex]['vehicle_id'].toString();
      final data = await getRecentRepairsByVehicle(userId: _userId, vehicleId: vehicleId, limit: 2);
      
      if (mounted) {
        setState(() {
          _recentRepairs = data;
          _loadingRepairs = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingRepairs = false);
    }
  }

  Future<void> _loadUpcomingBookings() async {
    final data = await getUpcomingBookings(_userId);
    if (mounted) {
      setState(() {
        _upcomingBookings = data;
        _isLoadingBookings = false;
      });
    }
  }

  // --- LOGIC HELPER ---
  bool _isDue(int index) {
    if (_vehicles.isEmpty || index >= _vehicles.length) return false;
    // Lấy ID xe hiện tại
    final currentVehicleId = _vehicles[index]['vehicle_id']; 
    final oneMonthLater = DateTime.now().add(const Duration(days: 30));

    // Check xem xe này có lịch hẹn nào sắp tới hạn không
    for (var booking in _upcomingBookings) {
      if (booking['vehicle_id'] == currentVehicleId) {
        try {
          final bookingDate = DateTime.parse(booking['booking_date']);
          if (bookingDate.isBefore(oneMonthLater)) return true;
        } catch (e) { continue; }
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Garage của tôi", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAllData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // === 1. CAROUSEL XE ===
                    SizedBox(
                      height: 220,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: _vehicles.length + 1, // +1 cho card Thêm xe
                        onPageChanged: (index) {
                          setState(() => _selectedIndex = index);
                          // [QUAN TRỌNG] Khi lướt xe, load lại dữ liệu sửa chữa tương ứng
                          _loadRecentRepairs();
                        },
                        itemBuilder: (context, index) {
                          if (index == _vehicles.length) return _buildAddVehicleCard();
                          return _buildVehicleCard(_vehicles[index], index);
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // === 2. NỘI DUNG DƯỚI (Thay đổi theo xe) ===
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildBottomContent(),
                    ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
    );
  }

  // === LOGIC QUAN TRỌNG NHẤT: HIỂN THỊ NỘI DUNG DƯỚI ===
  Widget _buildBottomContent() {
    // TRƯỜNG HỢP 1: Đang chọn card "Thêm xe mới"
    if (_selectedIndex == _vehicles.length) {
      return Center(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Opacity(
              opacity: 0.3,
              child: Image.asset('images/motorbike.png', height: 100),
            ),
            const SizedBox(height: 20),
            const Text(
              "Thêm xe vào garage thôi bạn ơi!",
              style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold),
            ),
            const Text(
              "Quản lý lịch sử bảo dưỡng dễ dàng hơn.",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // TRƯỜNG HỢP 2: Đang chọn một chiếc xe cụ thể
    // Lấy ID xe đang chọn để lọc dữ liệu
    final currentVehicle = _vehicles[_selectedIndex];
    final currentVehicleId = currentVehicle['vehicle_id'];

    // Lọc danh sách booking chỉ lấy của xe này
    final vehicleBookings = _upcomingBookings.where((b) => b['vehicle_id'] == currentVehicleId).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- HEADER BOOKING ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: const [Icon(Icons.calendar_month_outlined), SizedBox(width: 8), Text("Lịch bảo dưỡng", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.blue, size: 28),
                  tooltip: "Đặt lịch mới",
                  onPressed: () async {
                    final result = await context.push('/booking', extra: widget.user);
                    if (result == true) _loadUpcomingBookings();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward, color: Colors.grey),
                  tooltip: "Xem lịch sử",
                  onPressed: () => context.push('/booking-history', extra: widget.user),
                )
              ],
            )
          ],
        ),
        const SizedBox(height: 10),

        // --- LIST BOOKING (ĐÃ LỌC THEO XE) ---
        if (_isLoadingBookings)
          const Center(child: CircularProgressIndicator())
        else if (vehicleBookings.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
            child: const Text("Chưa có lịch đặt hẹn cho xe này.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic), textAlign: TextAlign.center),
          )
        else
          Column(
            children: vehicleBookings.map((booking) {
              return GestureDetector(
                onTap: () async {
                  final result = await context.push('/booking-detail', extra: {'booking': booking, 'user': widget.user});
                  if (result == true) _loadUpcomingBookings(); 
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 4, offset: const Offset(0, 2))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDateVN(booking['booking_date']), style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                            child: Text(booking['booking_time'] ?? '', style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold, fontSize: 12)),
                          )
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text("Tại: ${booking['garage_name'] ?? 'Không rõ'}", style: const TextStyle(fontWeight: FontWeight.bold)),
                      // Không cần hiện tên xe nữa vì đang ở trong tab của xe đó rồi, hoặc hiện để confirm
                      Text("Xe: ${booking['vehicle_name'] ?? booking['brand']}", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

        const SizedBox(height: 20),

        // --- HEADER REPAIRS ---
        Row(
          children: [
            const Icon(Icons.build_outlined),
            const SizedBox(width: 8),
            const Text("Sửa chữa gần đây", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Spacer(),
            GestureDetector(onTap: () => widget.onSwitchTab?.call(3), child: const Icon(Icons.arrow_forward, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 10),

        // --- LIST REPAIRS (THEO XE ĐANG CHỌN) ---
        if (_loadingRepairs)
          const Center(child: Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator()))
        else if (_recentRepairs.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: Text('Chưa có lịch sử chi tiêu cho xe này', style: TextStyle(color: Colors.grey))),
          )
        else
          ..._recentRepairs.map((e) {
            final title = e['note']?.toString() ?? e['category_name']?.toString() ?? 'Chi tiêu';
            final garageName = e['garage_name']?.toString() ?? 'Không rõ gara';
            final date = _formatDate(e['expense_date']);
            final amount = (e['amount'] ?? 0) as int;
            final price = '-${_formatMoney(amount)}';
            return _buildRepairItem(title, garageName, date, price);
          }),
      ],
    );
  }

  // --- WIDGETS ---
  
  // Card Xe (UI Mới)
  Widget _buildVehicleCard(Map<String, dynamic> vehicle, int index) {
    bool isMaintenanceDue = _isDue(index);
    String imgPath = getVehicleImageByType(vehicle['vehicle_type']);
    String warrantyDate = _formatDateVN(vehicle['warranty_end']);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100], 
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Image.asset(imgPath, fit: BoxFit.contain),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        getVehicleDisplayName(vehicle).toUpperCase(),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFC8A037)),
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${vehicle['brand']} • ${vehicle['license_plate'] ?? ''}",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text("BH đến: $warrantyDate", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isMaintenanceDue ? const Color(0xFFFFF3CD) : const Color(0xFFD1E7DD),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isMaintenanceDue ? const Color(0xFFFFEEBA) : const Color(0xFFBADBCC)),
                ),
                child: Text(
                  isMaintenanceDue ? "Đến hạn" : "Hoàn tất",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isMaintenanceDue ? const Color(0xFF856404) : const Color(0xFF0F5132)),
                ),
              ),
              InkWell(
                onTap: () async {
                  final result = await context.push('/vehicle-detail', extra: vehicle);
                  if (result == true) _loadVehicles(); 
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: const [
                      Text("Chi tiết", style: TextStyle(color: Color(0xFF59CBEF), fontWeight: FontWeight.bold)),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFF59CBEF)),
                    ],
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  // Card Thêm Xe (Giữ nguyên)
  Widget _buildAddVehicleCard() {
    return GestureDetector(
      onTap: () async {
        final result = await context.push<bool>('/add-vehicle', extra: widget.user);
        if (result == true) _loadVehicles();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue[50]), child: const Icon(Icons.add, size: 40, color: Colors.blue)),
            const SizedBox(height: 10),
            const Text("Thêm xe mới", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildRepairItem(String title, String shop, String date, String price) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(shop, style: const TextStyle(color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(date, style: const TextStyle(color: Colors.blue, fontSize: 12)),
              ],
            ),
          ),
          Text(price, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  // --- UTILS ---
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

  String _formatDateVN(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateStr ?? 'N/A';
    }
  }
}