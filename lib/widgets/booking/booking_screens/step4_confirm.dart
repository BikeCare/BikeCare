import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:bikecare/helpers/utils.dart'; // utils correct path
import '../booking_models/booking_state.dart';

class Step4Confirm extends StatefulWidget {
  final BookingState booking;
  final VoidCallback onConfirm;
  final VoidCallback onBack;
  final Database db;

  const Step4Confirm({
    super.key,
    required this.booking,
    required this.onConfirm,
    required this.onBack,
    required this.db,
  });

  @override
  State<Step4Confirm> createState() => _Step4ConfirmState();
}

class _Step4ConfirmState extends State<Step4Confirm> {
  Map<String, dynamic>? vehicle;
  Map<String, dynamic>? garage;
  List<Map<String, dynamic>> services = [];
  bool isLoading = true;
  bool isBooking = false; // Processing booking

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    try {
      final db = widget.db;
      final vehicleId = widget.booking.vehicleId;
      final garageId = widget.booking.garageId;
      final serviceIds = widget.booking.serviceIds;

      Map<String, dynamic>? vData;
      Map<String, dynamic>? gData;
      List<Map<String, dynamic>> sList = [];

      // 1. Load Vehicle
      if (vehicleId != null) {
        final res = await db.query(
          'vehicles',
          where: 'vehicle_id = ?',
          whereArgs: [vehicleId],
        );
        if (res.isNotEmpty) vData = res.first;
      }

      // 2. Load Garage
      if (garageId != null) {
        final res = await db.query(
          'garages',
          where: 'id = ?',
          whereArgs: [garageId],
        );
        if (res.isNotEmpty) gData = res.first;
      }

      // 3. Load Selected Services
      if (serviceIds.isNotEmpty) {
        // Build placeholders for IN clause (?,?,?)
        final placeholders = List.filled(serviceIds.length, '?').join(',');
        sList = await db.query(
          'services',
          where: 'service_id IN ($placeholders)',
          whereArgs: serviceIds,
        );
      }

      if (mounted) {
        setState(() {
          vehicle = vData;
          garage = gData;
          services = sList;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading confirm details: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _handleBooking() async {
    if (isBooking) return;
    setState(() {
      isBooking = true;
    });

    try {
      final db = widget.db;
      // Generate booking ID (timestamp string as per requirements)
      final bookingId = DateTime.now().millisecondsSinceEpoch.toString();

      // Prepare Booking Data
      final bookingData = {
        'booking_id': bookingId,
        'user_id': widget.booking.userId,
        'vehicle_id': widget.booking.vehicleId,
        'garage_id': widget.booking.garageId,
        'booking_date': widget.booking.bookingDate?.toIso8601String(),
        'booking_time': widget.booking.bookingTime?.format(context),
      };

      // Insert Booking
      await insertData(db, 'bookings', bookingData);

      // Insert Booking Services
      for (var sId in widget.booking.serviceIds) {
        final bsId = '${bookingId}_$sId'; // unique ID
        await insertData(db, 'booking_services', {
          'id': bsId,
          'booking_id': bookingId,
          'service_id': sId,
        });
      }

      // Success
      widget.onConfirm();
    } catch (e) {
      debugPrint('Error creating booking: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi đặt lịch: $e')));
    } finally {
      if (mounted) {
        setState(() {
          isBooking = false;
        });
      }
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
          onPressed: widget.onBack,
        ),
        centerTitle: true,
        title: const Text(
          'Thông tin đặt lịch',
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
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Xe bảo dưỡng
                    const Text(
                      'Xe bảo dưỡng',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _buildVehicleCard(vehicle),

                    const SizedBox(height: 16),

                    // 2. Cửa hàng
                    const Text(
                      'Cửa hàng',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _buildGarageCard(garage),

                    const SizedBox(height: 16),

                    // 3. Thời gian
                    const Text(
                      'Thời gian bảo dưỡng',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDate(widget.booking.bookingDate),
                          style: const TextStyle(fontSize: 14),
                        ),
                        Text(
                          widget.booking.bookingTime?.format(context) ??
                              'Chưa chọn giờ',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // 4. Dịch vụ
                    const Text(
                      'Dịch vụ bảo dưỡng',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (services.isEmpty)
                      const Text(
                        'Chưa chọn dịch vụ',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      )
                    else
                      ...services.map(
                        (s) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(s['service_name'] ?? ''),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Button
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: SizedBox(
                width: 180,
                height: 44,
                child: ElevatedButton(
                  onPressed: isBooking ? null : _handleBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF59CBEF),
                    foregroundColor: const Color(0xFFFFC107),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: isBooking
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFFFC107),
                          ),
                        )
                      : const Text(
                          'Đặt lịch',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleCard(Map<String, dynamic>? v) {
    if (v == null) {
      return const Text(
        'Không tìm thấy thông tin xe',
        style: TextStyle(color: Colors.red),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.motorcycle, size: 60, color: Colors.blueGrey),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (v['vehicle_name'] ?? 'UNKNOWN').toString().toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFFBCA136),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  v['license_plate'] ?? v['brand'] ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGarageCard(Map<String, dynamic>? g) {
    if (g == null) {
      return const Text(
        'Không tìm thấy thông tin garage',
        style: TextStyle(color: Colors.red),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            color: Colors.red.shade100,
            child: const Icon(Icons.store, color: Colors.red),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        g['name'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${g['rating'] ?? 0.0}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const Icon(Icons.star, color: Color(0xFFFFC107), size: 14),
                  ],
                ),
                const SizedBox(height: 4),
                _iconText(Icons.location_on_outlined, g['address']),
                // _iconText(Icons.access_time, g['hours']), // Column might not exist in schema
                _iconText(Icons.phone, g['phone']),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconText(IconData icon, String? text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 12, color: Colors.grey),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text ?? '',
              style: const TextStyle(fontSize: 11, color: Colors.black87),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Chưa chọn ngày';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
