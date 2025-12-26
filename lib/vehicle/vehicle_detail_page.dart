import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../helpers/utils.dart';

class VehicleDetailPage extends StatefulWidget {
  final Map<String, dynamic> vehicle; // Dữ liệu xe truyền vào
  const VehicleDetailPage({super.key, required this.vehicle});

  @override
  State<VehicleDetailPage> createState() => _VehicleDetailPageState();
}

class _VehicleDetailPageState extends State<VehicleDetailPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _brandController;
  late TextEditingController _plateController;

  String _selectedType = '<175cc';
  DateTime? _warrantyStart;
  DateTime? _warrantyEnd;

  @override
  void initState() {
    super.initState();
    // 1. Fill dữ liệu cũ vào form
    _nameController = TextEditingController(text: widget.vehicle['vehicle_name']);
    _brandController = TextEditingController(text: widget.vehicle['brand']);
    _plateController = TextEditingController(text: widget.vehicle['license_plate']);
    _selectedType = widget.vehicle['vehicle_type'] ?? '<175cc';

    // Parse ngày tháng
    if (widget.vehicle['warranty_start'] != null && widget.vehicle['warranty_start'].toString().isNotEmpty) {
      _warrantyStart = DateTime.tryParse(widget.vehicle['warranty_start']);
    }
    if (widget.vehicle['warranty_end'] != null && widget.vehicle['warranty_end'].toString().isNotEmpty) {
      _warrantyEnd = DateTime.tryParse(widget.vehicle['warranty_end']);
    }
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart 
          ? (_warrantyStart ?? DateTime.now()) 
          : (_warrantyEnd ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) _warrantyStart = picked;
        else _warrantyEnd = picked;
      });
    }
  }

  Future<void> _updateVehicle() async {
    if (_formKey.currentState!.validate()) {
      await updateVehicle(
        vehicleId: widget.vehicle['vehicle_id'],
        brand: _brandController.text,
        vehicleType: _selectedType,
        name: _nameController.text,
        licensePlate: _plateController.text,
        warrantyStart: _warrantyStart?.toIso8601String(),
        warrantyEnd: _warrantyEnd?.toIso8601String(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cập nhật thành công!")));
        Navigator.pop(context, true); // Trả về true để reload
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Thông tin xe", style: TextStyle(color: Color(0xFF59CBEF), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader("Thông tin cơ bản"),
              _buildInput("Tên gợi nhớ (VD: Xe đi làm)", _nameController),
              _buildInput("Hãng xe (VD: Honda Vision)", _brandController),
              _buildInput("Biển số xe", _plateController),

              const SizedBox(height: 16),
              const Text("Loại xe", style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile(
                      title: const Text("<175cc"),
                      value: "<175cc",
                      groupValue: _selectedType,
                      activeColor: const Color(0xFF59CBEF),
                      onChanged: (v) => setState(() => _selectedType = v!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile(
                      title: const Text(">175cc"),
                      value: ">175cc",
                      groupValue: _selectedType,
                      activeColor: const Color(0xFF59CBEF),
                      onChanged: (v) => setState(() => _selectedType = v!),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              _buildHeader("Thời hạn bảo hành"),
              Row(
                children: [
                  Expanded(child: _buildDatePicker("Bắt đầu", _warrantyStart, true)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildDatePicker("Kết thúc", _warrantyEnd, false)),
                ],
              ),

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _updateVehicle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF59CBEF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Lưu thay đổi", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 10),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
    );
  }

  Widget _buildInput(String hint, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
        validator: (v) => v!.isEmpty ? "Vui lòng nhập thông tin" : null,
      ),
    );
  }

  Widget _buildDatePicker(String label, DateTime? date, bool isStart) {
    return InkWell(
      onTap: () => _pickDate(isStart),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          suffixIcon: const Icon(Icons.calendar_today, size: 18, color: Color(0xFF59CBEF)),
        ),
        child: Text(
          date != null ? DateFormat('dd/MM/yyyy').format(date) : "Chọn ngày",
          style: TextStyle(color: date != null ? Colors.black : Colors.grey),
        ),
      ),
    );
  }
}