import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart'; // Để dùng listEquals
import '../../helpers/utils.dart';
import 'booking widgets/custom_date_time_picker.dart';

class BookingDetailPage extends StatefulWidget {
  final Map<String, dynamic> booking;
  final Map<String, dynamic> user;

  const BookingDetailPage({
    super.key,
    required this.booking,
    required this.user,
  });

  @override
  State<BookingDetailPage> createState() => _BookingDetailPageState();
}

class _BookingDetailPageState extends State<BookingDetailPage> {
  bool _isLoading = true;

  // Dữ liệu hiển thị & tham chiếu
  Map<String, dynamic>? _garageDetail;
  List<Map<String, dynamic>> _currentServices = []; // List object dịch vụ (để hiển thị tên)

  // Dữ liệu dùng để chọn (Options)
  List<Map<String, dynamic>> _allGarages = [];
  List<Map<String, dynamic>> _allServices = [];

  // Dữ liệu ĐANG SỬA (Draft)
  late Map<String, dynamic> _editingBooking; 
  List<String> _selectedServiceIds = [];

  // Dữ liệu GỐC (Để so sánh thay đổi)
  late Map<String, dynamic> _originalBooking;
  List<String> _originalServiceIds = [];

  @override
    void initState() {
      super.initState();
      // 1. Clone dữ liệu gốc để so sánh sau này
      _originalBooking = Map<String, dynamic>.from(widget.booking);
      
      // 2. Clone dữ liệu để sửa
      _editingBooking = Map<String, dynamic>.from(widget.booking);
      
      _loadFullData();
    }

  Future<void> _loadFullData() async {
    final bookingId = _editingBooking['booking_id'];
    final garageId = _editingBooking['garage_id'];

    // Lấy thông tin hiện tại
    final garage = await getGarageById(garageId);
    final currentServices = await getBookingServices(bookingId);
    
    // Lấy danh sách options
    final allGarages = await getAllGarages();
    final allServices = await getAllServices();

    // Lấy list ID dịch vụ gốc từ DB
    final db = await initializeDatabase();
    final serviceRows = await db.query('booking_services', 
        where: 'booking_id = ?', whereArgs: [bookingId]);
    final currentServiceIds = serviceRows.map((e) => e['service_id'] as String).toList();

    if (mounted) {
      setState(() {
        _garageDetail = garage;
        _currentServices = currentServices; // Để hiển thị tên ban đầu
        
        _allGarages = allGarages;
        _allServices = allServices;
        
        _selectedServiceIds = List.from(currentServiceIds); // List đang sửa
        _originalServiceIds = List.from(currentServiceIds); // List gốc
        
        _isLoading = false;
      });
    }
  }

  // --- KIỂM TRA CÓ THAY ĐỔI KHÔNG ---
  bool get _hasChanges {
    if (_isLoading) return false;

    // 1. So sánh Garage, Ngày, Giờ
    if (_editingBooking['garage_id'] != _originalBooking['garage_id']) return true;
    if (_editingBooking['booking_date'] != _originalBooking['booking_date']) return true;
    if (_editingBooking['booking_time'] != _originalBooking['booking_time']) return true;

    // 2. So sánh danh sách dịch vụ (Không quan tâm thứ tự)
    final setOriginal = _originalServiceIds.toSet();
    final setEditing = _selectedServiceIds.toSet();
    if (setOriginal.length != setEditing.length) return true;
    if (!setOriginal.containsAll(setEditing)) return true;

    return false;
  }

  // --- LOGIC LƯU ---
  Future<void> _handleSave() async {
    if (!_hasChanges) return; // Chặn nếu chưa có gì thay đổi

    setState(() => _isLoading = true);
    try {
      await updateBookingInfo(
        bookingId: _editingBooking['booking_id'],
        date: _editingBooking['booking_date'],
        time: _editingBooking['booking_time'],
        garageId: _editingBooking['garage_id'],
      );

      await updateBookingServices(
        _editingBooking['booking_id'],
        _selectedServiceIds,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đã cập nhật lịch hẹn thành công!")),
        );
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
      }
    }
  }

  // --- LOGIC XÓA ---
  Future<void> _handleDelete() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text("Xác nhận hủy"),
        content: const Text("Bạn có chắc chắn muốn hủy lịch hẹn này không?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Không", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await deleteBooking(_editingBooking['booking_id']);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã hủy lịch")));
                context.pop(true);
              }
            },
            child: const Text("Hủy ngay", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- UI PICKERS ---

  // 1. Đổi Garage (Popup Fullscreen)
  void _pickGarage() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        builder: (_, scrollController) {
          return Column(
            children: [
              const SizedBox(height: 16),
              const Text("Chọn cửa hàng khác", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _allGarages.length,
                  itemBuilder: (ctx, index) {
                    final g = _allGarages[index];
                    final isSelected = g['id'] == _editingBooking['garage_id'];
                    return ListTile(
                      leading: const Icon(Icons.store, color: Colors.blue),
                      title: Text(g['name'], style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                      subtitle: Text(g['address'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFF59CBEF)) : null,
                      onTap: () async {
                        final newDetail = await getGarageById(g['id']);
                        setState(() {
                          _editingBooking['garage_id'] = g['id'];
                          _editingBooking['garage_name'] = g['name'];
                          _garageDetail = newDetail;
                        });
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // 2. Đổi Dịch vụ (Popup Checkbox)
  void _pickServices() {
    List<String> tempSelected = List.from(_selectedServiceIds);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateSheet) => Container(
          height: MediaQuery.of(context).size.height * 0.6,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Chọn dịch vụ", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedServiceIds = tempSelected;
                        _currentServices = _allServices.where((s) => tempSelected.contains(s['service_id'])).toList();
                      });
                      Navigator.pop(ctx);
                    },
                    child: const Text("Xong", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF59CBEF))),
                  )
                ],
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: _allServices.length,
                  itemBuilder: (ctx, index) {
                    final s = _allServices[index];
                    final isChecked = tempSelected.contains(s['service_id']);
                    return CheckboxListTile(
                      activeColor: const Color(0xFF59CBEF),
                      title: Text(s['service_name']),
                      value: isChecked,
                      onChanged: (val) {
                        setStateSheet(() {
                          if (val == true) {
                            tempSelected.add(s['service_id']);
                          } else {
                            tempSelected.remove(s['service_id']);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 3. Chọn Ngày (Popup DatePicker)
  Future<void> _pickDate() async {
    DateTime current = DateTime.tryParse(_editingBooking['booking_date']) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFF59CBEF))),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _editingBooking['booking_date'] = picked.toIso8601String());
    }
  }

  // 4. Chọn Giờ (POPUP Dialog - Custom UI)
  void _pickTime() {
    TimeOfDay current;
    try {
      final format = DateFormat.jm();
      current = TimeOfDay.fromDateTime(format.parse(_editingBooking['booking_time']));
    } catch (e) {
      current = TimeOfDay.now();
    }

    // [FIX] Dùng showDialog thay vì showModalBottomSheet để đồng bộ kiểu "Popup"
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        contentPadding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Chọn giờ mới", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            // Dùng widget custom của bạn
            CustomTimePicker(
              initialTime: current,
              onTimeSelected: (newTime) {
                setState(() => _editingBooking['booking_time'] = newTime.format(context));
                Navigator.pop(ctx);
              },
              onCancel: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  void _goToGarageDetail() {
    if (_garageDetail != null) {
      context.push('/garage/detail', extra: {'garage': _garageDetail, 'user': widget.user});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(backgroundColor: Colors.white, body: Center(child: CircularProgressIndicator()));

    // Check trạng thái để enable/disable button
    bool canSave = _hasChanges;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Chi tiết lịch hẹn", style: TextStyle(color: Color(0xFF59CBEF), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(false),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === 1. XE (READ ONLY) ===
            const Text("Xe bảo dưỡng", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Image.asset(getVehicleImageByType(''), width: 60),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (_editingBooking['vehicle_name'] ?? _editingBooking['brand'] ?? 'Xe máy').toUpperCase(),
                          style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(_editingBooking['brand'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),

            // === 2. CỬA HÀNG ===
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Cửa hàng", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                GestureDetector(
                  onTap: _pickGarage, 
                  child: const Text("Đổi cửa hàng", style: TextStyle(color: Color(0xFF59CBEF), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _goToGarageDetail,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFF59CBEF)),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 60, height: 60, color: Colors.grey[200],
                        child: _buildGarageImage(_garageDetail),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text(_garageDetail?['name'] ?? _editingBooking['garage_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis)),
                              const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(_garageDetail?['address'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey), maxLines: 2, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // === 3. THỜI GIAN (SỬA TRỰC TIẾP) ===
            const Text("Thời gian bảo dưỡng", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text("Ngày", style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Row(children: [const Icon(Icons.calendar_today, size: 18, color: Color(0xFF59CBEF)), const SizedBox(width: 8), Text(_formatDate(_editingBooking['booking_date']), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))]),
                      ]),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _pickTime, // Giờ đã mở Popup (Dialog)
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text("Giờ", style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Row(children: [const Icon(Icons.access_time, size: 18, color: Color(0xFF59CBEF)), const SizedBox(width: 8), Text(_editingBooking['booking_time'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))]),
                      ]),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // === 4. DỊCH VỤ ===
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Dịch vụ bảo dưỡng", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                GestureDetector(
                  onTap: _pickServices,
                  child: const Text("Chỉnh sửa", style: TextStyle(color: Color(0xFF59CBEF), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _currentServices.isEmpty
                    ? [const Text("Chưa chọn dịch vụ nào", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))]
                    : _currentServices.map((s) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(children: [const Icon(Icons.check_circle, size: 16, color: Colors.green), const SizedBox(width: 8), Text(s['service_name'], style: const TextStyle(fontSize: 14))]),
                        )).toList(),
              ),
            ),

            const SizedBox(height: 40),

            // === 5. BUTTONS ===
            // Nút Lưu chỉ sáng lên khi có thay đổi (canSave = true)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: canSave ? _handleSave : null, // Disable nếu không có đổi
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF59CBEF),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300], // Màu khi disable
                  disabledForegroundColor: Colors.grey[500],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text("Cập nhật lịch hẹn", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: _handleDelete,
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text("Hủy lịch hẹn", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // Helper hiển thị ảnh Garage
  Widget _buildGarageImage(Map<String, dynamic>? garage) {
    if (garage == null) return const Icon(Icons.store, color: Colors.grey);
    String? imgUrl = garage['image'];
    if (imgUrl == null || imgUrl.isEmpty) {
        String? jsonImgs = garage['images'];
        if (jsonImgs != null && jsonImgs.isNotEmpty) {
            try {
                List<dynamic> list = jsonDecode(jsonImgs);
                if (list.isNotEmpty) imgUrl = list[0];
            } catch (_) {}
        }
    }
    if (imgUrl == null || imgUrl.isEmpty) return const Icon(Icons.store, color: Colors.grey);
    if (imgUrl.startsWith('http')) return Image.network(imgUrl, fit: BoxFit.cover);
    return Image.asset(imgUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.store, color: Colors.grey));
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}