import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../helpers/utils.dart';

// --- PALETTE MÀU (Cerulean Blue Theme) ---
const Color kPrimaryColor = Color(0xFF2E8EC7); 
const Color kSecondaryColor = Color(0xFFE1F5FE); 
const Color kAccentColor = Color(0xFFFFC107); 
// [ĐÃ SỬA] Nền trang màu Trắng theo yêu cầu
const Color kBgColor = Colors.white; 
const Color kTextDark = Color(0xFF2D3436);
const Color kTextGrey = Color(0xFF636E72);
const Color kBorderColor = Color(0xFFE0E0E0); 

enum TrendMode { week, month }

class HistoryExpensesPage extends StatefulWidget {
  final Map<String, dynamic> user;
  const HistoryExpensesPage({super.key, required this.user});

  @override
  State<HistoryExpensesPage> createState() => _HistoryExpensesPageState();
}

class _HistoryExpensesPageState extends State<HistoryExpensesPage> {
  List<Map<String, dynamic>> expenses = [];
  List<Map<String, dynamic>> allExpenses = [];
  List<Map<String, dynamic>> vehicles = [];
  bool loading = true;
  bool localeInitialized = false;

  TrendMode mode = TrendMode.week;
  String? selectedVehicleId;

  @override
  void initState() {
    super.initState();
    _initLocale();
    _load();
  }

  Future<void> _initLocale() async {
    await initializeDateFormatting('vi_VN', null);
    if (mounted) setState(() => localeInitialized = true);
  }

  Future<void> _load() async {
    try {
      final userId = widget.user['user_id'].toString();
      final vehicleData = await getUserVehicles(userId);
      final data = await getUserExpenses(userId);

      if (!mounted) return;
      setState(() {
        allExpenses = data;
        vehicles = vehicleData;
        _filterExpenses();
        loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => loading = false);
    }
  }

  void _filterExpenses() {
    if (selectedVehicleId == null) {
      expenses = allExpenses;
    } else {
      expenses = allExpenses
          .where((e) => e['vehicle_id'] == selectedVehicleId)
          .toList();
    }
  }

  // --- ACTIONS ---
  void _showActionMenu(BuildContext context, Map<String, dynamic> expense) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.edit, color: kPrimaryColor),
              title: const Text('Chỉnh sửa chi tiêu', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _editExpense(expense);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Xoá chi tiêu', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(expense);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _editExpense(Map<String, dynamic> expense) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddExpenseSheet(user: widget.user, expense: expense),
    );
    _load();
  }

  void _confirmDelete(Map<String, dynamic> expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Xác nhận xoá"),
        content: const Text("Bạn có chắc chắn muốn xoá khoản chi này không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await deleteExpense(expense['expense_id'].toString());
              _load();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Xoá", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- DATA PROCESSING ---
  List<_TrendBar> _buildTrendBars(List<Map<String, dynamic>> items, TrendMode m) {
    if (items.isEmpty) return [];
    final totals = <String, int>{};

    for (final e in items) {
      final dt = DateTime.tryParse(e['expense_date'].toString()) ?? DateTime.now();
      final amount = int.tryParse(e['amount'].toString()) ?? 0;

      if (m == TrendMode.month) {
        final key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
        totals[key] = (totals[key] ?? 0) + amount;
      } else {
        final wk = _weekNumber(dt);
        final key = '${dt.year}-W${wk.toString().padLeft(2, '0')}';
        totals[key] = (totals[key] ?? 0) + amount;
      }
    }

    final keys = totals.keys.toList()..sort();
    final last = keys.length <= 5 ? keys : keys.sublist(keys.length - 5);

    return last.map((k) {
      final v = totals[k] ?? 0;
      final label = m == TrendMode.month ? "T${k.split('-')[1]}" : k.split('W').last;
      return _TrendBar(label: label, value: v);
    }).toList();
  }

  int _weekNumber(DateTime d) {
    int dayOfYear = int.parse(DateFormat("D").format(d));
    return ((dayOfYear - d.weekday + 10) / 7).floor();
  }

  double _calcMaxY(List<int> values) {
    if (values.isEmpty) return 100000;
    int maxV = values.reduce((a, b) => a > b ? a : b);
    if (maxV == 0) return 100000;
    return ((maxV * 1.2) / 100000).ceil() * 100000.0; 
  }

  List<_MonthGroup> _groupByMonth(List<Map<String, dynamic>> items) {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final e in items) {
      final dt = DateTime.tryParse(e['expense_date'].toString()) ?? DateTime.now();
      final key = '${dt.year}-${dt.month}';
      map.putIfAbsent(key, () => []).add(e);
    }
    final groups = <_MonthGroup>[];
    map.forEach((k, v) {
      final parts = k.split('-');
      groups.add(_MonthGroup(
        monthDate: DateTime(int.parse(parts[0]), int.parse(parts[1])),
        items: v..sort((a, b) => (b['expense_date'] as String).compareTo(a['expense_date'] as String)),
      ));
    });
    groups.sort((a, b) => b.monthDate.compareTo(a.monthDate));
    return groups;
  }

  IconData _iconForCategory(String name) {
    final n = name.toLowerCase();
    if (n.contains('lốp') || n.contains('vá')) return Icons.tire_repair;
    if (n.contains('nhớt') || n.contains('dầu')) return Icons.oil_barrel;
    if (n.contains('phanh') || n.contains('bố thắng')) return Icons.build_circle_outlined;
    if (n.contains('rửa') || n.contains('vệ sinh')) return Icons.water_drop_outlined;
    return Icons.receipt_long;
  }

  // --- UI BUILD ---
  @override
  Widget build(BuildContext context) {
    if (!localeInitialized) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final trendBars = _buildTrendBars(expenses, mode);
    final groups = _groupByMonth(expenses);
    final maxY = _calcMaxY(trendBars.map((e) => e.value).toList());

    return Scaffold(
      backgroundColor: kBgColor, // Nền Trắng
      appBar: AppBar(
        title: const Text(
          "Lịch sử chi tiêu",
          style: TextStyle(color: kTextDark, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: kTextDark),
        // Thêm đường kẻ mờ dưới AppBar cho tách biệt (giống Profile Page)
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: kBorderColor, height: 1),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => AddExpenseSheet(user: widget.user),
          );
          _load();
        },
        backgroundColor: kPrimaryColor,
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: kPrimaryColor,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- 1. DROPDOWN (Style Mới - Viền Xanh, Mũi tên Xanh) ---
                    DropdownButtonFormField<String?>(
                      value: selectedVehicleId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.fromLTRB(16, 12, 0, 12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: kPrimaryColor, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: kPrimaryColor, width: 1.5),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        suffixIcon: Container(
                          decoration: const BoxDecoration(
                            color: kPrimaryColor,
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                          ),
                          child: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                        ),
                        suffixIconConstraints: const BoxConstraints(minWidth: 50, minHeight: 48),
                      ),
                      icon: const SizedBox.shrink(),
                      dropdownColor: Colors.white,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kTextDark),
                      hint: const Text("Chọn xe để xem", style: TextStyle(color: kTextGrey, fontWeight: FontWeight.normal)),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('📊 Tất cả xe', style: TextStyle(fontWeight: FontWeight.bold, color: kTextDark)),
                        ),
                        ...vehicles.map((v) {
                          final name = getVehicleDisplayName(v);
                          return DropdownMenuItem<String?>(
                            value: v['vehicle_id'].toString(),
                            child: Text("🏍️ $name", style: const TextStyle(color: kTextDark)),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedVehicleId = value;
                          _filterExpenses();
                        });
                      },
                    ),
                    
                    const SizedBox(height: 24),

                    // --- 2. BIỂU ĐỒ (ĐÃ SỬA: SỐ TIỀN TRỤC TRÁI + BỎ TEXT MÔ TẢ) ---
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: kBorderColor), // Thêm viền mờ cho nổi bật trên nền trắng
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Xu hướng", 
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kTextDark)
                              ),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F3F4), // Nền xám nhạt cho toggle
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    _TrendButton("Tuần", mode == TrendMode.week, () => setState(() => mode = TrendMode.week)),
                                    _TrendButton("Tháng", mode == TrendMode.month, () => setState(() => mode = TrendMode.month)),
                                  ],
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 30),
                          
                          // THE CHART
                          AspectRatio(
                            aspectRatio: 1.6,
                            child: trendBars.isEmpty 
                              ? const Center(child: Text("Chưa có dữ liệu", style: TextStyle(color: kTextGrey)))
                              : BarChart(
                                BarChartData(
                                  maxY: maxY,
                                  barTouchData: BarTouchData(
                                    touchTooltipData: BarTouchTooltipData(
                                      getTooltipColor: (group) => kTextDark,
                                      tooltipPadding: const EdgeInsets.all(8),
                                      tooltipMargin: 8,
                                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                        return BarTooltipItem(
                                          '${NumberFormat.compact(locale: 'vi').format(rod.toY)}đ',
                                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                        );
                                      },
                                    ),
                                  ),
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: false,
                                    horizontalInterval: maxY / 4,
                                    getDrawingHorizontalLine: (value) => FlLine(
                                      color: kBorderColor,
                                      strokeWidth: 1,
                                      dashArray: [5, 5],
                                    ),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  titlesData: FlTitlesData(
                                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    // TRỤC TRÁI: HIỆN SỐ TIỀN
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 40,
                                        interval: maxY / 4,
                                        getTitlesWidget: (v, meta) {
                                          if (v == 0) return const SizedBox.shrink();
                                          final label = NumberFormat.compact(locale: 'vi').format(v);
                                          return Padding(
                                            padding: const EdgeInsets.only(right: 6),
                                            child: Text(
                                              label,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Color(0xFFAAAAAA),
                                                fontWeight: FontWeight.bold
                                              ),
                                              textAlign: TextAlign.right,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (v, meta) {
                                          if (v.toInt() >= 0 && v.toInt() < trendBars.length) {
                                            return Padding(
                                              padding: const EdgeInsets.only(top: 10.0),
                                              child: Text(
                                                trendBars[v.toInt()].label, 
                                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kTextGrey)
                                              ),
                                            );
                                          }
                                          return const Text('');
                                        },
                                      ),
                                    ),
                                  ),
                                  barGroups: trendBars.asMap().entries.map((e) {
                                    final isMax = e.value.value.toDouble() == trendBars.map((b)=>b.value).reduce((a,b)=>a>b?a:b).toDouble();
                                    return BarChartGroupData(
                                      x: e.key,
                                      barRods: [
                                        BarChartRodData(
                                          toY: e.value.value.toDouble(),
                                          color: isMax ? kAccentColor : kPrimaryColor, 
                                          width: 18,
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                          backDrawRodData: BackgroundBarChartRodData(
                                            show: true,
                                            toY: maxY,
                                            color: const Color(0xFFF1F3F4), // Nền cột mờ
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3. List Expenses
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final g = groups[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month, size: 16, color: kPrimaryColor),
                            const SizedBox(width: 8),
                            Text(
                              "Tháng ${g.monthDate.month}/${g.monthDate.year}",
                              style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimaryColor, fontSize: 14),
                            ),
                            const Expanded(child: Divider(indent: 10, color: kBorderColor)),
                          ],
                        ),
                      ),
                      ...g.items.map((e) => _ExpenseCard(
                        item: e, 
                        onLongPress: () => _showActionMenu(context, e)
                      )),
                    ],
                  );
                }, childCount: groups.length),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- SUB WIDGETS ---

class _TrendButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;
  const _TrendButton(this.text, this.isSelected, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? kPrimaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13, 
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : kTextGrey,
          ),
        ),
      ),
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onLongPress;
  const _ExpenseCard({required this.item, required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final amount = int.tryParse(item['amount'].toString()) ?? 0;
    final formatter = NumberFormat('#,###', 'vi_VN');
    final note = item['note'] ?? item['category_name'];
    final dateStr = item['expense_date'].toString().split('T')[0];
    final parts = dateStr.split('-');
    final displayDate = "${parts[2]}/${parts[1]}";

    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorderColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kSecondaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.receipt_long, color: kPrimaryColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(note, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kTextDark)),
                  const SizedBox(height: 4),
                  Text(item['garage_name'] ?? 'Không rõ địa điểm', style: const TextStyle(color: kTextGrey, fontSize: 13)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("-${formatter.format(amount)}đ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.redAccent)),
                const SizedBox(height: 4),
                Text(displayDate, style: const TextStyle(color: kTextGrey, fontSize: 12)),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _MonthGroup {
  final DateTime monthDate;
  final List<Map<String, dynamic>> items;
  _MonthGroup({required this.monthDate, required this.items});
}

class _TrendBar {
  final String label;
  final int value;
  _TrendBar({required this.label, required this.value});
}

class AddExpenseSheet extends StatefulWidget {
  final Map<String, dynamic> user;
  final Map<String, dynamic>? expense;
  const AddExpenseSheet({super.key, required this.user, this.expense});

  @override
  State<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<AddExpenseSheet> {
  final _amountCtl = TextEditingController();
  final _noteCtl = TextEditingController();
  final _garageCtl = TextEditingController();

  List<Map<String, dynamic>> vehicles = [];
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> allGarages = [];

  String? _vehicleId;
  int? _categoryId;
  String? _selectedCategoryName; 
  String? _selectedGarageId;
  bool _isOtherGarage = false;
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
    final g = await getAllGarages();

    if (!mounted) return;
    setState(() {
      vehicles = v;
      categories = c;
      allGarages = g;

      if (widget.expense != null) {
        final exp = widget.expense!;
        _amountCtl.text = exp['amount'].toString();
        _noteCtl.text = exp['note'] ?? '';
        _vehicleId = exp['vehicle_id']?.toString();
        _categoryId = exp['category_id'] as int?;
        _date = _parseDate(exp['expense_date']) ?? DateTime.now();

        final savedGarage = exp['garage_name']?.toString() ?? '';
        if (savedGarage.isNotEmpty) {
          final match = allGarages.indexWhere(
            (ga) => ga['name'] == savedGarage,
          );
          if (match != -1) {
            _selectedGarageId = allGarages[match]['id'].toString();
            _isOtherGarage = false;
          } else {
            _isOtherGarage = true;
            _garageCtl.text = savedGarage;
          }
        }
      } else {
        _vehicleId = vehicles.isNotEmpty
            ? vehicles.first['vehicle_id'].toString()
            : null;
        _categoryId = categories.isNotEmpty
            ? categories.first['category_id'] as int?
            : null;
        _selectedCategoryName = categories.isNotEmpty
            ? categories.first['category_name']?.toString()
            : null;
      }
    });
  }

  String _toIso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    final s = raw.toString().trim();
    try {
      return DateTime.parse(s);
    } catch (_) {
      return null;
    }
  }

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
      String finalGarageName = "";
      if (_isOtherGarage) {
        finalGarageName = _garageCtl.text.trim();
      } else if (_selectedGarageId != null) {
        final garage = allGarages.firstWhere(
          (g) => g['id'] == _selectedGarageId,
        );
        finalGarageName = garage['name'] ?? "";
      }

      if (widget.expense != null) {
        await updateExpense(
          expenseId: widget.expense!['expense_id'].toString(),
          amount: amount,
          expenseDateIso: _toIso(_date),
          categoryId: _categoryId!,
          garageName: finalGarageName,
          note: _noteCtl.text.trim(),
          vehicleId: _vehicleId,
        );
      } else {
        await addExpense(
          userId: widget.user['user_id'].toString(),
          vehicleId: _vehicleId!,
          amount: amount,
          expenseDateIso: _toIso(_date),
          categoryId: _categoryId!,
          garageName: finalGarageName,
          note: _noteCtl.text.trim(),
        );
      }
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _amountCtl.dispose();
    _noteCtl.dispose();
    _garageCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    const primary = kPrimaryColor;
    const border = Color(0xFFE0E0E0);
    const textSoft = Color(0xFF636E72);
    // [FIX] Nền Sheet màu trắng
    const sheetBg = Colors.white;

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
        floatingLabelBehavior: FloatingLabelBehavior.always,
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
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
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
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD6EAF6),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.expense != null
                      ? 'Cập nhật chi tiêu'
                      : 'Thêm chi tiêu',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _noteCtl,
                  decoration: deco('Sửa chữa').copyWith(
                    hintText: 'Ví dụ: Thay nhớt, vá lốp...',
                    hintStyle: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                    ),
                    suffixIcon: const Icon(
                      Icons.edit,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (!_isOtherGarage)
                  DropdownButtonFormField<String>(
                    value: _selectedGarageId,
                    hint: const Text(
                      'Chọn cửa hàng...',
                      style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                    ),
                    items: [
                      ...allGarages.map(
                        (g) => DropdownMenuItem(
                          value: g['id'].toString(),
                          child: Text(
                            g['name'].toString(),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const DropdownMenuItem(
                        value: "OTHER",
                        child: Row(
                          children: [
                            Icon(
                              Icons.add_circle_outline,
                              size: 18,
                              color: Colors.grey,
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Khác (Tự nhập tên...)",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() {
                      if (v == "OTHER") {
                        _isOtherGarage = true;
                        _selectedGarageId = null;
                      } else {
                        _selectedGarageId = v;
                        _isOtherGarage = false;
                      }
                    }),
                    decoration: deco('Địa điểm / Gara').copyWith(
                      prefixIcon: const Icon(
                        Icons.store,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                    icon: const Icon(Icons.expand_more),
                    dropdownColor: Colors.white,
                    isExpanded: true,
                  )
                else
                  TextField(
                    controller: _garageCtl,
                    autofocus: true,
                    decoration: deco('Địa điểm / Gara').copyWith(
                      prefixIcon: const Icon(
                        Icons.store,
                        color: Color(0xFF9CA3AF),
                      ),
                      hintText: 'Nhập tên cửa hàng...',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() {
                          _isOtherGarage = false;
                          _selectedGarageId = null;
                          _garageCtl.clear();
                        }),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _vehicleId,
                  items: vehicles
                      .map(
                        (v) => DropdownMenuItem(
                          value: v['vehicle_id'].toString(),
                          child: Text(
                            v['vehicle_name']?.toString() ?? 'Xe chưa đặt tên',
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
                DropdownButtonFormField<String>(
                  value: _selectedCategoryName,
                  hint: const Text(
                    'Chọn nhóm chi tiêu...',
                    style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                  ),
                  items: categories
                      .map(
                        (c) => DropdownMenuItem(
                          value: c['category_name'].toString(),
                          child: Text(
                            c['category_name'].toString(),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    final cat = categories.firstWhere(
                      (c) => c['category_name'] == v,
                      orElse: () => {},
                    );
                    setState(() {
                      _selectedCategoryName = v;
                      _categoryId = cat['category_id'] as int?;
                    });
                  },
                  decoration: deco('Nhóm chi tiêu'),
                  icon: const Icon(Icons.expand_more),
                  dropdownColor: Colors.white,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _amountCtl,
                  keyboardType: TextInputType.number,
                  decoration: deco('Số tiền').copyWith(
                    prefixIcon: const Icon(
                      Icons.payments,
                      color: Color(0xFF9CA3AF),
                    ),
                    hintText: 'Nhập số tiền chi tiêu...',
                  ),
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
                                      primary: Color(0xFF2E8EC7),
                                      onPrimary: Colors.white,
                                      surface: Colors.white,
                                      onSurface: Colors.black87,
                                    ),
                                    dialogBackgroundColor: Colors.white,
                                    textButtonTheme: TextButtonThemeData(
                                      style: TextButton.styleFrom(
                                        foregroundColor: const Color(
                                          0xFF2E8EC7,
                                        ),
                                      ),
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
                              color: Colors.black,
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
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
                SizedBox(height: bottom + 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}