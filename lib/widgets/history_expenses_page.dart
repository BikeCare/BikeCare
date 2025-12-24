import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../helpers/utils.dart';

const Color kCyanMain = Color(0xFF59CBEF);
const Color kCyanDeep = Color(0xFF2A9BC6);
const Color kCard = Colors.white;
const Color kBg = Colors.white;
const Color kText = Color(0xFF111111);
const Color kSubText = Color(0xFF666666);
const Color kBorderSoft = Color(0xFFEEEEEE); // Grey border

enum TrendMode { week, month }

class HistoryExpensesPage extends StatefulWidget {
  final Map<String, dynamic> user;
  const HistoryExpensesPage({super.key, required this.user});

  @override
  State<HistoryExpensesPage> createState() => _HistoryExpensesPageState();
}

class _HistoryExpensesPageState extends State<HistoryExpensesPage> {
  List<Map<String, dynamic>> expenses = [];
  bool loading = true;
  bool localeInitialized = false;

  TrendMode mode = TrendMode.week;

  @override
  void initState() {
    super.initState();
    _initLocale();
    _load();
  }

  Future<void> _initLocale() async {
    await initializeDateFormatting('vi_VN', null);
    if (mounted) {
      setState(() => localeInitialized = true);
    }
  }

  Future<void> _load() async {
    final userId = widget.user['user_id'].toString();
    final data = await getUserExpenses(userId);
    if (!mounted) return;
    setState(() {
      expenses = data;
      loading = false;
    });
  }

  // --------- helpers ----------
  final _money = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  String _fmtMoney(int v) => _money.format(v).replaceAll('₫', 'đ');

  DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    final s = raw.toString().trim();
    // kỳ vọng DB lưu 'YYYY-MM-DD'
    try {
      return DateTime.parse(s);
    } catch (_) {
      return null;
    }
  }

  String _fmtDateLine(DateTime d) {
    // dd/MM/yyyy
    return DateFormat('d/M/yyyy', 'vi_VN').format(d);
  }

  String _monthHeader(DateTime d) => 'Tháng ${d.month}/${d.year}';

  // Gom nhóm list theo tháng (giống ảnh)
  // return: Map< "Tháng m/yyyy", List<expense> > theo thứ tự mới -> cũ
  List<_MonthGroup> _groupByMonth(List<Map<String, dynamic>> items) {
    final map = <String, List<Map<String, dynamic>>>{};

    for (final e in items) {
      final dt = _parseDate(e['expense_date']) ?? DateTime.now();
      final key =
          '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}';
      map.putIfAbsent(key, () => []).add(e);
    }

    // sort month desc
    final keys = map.keys.toList()..sort((a, b) => b.compareTo(a));

    // sort item desc by date
    final groups = <_MonthGroup>[];
    for (final k in keys) {
      final list = map[k]!
        ..sort((a, b) {
          final da = _parseDate(a['expense_date']) ?? DateTime(1970);
          final db = _parseDate(b['expense_date']) ?? DateTime(1970);
          return db.compareTo(da);
        });

      final parts = k.split('-'); // yyyy-mm
      final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]), 1);

      groups.add(_MonthGroup(monthDate: dt, items: list));
    }
    return groups;
  }

  // --------- chart data ----------
  // Mode tuần: 4 cột (tuần) gần nhất (hoặc ít hơn nếu không có data)
  // Mode tháng: 4 cột (tháng) gần nhất
  List<_TrendBar> _buildTrendBars(
    List<Map<String, dynamic>> items,
    TrendMode m,
  ) {
    if (items.isEmpty) return [];

    // collect totals
    final totals = <String, int>{};

    for (final e in items) {
      final dt = _parseDate(e['expense_date']);
      if (dt == null) continue;
      final amount = (e['amount'] ?? 0) is int
          ? (e['amount'] as int)
          : int.tryParse(e['amount'].toString()) ?? 0;

      if (m == TrendMode.month) {
        final key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
        totals[key] = (totals[key] ?? 0) + amount;
      } else {
        // week key: yyyy-ww (ISO-ish simple)
        final wk = _weekNumber(dt);
        final key = '${dt.year}-W${wk.toString().padLeft(2, '0')}';
        totals[key] = (totals[key] ?? 0) + amount;
      }
    }

    final keys = totals.keys.toList()
      ..sort((a, b) => a.compareTo(b)); // tăng dần theo thời gian
    // lấy 4 mốc gần nhất
    final last = keys.length <= 4 ? keys : keys.sublist(keys.length - 4);

    return last.map((k) {
      final v = totals[k] ?? 0;
      final label = m == TrendMode.month
          ? k.split('-')[1] // mm
          : k.split('W').last; // ww
      return _TrendBar(label: label, value: v);
    }).toList();
  }

  // tuần trong năm (đủ dùng cho biểu đồ trend)
  int _weekNumber(DateTime d) {
    final dayOfYear = int.parse(DateFormat('D').format(d));
    final w = ((dayOfYear - d.weekday + 10) / 7).floor();
    return w < 1 ? 1 : w;
  }

  IconData _iconForCategory(String name) {
    final n = name.toLowerCase();
    if (n.contains('lốp') || n.contains('vá')) {
      return Icons.tire_repair;
    }
    if (n.contains('nhớt') || n.contains('dầu')) {
      return Icons.oil_barrel;
    }
    if (n.contains('phanh') || n.contains('bố thắng')) {
      return Icons.build_circle_outlined;
    }
    if (n.contains('rửa') || n.contains('vệ sinh')) {
      return Icons.water_drop_outlined;
    }
    return Icons.receipt_long;
  }

  @override
  Widget build(BuildContext context) {
    if (!localeInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final trendBars = _buildTrendBars(expenses, mode);
    final groups = _groupByMonth(expenses);
    final maxY = _calcNiceMaxY(trendBars.map((e) => e.value).toList());

    return Scaffold(
      backgroundColor: kBg, // Nền sáng
      body: SafeArea(
        top: true,
        bottom: false,
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Header Đẹp
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: kCyanMain.withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.bar_chart_rounded,
                                  color: kCyanDeep,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Lịch sử chi tiêu',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: kText,
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // 2. Xu hướng
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Xu hướng',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: kText,
                                ),
                              ),
                              _TrendToggle(
                                value: mode,
                                onChanged: (v) => setState(() => mode = v),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // 3. Chart Container
                          Container(
                            padding: const EdgeInsets.fromLTRB(16, 24, 20, 10),
                            decoration: BoxDecoration(
                              color: kCard,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: kBorderSoft),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 18,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                _TrendChart(bars: trendBars, maxY: maxY),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),

                          // 4. Danh sách chi tiêu (Header)
                          const Text(
                            'Chi tiết',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: kText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 5. List Items (SliverList)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final g = groups[index];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 12),
                            // Month Divider
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: kCyanMain.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _monthHeader(g.monthDate),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: kCyanDeep,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    margin: const EdgeInsets.only(left: 10),
                                    color: kCyanMain.withOpacity(0.12),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Items in this month
                            ...g.items.map((e) {
                              final title =
                                  (e['note']?.toString().trim().isNotEmpty ??
                                      false)
                                  ? e['note'].toString()
                                  : e['category_name']?.toString() ??
                                        'Chi tiêu';

                              final categoryName =
                                  e['category_name']?.toString() ?? 'Chi tiêu';
                              final dt =
                                  _parseDate(e['expense_date']) ??
                                  DateTime.now();

                              final place =
                                  (e['location'] ?? e['garage_name'] ?? '')
                                      .toString()
                                      .trim();

                              final amount = (e['amount'] ?? 0) is int
                                  ? (e['amount'] as int)
                                  : int.tryParse(e['amount'].toString()) ?? 0;

                              return _ExpenseRow(
                                icon: _iconForCategory(categoryName),
                                title: title,
                                subtitle: place.isEmpty
                                    ? _fmtDateLine(dt)
                                    : '${_fmtDateLine(dt)} • $place',
                                amountText: '-${_fmtMoney(amount)}',
                                chipText: categoryName,
                              );
                            }),
                            const SizedBox(height: 8),
                          ],
                        );
                      }, childCount: groups.length),
                    ),
                  ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor:
                Colors.transparent, // ✅ bỏ nền mặc định (hay bị tím/hồng)
            barrierColor: Colors.black.withOpacity(
              0.45,
            ), // ✅ nền đen mờ phía sau
            builder: (_) => AddExpenseSheet(user: widget.user),
          );
          _load();
        },
        backgroundColor: const Color(0xFF86C3E6),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  static double _calcNiceMaxY(List<int> values) {
    if (values.isEmpty) return 100000;
    final maxV = values.reduce((a, b) => a > b ? a : b);
    if (maxV <= 0) return 100000;
    // làm tròn lên để chart nhìn đẹp
    final step = 50000;
    final rounded = ((maxV + step - 1) ~/ step) * step;
    return rounded.toDouble();
  }
}

class _MonthGroup {
  final DateTime monthDate;
  final List<Map<String, dynamic>> items;
  _MonthGroup({required this.monthDate, required this.items});
}

class _TrendBar {
  final String label; // "13, 14" hoặc "09,10"
  final int value; // tổng tiền
  _TrendBar({required this.label, required this.value});
}

class _TrendToggle extends StatelessWidget {
  final TrendMode value;
  final ValueChanged<TrendMode> onChanged;

  const _TrendToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isWeek = value == TrendMode.week;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorderSoft),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TogglePill(
            text: 'Tuần',
            selected: isWeek,
            onTap: () => onChanged(TrendMode.week),
          ),
          _TogglePill(
            text: 'Tháng',
            selected: !isWeek,
            onTap: () => onChanged(TrendMode.month),
          ),
        ],
      ),
    );
  }
}

class _TogglePill extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _TogglePill({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? kCyanMain : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: selected ? Colors.white : kSubText,
          ),
        ),
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  final List<_TrendBar> bars;
  final double maxY;

  const _TrendChart({required this.bars, required this.maxY});

  @override
  Widget build(BuildContext context) {
    if (bars.isEmpty) {
      return Container(
        height: 170,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFFF6F8FA),
        ),
        child: const Text('Chưa có dữ liệu để vẽ biểu đồ'),
      );
    }

    return Container(
      height: 180,
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
      ),
      child: BarChart(
        BarChartData(
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 3,
            getDrawingHorizontalLine: (value) => FlLine(
              strokeWidth: 1,
              color: const Color(0xFFEEEEEE),
              dashArray: [4, 4],
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: const Border(
              left: BorderSide(color: Color(0xFFBDBDBD)),
              bottom: BorderSide(color: Color(0xFFBDBDBD)),
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 54,
                interval: maxY / 3,
                getTitlesWidget: (v, meta) {
                  final label = NumberFormat.compact(locale: 'vi_VN').format(v);
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(
                      '$labelđ',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFAAAAAA),
                      ),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, meta) {
                  final i = v.toInt();
                  if (i < 0 || i >= bars.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      bars[i].label,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: List.generate(bars.length, (i) {
            final isLast = i == bars.length - 1;
            return BarChartGroupData(
              x: i,
              barsSpace: 6,
              barRods: [
                BarChartRodData(
                  toY: bars[i].value.toDouble(),
                  width: 22,
                  borderRadius: BorderRadius.circular(2),
                  // giống ảnh: cột cuối vàng
                  color: isLast
                      ? const Color(0xFFFBC71C)
                      : kCyanMain.withOpacity(0.5),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _ExpenseRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String amountText;
  final String chipText;

  const _ExpenseRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amountText,
    required this.chipText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorderSoft, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon Box
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: kCyanMain.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: kCyanDeep, size: 22),
          ),
          const SizedBox(width: 14),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: kText,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      amountText,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: kText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: kSubText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (chipText.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: kCyanMain.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: kCyanMain.withOpacity(0.2)),
                        ),
                        child: Text(
                          chipText,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: kCyanDeep,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AddExpenseSheet extends StatefulWidget {
  final Map<String, dynamic> user;
  const AddExpenseSheet({super.key, required this.user});

  @override
  State<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<AddExpenseSheet> {
  final _amountCtl = TextEditingController();
  final _noteCtl = TextEditingController();

  List<Map<String, dynamic>> vehicles = [];
  List<Map<String, dynamic>> categories = [];

  String? _vehicleId;
  int? _categoryId;
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final userId = widget.user['user_id'].toString();
    final v = await getUserVehicles(userId);
    final c = await getExpenseCategories();
    if (!mounted) return;
    setState(() {
      vehicles = v;
      categories = c;
      _vehicleId = vehicles.isNotEmpty
          ? vehicles.first['vehicle_id'].toString()
          : null;
      _categoryId = categories.isNotEmpty
          ? categories.first['category_id'] as int
          : null;
    });
  }

  String _toIso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _save() async {
    final amount = int.tryParse(_amountCtl.text.trim());
    if (_vehicleId == null ||
        _categoryId == null ||
        amount == null ||
        amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vui lòng chọn xe, nhóm chi tiêu và nhập số tiền hợp lệ',
          ),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await addExpense(
        userId: widget.user['user_id'].toString(),
        vehicleId: _vehicleId!,
        amount: amount,
        expenseDateIso: _toIso(_date),
        categoryId: _categoryId!,
        note: _noteCtl.text.trim(),
      );
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _amountCtl.dispose();
    _noteCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    const primary = Color(0xFF59CBEF); // kCyanMain
    const border = Color(0xFFBFE3F7);
    const textSoft = Color(0xFF6B7280);
    const sheetBg = Color(0xFFF7FBFE);
    const Color kYellowAccent = Color(0xFFFBC71C);

    InputDecoration deco(String label) {
      return InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: textSoft,
          fontWeight: FontWeight.w700,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, bottom + 12),
      child: Container(
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: BorderRadius.circular(22),
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: primary,
              primary: primary,
              surfaceTint: Colors.white,
            ),
            splashColor: primary.withOpacity(0.1),
            highlightColor: primary.withOpacity(0.05),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // thanh kéo
              Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD6EAF6),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 10),

              const Text(
                'Thêm chi tiêu',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),

              TextField(
                controller: _noteCtl,
                decoration: deco('Sửa chữa').copyWith(
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  hintText: 'Ví dụ: Thay nhớt, vá lốp...',
                  hintStyle: const TextStyle(
                    color: Color(0xFF9CA3AF), // Grey 400
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                  ),
                  suffixIcon: const Icon(Icons.edit, color: Color(0xFF6B7280)),
                ),
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                initialValue: _vehicleId,
                items: vehicles
                    .map(
                      (v) => DropdownMenuItem(
                        value: v['vehicle_id'].toString(),
                        child: Text(
                          getVehicleDisplayName(v),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _vehicleId = v),
                decoration: deco('Chọn xe'),
                icon: const Icon(Icons.expand_more),
                dropdownColor: Colors.white,
              ),

              const SizedBox(height: 12),

              DropdownButtonFormField<int>(
                initialValue: _categoryId,
                items: categories
                    .map(
                      (c) => DropdownMenuItem(
                        value: c['category_id'] as int,
                        child: Text(
                          c['category_name'].toString(),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _categoryId = v),
                decoration: deco('Nhóm chi tiêu'),
                icon: const Icon(Icons.expand_more),
                dropdownColor: Colors.white,
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _amountCtl,
                keyboardType: TextInputType.number,
                decoration: deco('Số tiền'),
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Ngày: ${_toIso(_date)}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    SizedBox(
                      height: 36,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                            initialDate: _date,
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: primary,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) setState(() => _date = picked);
                        },
                        child: const Text(
                          'Chọn',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color.fromARGB(255, 0, 0, 0),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Lưu',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
