import 'package:flutter/material.dart';
import '../helpers/utils.dart';
import '../helpers/routers.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/app_bottom_nav.dart';
import 'package:fl_chart/fl_chart.dart';

class HomePage extends StatefulWidget {
  final Map<String, dynamic> user;

  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _loadingExpense = true;
  Map<String, int> _monthByCategory = {}; // category_name -> total amount
  int _monthTotal = 0;

  List<Map<String, dynamic>> _vehicles = [];
  bool _loadingVehicles = true;
  late final String userId;

  // Header info
  String city = '...'; // default text trước khi GPS load xong
  String currentDate = DateFormat('dd/MM/yyyy').format(DateTime.now());

  final BoxDecoration _cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: Colors.grey),
  );

  @override
  void initState() {
    super.initState();
    userId = widget.user['user_id'].toString();
    _loadingExpense = true;
    _loadMonthlyExpense();

    _loadVehicles();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLocation();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: AppBottomNav(user: widget.user),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildMonthlyExpense(),
              _buildUtilities(),
              _buildMyVehicles(),
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Xin chào, ${getLastName(widget.user['full_name'])}!',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$city, $currentDate',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(60, 2, 3, 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: AssetImage('images/map.png'),
                fit: BoxFit.cover,
                //colorFilter: ColorFilter.mode(Colors.black26, BlendMode.darken),
                // làm mờ background để text nổi bật
              ),
            ),
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: const [
                    Text(
                      'Gara gần nhất',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '300m',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
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
              _expensePieChart(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _expenseLegend(), // ✅ CHỈ GỌI HÀM
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        context.go('/history', extra: widget.user);
                      },
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

  Widget _expenseLegend() {
    if (_loadingExpense) {
      return const Text('Đang tải dữ liệu...');
    }

    if (_monthByCategory.isEmpty) {
      return const Text('Chưa có dữ liệu chi tiêu tháng này');
    }

    final entries = _monthByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    Color colorOf(String cat) {
      switch (cat) {
        case 'Bảo dưỡng định kỳ':
          return Colors.blue;
        case 'Sửa chữa khẩn cấp':
          return Colors.blueGrey;
        case 'Nâng cấp & tân trang':
          return Colors.lightBlue;
        case 'Phụ tùng':
          return Colors.teal;
        default:
          return Colors.grey;
      }
    }

    String money(int v) =>
        NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(v);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...entries
            .take(4)
            .map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    CircleAvatar(radius: 6, backgroundColor: colorOf(e.key)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(e.key)),
                    Text(
                      money(e.value),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
        const SizedBox(height: 6),
        Text(
          'Tổng: ${money(_monthTotal)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _expensePieChart() {
    if (_loadingExpense) {
      return const SizedBox(
        width: 120,
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_monthTotal <= 0 || _monthByCategory.isEmpty) {
      return Container(
        width: 120,
        height: 120,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF7BAEC8),
        ),
        child: const Center(
          child: Text(
            'Chưa có\nchi tiêu',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final entries = _monthByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final sections = <PieChartSectionData>[];

    // Map màu cố định theo category (đúng 4 nhóm seed của bạn)
    Color colorOf(String cat) {
      switch (cat) {
        case 'Bảo dưỡng định kỳ':
          return Colors.blue;
        case 'Sửa chữa khẩn cấp':
          return Colors.blueGrey;
        case 'Nâng cấp & tân trang':
          return Colors.lightBlue;
        case 'Phụ tùng':
          return Colors.teal;
        default:
          return Colors.grey;
      }
    }

    for (final e in entries) {
      final percent = (e.value / _monthTotal) * 100.0;
      sections.add(
        PieChartSectionData(
          value: e.value.toDouble(),
          color: colorOf(e.key),
          title: percent >= 10 ? '${percent.toStringAsFixed(0)}%' : '',
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return SizedBox(
      width: 120,
      height: 120,
      child: PieChart(
        PieChartData(
          sections: sections,
          centerSpaceRadius: 18,
          sectionsSpace: 2,
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
            children: [
              Expanded(
                flex: 2,
                child: _utilityCard(
                  'images/emergency.png',
                  'Cứu hộ khẩn cấp',
                  height: 240,
                  imageSize: 90,
                  textSize: 17,
                  route: '/login',
                  onTap: _showEmergencySheet,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _utilityCard(
                            'images/calendar.png',
                            'Đặt lịch bảo dưỡng',
                            onTap: () {
                              context.go('/booking', extra: widget.user);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _utilityCard(
                            'images/garage.png',
                            'Gara yêu thích',
                            imageSize: 55,
                            onTap: () {
                              context.go('/dashboard', extra: widget.user);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _utilityCard(
                            'images/tips.png',
                            'Mẹo bảo dưỡng',
                            imageSize: 60,
                            onTap: () {
                              context.push(AppRoutes.maintenanceTips);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _utilityCard(
                            'images/search.png',
                            'Tra cứu phạt nguội',
                            onTap: () {
                              context.push(
                                AppRoutes.trafficFine,
                                extra: widget.user,
                              );
                            },
                          ),
                        ),
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

  Widget _utilityCard(
    String imagePath,
    String label, {
    double imageSize = 46,
    double height = 114,
    double textSize = 14,
    String? route, // ← GIỮ NGUYÊN, CHƯA CẦN XOÁ
    VoidCallback? onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap, // ← CHỈ DÒNG NÀY QUAN TRỌNG
      child: Container(
        height: height,
        decoration: _cardDecoration,
        padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(imagePath, height: imageSize),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: TextStyle(fontSize: textSize),
              ),
            ),
          ],
        ),
      ),
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
          _buildVehicleContent(),
        ],
      ),
    );
  }

  Widget _buildVehicleContent() {
    if (_loadingVehicles) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_vehicles.isEmpty) {
      return const Text('Bạn chưa thêm xe nào');
    }

    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _vehicles.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final vehicle = _vehicles[index];
          return _vehicleCard(
            title: getVehicleDisplayName(vehicle),
            imagePath: getVehicleImageByType(vehicle['vehicle_type']),
          );
        },
      ),
    );
  }

  Widget _vehicleCard({required String title, required String imagePath}) {
    return Container(
      width: 280,
      decoration: _cardDecoration,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
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
          Positioned(
            bottom: -10,
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                imagePath,
                height: 140,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.directions_bike, size: 80),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /* ================= Hàm lấy xe ================= */
  Future<void> _loadVehicles() async {
    final result = await getUserVehicles(userId);
    setState(() {
      _vehicles = result;
      _loadingVehicles = false;
    });
  }

  /* ================= HÀM LẤY VỊ TRÍ ================= */
  Future<void> _loadLocation() async {
    try {
      final position = await _determinePosition().timeout(
        const Duration(seconds: 6),
      );
      final cityName = await _getCityName(
        position,
      ).timeout(const Duration(seconds: 6));

      if (!mounted) return;
      setState(() => city = cityName);
    } catch (e) {
      debugPrint('Lỗi lấy vị trí: $e');
      if (!mounted) return;
      setState(() => city = 'Unknown');
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('GPS chưa bật');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Quyền truy cập vị trí bị từ chối');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Quyền truy cập vị trí bị từ chối vĩnh viễn');
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<String> _getCityName(Position position) async {
    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    return placemarks.isNotEmpty
        ? (placemarks.first.locality ?? 'Unknown')
        : 'Unknown';
  }

  /* ================= EMERGENCY ================= */

  Widget _callTile(String phone, String label) {
    return ListTile(
      leading: const Icon(Icons.call, size: 40),
      title: Text(label, style: const TextStyle(fontSize: 18)),
      subtitle: Text(phone, style: const TextStyle(fontSize: 16)),
      onTap: () async {
        final uri = Uri(scheme: 'tel', path: phone);

        if (!await launchUrl(
          uri,
          mode: LaunchMode.externalApplication, // ← QUAN TRỌNG
        )) {
          debugPrint('Không thể gọi số $phone');
        }
      },
    );
  }

  void _showEmergencySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cứu hộ khẩn cấp',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Chọn số điện thoại để gọi nhanh',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),

              _callTile('119', 'Trung tâm cứu hộ giao thông'),
              const Divider(),
              _callTile('116', 'Cứu hộ giao thông'),
              const Divider(),
              _callTile('0909123456', 'Cứu hộ Huy Khang'),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF59CBEF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Hủy bỏ',
                    style: TextStyle(
                      fontSize: 25,
                      color: Color(0xFFFBC71C),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String getLastName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    return parts.isNotEmpty ? parts.last : fullName;
  }

  Future<void> _loadMonthlyExpense() async {
    try {
      final rows = await getUserExpenses(userId);

      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 1); // exclusive

      final Map<String, int> agg = {};
      int total = 0;

      for (final r in rows) {
        final dateStr = (r['expense_date'] ?? '').toString();
        DateTime? d;
        try {
          d = DateTime.parse(
            dateStr,
          ); // bạn lưu ISO yyyy-MM-dd :contentReference[oaicite:2]{index=2}
        } catch (_) {
          continue;
        }

        if (d.isBefore(startOfMonth) || !d.isBefore(endOfMonth)) continue;

        final cat = (r['category_name'] ?? 'Khác').toString();
        final amount = (r['amount'] ?? 0) as int;

        agg[cat] = (agg[cat] ?? 0) + amount;
        total += amount;
      }

      if (!mounted) return;
      setState(() {
        _monthByCategory = agg;
        _monthTotal = total;
        _loadingExpense = false;
      });
    } catch (e) {
      debugPrint('Load monthly expense error: $e');
      if (!mounted) return;
      setState(() {
        _monthByCategory = {};
        _monthTotal = 0;
        _loadingExpense = false;
      });
    }
  }
}
