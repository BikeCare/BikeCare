import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fl_chart/fl_chart.dart';

import '../helpers/utils.dart';

class HomePage extends StatefulWidget {
  final Map<String, dynamic> user;
  final Function(int) onSwitchTab;

  const HomePage({super.key, required this.user, required this.onSwitchTab});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  
  /* ================= STATE ================= */
  late final String userId;

  // Expense state
  bool _loadingExpense = true;
  Map<String, int> _monthByCategory = {};
  int _monthTotal = 0;

  /* ================= HEADER INFO ================= */
  String city = '...';
  final String currentDate = DateFormat('dd/MM/yyyy').format(DateTime.now());

  /* ================= UI CONST ================= */
  final BoxDecoration _cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: Colors.grey),
  );

  /* ================= LIFECYCLE ================= */
  @override
  void initState() {
    super.initState();
    userId = widget.user['user_id'].toString();
    _loadLocation();
    _loadMonthlyExpense();
  }

  // Public method to refresh expense data
  void refreshExpenses() {
    _loadMonthlyExpense();
  }

  /* ================= BUILD ================= */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildMonthlyExpense(),
              _buildUtilities(),

            ],
          ),
        ),
      ),
    );
  }

  /* =========================================================
   * HEADER
   * ========================================================= */
  Widget _buildHeader() {
  return Container(
    padding: const EdgeInsets.all(20),
    color: const Color(0xFF4F6472),
    child: Row(
      children: [
        Expanded(
          flex: 6, // 👈 70%
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Xin chào, ${getLastName(widget.user['full_name'])}!',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$city, $currentDate',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 4, // 👈 30%
          child: _buildNearestGarage(),
        ),
      ],
    ),
  );
}


  Widget _buildNearestGarage() {
  return AspectRatio(
    aspectRatio: 1.9, // 👈 giữ hình đẹp & không tràn
    child: Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: const DecorationImage(
          image: AssetImage('images/map.png'),
          fit: BoxFit.contain,
        ),
      ),
      child: Stack(
  children: [
    Positioned(
      top: 6,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Gara gần nhất',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 9,
              ),
            ),
            SizedBox(height: 1),
            Text(
              '300m',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
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


  /* =========================================================
   * MONTHLY EXPENSE
   * ========================================================= */
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
          const SizedBox(height: 16),
          Row(
            children: [
              _expensePieChart(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _expenseLegend(),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        widget.onSwitchTab(3);
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
      return const Center(child: CircularProgressIndicator());
    }

    if (_monthByCategory.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _legendItem('Bảo dưỡng định kỳ', Colors.blue),
          _legendItem('Sửa chữa khẩn cấp', Colors.blueGrey),
          _legendItem('Nâng cấp & Tân trang', Colors.lightBlue),
          _legendItem('Phụ tùng mua ngoài', Colors.teal),
        ],
      );
    }

    final entries = _monthByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...entries
            .take(4)
            .map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    CircleAvatar(radius: 6, backgroundColor: colorOf(e.key)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        e.key,
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      money(e.value),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        const Divider(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Tổng:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              money(_monthTotal),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ],
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

  /* =========================================================
   * UTILITIES
   * ========================================================= */
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
                  'Cứu hộ\nkhẩn cấp',
                  height: 270,
                  imageSize: 90,
                  textSize: 17,
                  onTap: _showEmergencySheet,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(flex: 3, child: _utilityGrid()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _utilityGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _utilityCard(
                'images/calendar.png',
                'Đặt lịch \n bảo dưỡng',
                onTap: () => context.push('/booking', extra: widget.user),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _utilityCard(
                'images/garage.png',
                'Gara \n yêu thích',
                imageSize: 52,
                onTap: () => context.push('/favorites'),
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
                'Mẹo \n bảo dưỡng',
                //imageSize: 60,
                onTap: () => context.push('/maintenance-tips'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _utilityCard(
                'images/search.png',
                'Tra cứu \nphạt nguội',
                onTap: () => context.push('/traffic-fine', extra: widget.user),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _utilityCard(
    String imagePath,
    String label, {
    double imageSize = 46,
    double height = 130,
    double textSize = 14,
    VoidCallback? onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        height: height,
        decoration: _cardDecoration,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(imagePath, height: imageSize),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: textSize),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadLocation() async {
    try {
      final position = await _determinePosition();
      final cityName = await _getCityName(position);
      setState(() => city = cityName);
    } catch (_) {
      setState(() => city = 'Unknown');
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('GPS chưa bật');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Quyền truy cập vị trí bị từ chối vĩnh viễn');
    }

    return Geolocator.getCurrentPosition();
  }

  Future<String> _getCityName(Position position) async {
  final placemarks = await placemarkFromCoordinates(
    position.latitude,
    position.longitude,
  );

  if (placemarks.isEmpty) return 'Unknown';

  final p = placemarks.first;

  // DEBUG (có thể xóa sau)
  debugPrint('Placemark: $p');

  // Ưu tiên field hay có ở Việt Nam
  return p.administrativeArea ??       // TP.HCM, Hà Nội
         p.subAdministrativeArea ??    // Quận / Huyện
         p.locality ??                 // Phường / Xã (hay null)
         p.country ??                  // Vietnam
         'Unknown';
}

  /* =========================================================
   * EMERGENCY
   * ========================================================= */
  Widget _callTile(String phone, String label) {
    return ListTile(
      leading: const Icon(Icons.call, size: 40),
      title: Text(label, style: const TextStyle(fontSize: 15)),
      subtitle: Text(phone, style: const TextStyle(fontSize: 12)),
      onTap: () async {
        final uri = Uri(scheme: 'tel', path: phone);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
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
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
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
                const SizedBox(height: 12),
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
                        fontSize: 22, // 👈 giảm nhẹ để an toàn
                        color: Color(0xFFFBC71C),
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

  // =========================================================
  // EXPENSE PIE CHART
  // =========================================================
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
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    final entries = _monthByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final sections = <PieChartSectionData>[];
    for (final e in entries) {
      final percent = (e.value / _monthTotal) * 100.0;
      sections.add(
        PieChartSectionData(
          value: e.value.toDouble(),
          color: colorOf(e.key),
          title: percent >= 10 ? '${percent.toStringAsFixed(0)}%' : '',
          radius: 54,
          titleStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return SizedBox(
      width: 130,
      height: 130,
      child: PieChart(
        PieChartData(
          sections: sections,
          centerSpaceRadius: 22,
          sectionsSpace: 3,
        ),
      ),
    );
  }

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

  String money(int amount) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(amount)} đ';
  }

  Future<void> _loadMonthlyExpense() async {
    final rows = await getUserExpenses(userId);

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 1);

    final Map<String, int> agg = {};
    int total = 0;

    for (final r in rows) {
      final dateStr = r['expense_date']?.toString();
      if (dateStr != null) {
        try {
          final date = DateTime.parse(dateStr);
          if (date.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
              date.isBefore(endOfMonth)) {
            final cat = (r['category_name'] ?? 'Khác').toString();
            final amount = (r['amount'] ?? 0) as int;

            agg[cat] = (agg[cat] ?? 0) + amount;
            total += amount;
          }
        } catch (e) {
          // Skip invalid dates
        }
      }
    }

    if (mounted) {
      setState(() {
        _monthByCategory = agg;
        _monthTotal = total;
        _loadingExpense = false;
      });
    }
  }
}
