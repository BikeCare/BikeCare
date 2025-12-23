import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../../helpers/utils.dart';

/// =======================
/// COLOR SYSTEM (CÙNG TONE)
/// =======================
const Color kBg = Color(0xFFF7FBFF); // nền hơi xanh nhạt cho "sạch"
const Color kCard = Colors.white;
const Color kText = Color(0xFF111111);
const Color kSubText = Color(0xFF333333);

const Color kCyanMain = Color(0xFF59CBEF); // bạn yêu cầu
const Color kCyanDeep = Color(0xFF2A9BC6); // cyan đậm dùng cho text/cta
const Color kYellow = Color.fromARGB(255, 255, 193, 7); // vàng nhấn icon
const Color kBorderSoft = Color(0x1A59CBEF); // cyan mờ (viền nhẹ)

/// =======================
/// PAGE 1: LIST
/// =======================
class MaintenanceTipsPage extends StatefulWidget {
  const MaintenanceTipsPage({super.key});

  @override
  State<MaintenanceTipsPage> createState() => _MaintenanceTipsPageState();
}

class _MaintenanceTipsPageState extends State<MaintenanceTipsPage> {
  List<Map<String, dynamic>> tips = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadTips();
  }

  Future<void> loadTips() async {
    final Database db = await initializeDatabase();
    final data = await db.query('maintenance_tips', orderBy: 'id DESC');
    if (!mounted) return;
    setState(() {
      tips = data;
      loading = false;
    });
  }

  IconData _iconByTitle(String title) {
    final t = title.toLowerCase();
    if (t.contains('nhớt')) {
      return Icons.oil_barrel_outlined;
    }
    if (t.contains('lốp') || t.contains('lop')) {
      return Icons.tire_repair_outlined;
    }
    if (t.contains('bình') || t.contains('ắc')) {
      return Icons.battery_alert_outlined;
    }
    if (t.contains('xăng')) {
      return Icons.local_gas_station_outlined;
    }
    if (t.contains('khó nổ')) {
      return Icons.flash_on_outlined;
    }
    return Icons.lightbulb_outline;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Mẹo bảo dưỡng',
          style: TextStyle(color: kText, fontWeight: FontWeight.w900),
        ),
        iconTheme: const IconThemeData(color: kText),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: kCyanMain.withValues(alpha: 0.18)),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: kCyanMain))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: tips.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final tip = tips[index];
                final title = (tip['title'] ?? '').toString();
                final summary = (tip['summary'] ?? '').toString();

                return InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            MaintenanceTipDetailPage(id: tip['id'] as int),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: kCard,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: kCyanMain.withValues(alpha: 0.28),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: kCyanMain.withValues(alpha: 0.10),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ICON BOX
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: kCyanMain,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.75),
                              width: 1.2,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              _iconByTitle(title),
                              size: 32,
                              color: kYellow,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // TEXT
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  height: 1.15,
                                  fontWeight: FontWeight.w900,
                                  color: kText,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                summary,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.35,
                                  color: kSubText.withValues(alpha: 0.85),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 10),

                              // CTA CHIP
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: kCyanMain.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: kCyanMain.withValues(alpha: 0.35),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Xem thêm',
                                        style: TextStyle(
                                          color: kCyanDeep,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      SizedBox(width: 6),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 16,
                                        color: kCyanDeep,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

/// =======================
/// PAGE 2: DETAIL
/// =======================
class MaintenanceTipDetailPage extends StatefulWidget {
  final int id;
  const MaintenanceTipDetailPage({super.key, required this.id});

  @override
  State<MaintenanceTipDetailPage> createState() =>
      _MaintenanceTipDetailPageState();
}

class _MaintenanceTipDetailPageState extends State<MaintenanceTipDetailPage> {
  Map<String, dynamic>? tip;

  @override
  void initState() {
    super.initState();
    loadDetail();
  }

  Future<void> loadDetail() async {
    final Database db = await initializeDatabase();
    final data = await db.query(
      'maintenance_tips',
      where: 'id = ?',
      whereArgs: [widget.id],
      limit: 1,
    );
    if (!mounted || data.isEmpty) return;
    setState(() => tip = data.first);
  }

  @override
  Widget build(BuildContext context) {
    if (tip == null) {
      return const Scaffold(
        backgroundColor: kBg,
        body: Center(child: CircularProgressIndicator(color: kCyanMain)),
      );
    }

    final title = (tip!['title'] ?? '').toString();
    final content = (tip!['content'] ?? '').toString();

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Chi tiết',
          style: TextStyle(color: kText, fontWeight: FontWeight.w900),
        ),
        iconTheme: const IconThemeData(color: kText),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: kCyanMain.withValues(alpha: 0.18)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: kCyanMain.withValues(alpha: 0.25)),
            boxShadow: [
              BoxShadow(
                color: kCyanMain.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TITLE
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  height: 1.15,
                  fontWeight: FontWeight.w900,
                  color: kText,
                ),
              ),
              const SizedBox(height: 12),

              // DIVIDER
              Container(height: 1, color: kCyanMain.withValues(alpha: 0.18)),
              const SizedBox(height: 12),

              // CONTENT
              Text(
                content,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
