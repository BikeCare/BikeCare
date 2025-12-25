import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../../helpers/utils.dart';

/// =======================
/// PAGE: LIST TIPS
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
    try {
      final Database db = await initializeDatabase();
      final data = await db.query('maintenance_tips');
      if (!mounted) return;
      setState(() {
        tips = data;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ===== HEADER đúng như hình (viền xanh trên/dưới) =====
            Container(
              height: 64,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Mẹo bảo dưỡng',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // cân title ở giữa
                ],
              ),
            ),

            // ===== BODY =====
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : (tips.isEmpty
                        ? const _EmptyView()
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: tips.length,
                            itemBuilder: (context, index) {
                              final tip = tips[index];
                              final id = (tip['tip_id'] as int?) ?? index;
                              final title = (tip['tip_title'] ?? '').toString();
                              final summary = (tip['tip_summary'] ?? '')
                                  .toString();
                              final content = (tip['tip_content'] ?? '')
                                  .toString();

                              final preview = summary.trim().isNotEmpty
                                  ? summary
                                  : content;

                              return _TipCard(
                                title: title,
                                preview: preview,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => MaintenanceTipDetailPage(
                                        id: id,
                                        title: title,
                                        content: content,
                                      ),
                                    ),
                                  );
                                },
                                onSeeMore: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => MaintenanceTipDetailPage(
                                        id: id,
                                        title: title,
                                        content: content,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          )),
            ),
          ],
        ),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final String title;
  final String preview;
  final VoidCallback onTap;
  final VoidCallback onSeeMore;

  const _TipCard({
    required this.title,
    required this.preview,
    required this.onTap,
    required this.onSeeMore,
  });

  @override
  Widget build(BuildContext context) {
    const titleBlue = Color(0xFF2E8EC7);
    const linkBlue = Color(0xFF4FAFE6);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFDADADA)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _MaintenanceIcon(),
            const SizedBox(width: 10),

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
                      fontWeight: FontWeight.w700,
                      color: titleBlue,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Preview + "Xem thêm" giống hình
                  Wrap(
                    children: [
                      Text(
                        _shorten(preview),
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.3,
                          color: Colors.black87,
                        ),
                      ),
                      const Text(' '),
                      GestureDetector(
                        onTap: onSeeMore,
                        child: const Text(
                          'Xem thêm',
                          style: TextStyle(
                            fontSize: 13,
                            color: linkBlue,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                            decorationThickness: 1,
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

  static String _shorten(String text) {
    final t = text.trim();
    if (t.length > 95) return '${t.substring(0, 95)}...';
    return t;
  }
}

/// Icon: vòng tròn vàng + tia sét + mũi tên đỏ (giống screenshot)
class _MaintenanceIcon extends StatelessWidget {
  const _MaintenanceIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFFFFD54F),
              shape: BoxShape.circle,
            ),
          ),
          const Icon(Icons.bolt, size: 36, color: Colors.black),
          const Positioned(
            left: -2,
            bottom: -2,
            child: Icon(
              Icons.arrow_downward,
              color: Color(0xFFE65A5A),
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(18),
        child: Text(
          'Chưa có mẹo bảo dưỡng.\nHãy seed dữ liệu vào bảng maintenance_tips.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14.5, color: Color(0xFF333333)),
        ),
      ),
    );
  }
}

/// =======================
/// PAGE: DETAIL
/// =======================
class MaintenanceTipDetailPage extends StatefulWidget {
  final int id;
  final String title;
  final String content;

  const MaintenanceTipDetailPage({
    super.key,
    required this.id,
    required this.title,
    required this.content,
  });

  @override
  State<MaintenanceTipDetailPage> createState() =>
      _MaintenanceTipDetailPageState();
}

class _MaintenanceTipDetailPageState extends State<MaintenanceTipDetailPage> {
  Map<String, dynamic>? tip;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadDetail();
  }

  Future<void> loadDetail() async {
    try {
      final Database db = await initializeDatabase();
      final data = await db.query(
        'maintenance_tips',
        where: 'tip_id = ?',
        whereArgs: [widget.id],
        limit: 1,
      );
      if (!mounted) return;
      setState(() {
        tip = data.isEmpty ? null : data.first;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const titleBlue = Color(0xFF2E8EC7);

    final showTitle = tip?['tip_title']?.toString() ?? widget.title;
    final showContent = tip?['tip_content']?.toString() ?? widget.content;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header giống trang list
            Container(
              height: 64,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Mẹo bảo dưỡng',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            showTitle,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: titleBlue,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            showContent,
                            style: const TextStyle(
                              fontSize: 15.5,
                              height: 1.6,
                              color: Color(0xFF333333),
                              letterSpacing: 0.2,
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
}
