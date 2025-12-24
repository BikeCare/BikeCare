import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
// import 'package:bikecare/helpers/utils.dart';
import '../booking_models/booking_state.dart';

// Temporary getItems function
Future<List<Map<String, dynamic>>> getItems(
  Database db,
  String tableName, {
  String? orderBy,
}) async {
  try {
    return await db.query(tableName, orderBy: orderBy);
  } catch (e) {
    debugPrint('Error in getItems($tableName): $e');
    return <Map<String, dynamic>>[];
  }
}

class Step1SelectVehicle extends StatefulWidget {
  final BookingState booking;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final Database db; // Nhận database

  const Step1SelectVehicle({
    super.key,
    required this.booking,
    required this.onNext,
    required this.onBack,
    required this.db,
  });

  @override
  State<Step1SelectVehicle> createState() => _Step1SelectVehicleState();
}

class _Step1SelectVehicleState extends State<Step1SelectVehicle> {
  // Lists to hold DB data
  List<Map<String, dynamic>> vehicles = [];
  List<Map<String, dynamic>> garages = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final g = await getItems(widget.db, 'garages');
      if (widget.booking.userId == null) {
        setState(() {
          vehicles = [];
          garages = g;
          isLoading = false;
        });
        return;
      }
      final v = await widget.db.query(
        'vehicles',
        where: 'user_id = ?',
        whereArgs: [widget.booking.userId],
      );

      if (mounted) {
        setState(() {
          vehicles = v;
          garages = g;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading data step 1: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: widget.onBack, // ✅ về homepage khi đang step 1
        ),
        centerTitle: true,
        title: const Text(
          'Đặt lịch bảo dưỡng',
          style: TextStyle(
            color: Color(0xFF59CBEF),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress
            _ProgressHeader(),

            const SizedBox(height: 24),

            const Text(
              'Chọn xe*',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _DropdownField(
              hint: 'Chọn xe từ garage',
              value: widget.booking.vehicleId,
              items: vehicles,
              // Map DB keys to standardized keys for dropdown if needed,
              // or just pass list and handle inside.
              // Here we pass List<Map<String, dynamic>>
              idKey: 'vehicle_id',
              nameKey: 'vehicle_name', // or brand/license_plate
              onSelected: (v) {
                setState(() {
                  widget.booking.vehicleId = v;
                });
              },
            ),

            const SizedBox(height: 20),

            const Text(
              'Chọn cửa hàng*',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _DropdownField(
              hint: 'Chọn cửa hàng',
              value: widget.booking.garageId,
              items: garages,
              idKey: 'id',
              nameKey: 'name',
              onSelected: (v) {
                setState(() {
                  widget.booking.garageId = v;
                });
              },
            ),

            const SizedBox(height: 32),

            Center(
              child: SizedBox(
                width: 180,
                height: 44,
                child: ElevatedButton(
                  onPressed: widget.booking.isStep1Valid ? widget.onNext : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF59CBEF), // nút bật
                    disabledBackgroundColor:
                        Colors.grey.shade300, // nền khi tắt
                    foregroundColor: const Color(0xFFFFC107), // chữ khi bật
                    disabledForegroundColor: const Color(
                      0xFF5B4706,
                    ), // 👈 chữ khi tắt
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Tiếp theo',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _circle(true),
            _line(),
            _circle(false),
            _line(),
            _circle(false),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'Chọn xe và cửa hàng',
              style: TextStyle(color: Color(0xFF59CBEF), fontSize: 12),
            ),
            Text('Chọn thời gian', style: TextStyle(fontSize: 12)),
            Text('Chọn dịch vụ', style: TextStyle(fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _circle(bool active) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? Colors.white : Colors.white,
        border: Border.all(
          color: active ? Color(0xFF59CBEF) : Colors.black,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _line() {
    return Expanded(child: Container(height: 1, color: Colors.black));
  }
}

class _DropdownField extends StatefulWidget {
  final String hint;
  final String? value;
  final List<Map<String, dynamic>> items;
  final ValueChanged<String> onSelected;
  final String idKey;
  final String nameKey;

  const _DropdownField({
    required this.hint,
    required this.value,
    required this.items,
    required this.onSelected,
    required this.idKey,
    required this.nameKey,
  });

  @override
  State<_DropdownField> createState() => _DropdownFieldState();
}

class _DropdownFieldState extends State<_DropdownField> {
  bool isOpen = false;

  String _displayText() {
    if (widget.value == null) return widget.hint;
    try {
      final item = widget.items.firstWhere(
        (e) => e[widget.idKey].toString() == widget.value,
      );
      return item[widget.nameKey].toString();
    } catch (e) {
      return widget.hint;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // FIELD
        Container(
          height: 44,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF59CBEF)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // TEXT (KHÔNG CLICK)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    _displayText(),
                    style: TextStyle(
                      color: widget.value == null ? Colors.grey : Colors.black,
                    ),
                  ),
                ),
              ),

              // ARROW BUTTON
              GestureDetector(
                onTap: () {
                  setState(() {
                    isOpen = !isOpen;
                  });
                },
                child: Container(
                  width: 44,
                  height: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFF59CBEF),
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Icon(
                    isOpen
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),

        // DROPDOWN LIST (INLINE)
        if (isOpen)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 200), // Limit height
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF59CBEF)),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            child: SingleChildScrollView(
              child: Column(
                children: widget.items.map((item) {
                  final id = item[widget.idKey].toString();
                  final raw = item[widget.nameKey];
                  final name = (raw == null || raw.toString().trim().isEmpty)
                      ? '(Không có tên)'
                      : raw.toString();

                  return InkWell(
                    onTap: () {
                      setState(() {
                        isOpen = false;
                      });
                      widget.onSelected(id);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Color(0xFF59CBEF),
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Text(name),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }
}
