import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
// import 'package:bikecare/helpers/utils.dart'; // import utils correct path
import '../booking_models/booking_state.dart';
import '../booking_widgets/booking_progress_header.dart';

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

class Step3SelectService extends StatefulWidget {
  final BookingState booking;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final Database db; // DB

  const Step3SelectService({
    super.key,
    required this.booking,
    required this.onNext,
    required this.onBack,
    required this.db,
  });

  @override
  State<Step3SelectService> createState() => _Step3SelectServiceState();
}

class _Step3SelectServiceState extends State<Step3SelectService> {
  List<Map<String, dynamic>> _services = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    try {
      // Load from 'services' table
      final s = await getItems(widget.db, 'services');
      if (mounted) {
        setState(() {
          _services = s;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading services: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _toggleService(String id) {
    setState(() {
      if (widget.booking.serviceIds.contains(id)) {
        widget.booking.serviceIds.remove(id);
      } else {
        widget.booking.serviceIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Validation check
    final isValid = widget.booking.isStep3Valid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: widget.onBack,
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
          children: [
            const BookingProgressHeader(currentStep: 3),

            const SizedBox(height: 24),

            // Title
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Chọn dịch vụ*',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Service List
            Expanded(
              child: _services.isEmpty
                  ? const Center(
                      child: Text('Chưa có dịch vụ nào trong hệ thống'),
                    )
                  : ListView.separated(
                      itemCount: _services.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final service = _services[index];
                        final id = service['service_id'].toString();
                        final name = service['service_name'].toString();
                        final isSelected = widget.booking.serviceIds.contains(
                          id,
                        );

                        return GestureDetector(
                          onTap: () => _toggleService(id),
                          behavior: HitTestBehavior.opaque, // Hit entire row
                          child: Row(
                            children: [
                              _buildRadioCircle(isSelected),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            // Bottom Button
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: SizedBox(
                width: 180,
                height: 44,
                child: ElevatedButton(
                  onPressed: isValid ? widget.onNext : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF59CBEF),
                    disabledBackgroundColor: Colors.grey.shade300,
                    foregroundColor: const Color(0xFFFFC107),
                    disabledForegroundColor: const Color(0xFF5B4706),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Kiểm tra thông tin',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioCircle(bool isSelected) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? const Color(0xFF59CBEF) : const Color(0xFF59CBEF),
          width: 1.5,
        ),
        color: Colors.white,
      ),
      child: isSelected
          ? const Center(
              child: Icon(Icons.check, size: 16, color: Color(0xFF59CBEF)),
            )
          : null,
    );
  }
}
