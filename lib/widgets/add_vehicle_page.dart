import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../helpers/utils.dart'; // Import utils để gọi hàm lưu DB

class AddVehiclePage extends StatefulWidget {
  const AddVehiclePage({super.key});

  @override
  State<AddVehiclePage> createState() => _AddVehiclePageState();
}

class _AddVehiclePageState extends State<AddVehiclePage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();

  String _selectedType = '<175cc'; // Default
  DateTime? _warrantyStart;
  DateTime? _warrantyEnd;

  // Giả lập User ID (Sau này lấy từ Login)
  final String _userId = "user_001";

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _warrantyStart = picked;
        } else {
          _warrantyEnd = picked;
        }
      });
    }
  }

  Future<void> _saveVehicle() async {
    if (_formKey.currentState!.validate()) {
      // Gọi hàm từ utils.dart với đầy đủ thông tin
      await saveUserVehicle(
        userId: _userId,
        brand: _brandController.text,
        vehicleType: _selectedType,

        // --- THÊM CÁC DÒNG NÀY ---
        name: _nameController.text,
        licensePlate: _plateController.text,
        warrantyStart: _warrantyStart?.toIso8601String(),
        warrantyEnd: _warrantyEnd?.toIso8601String(),
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Thêm xe thành công!")));
        // Trả về true để trang Garage biết mà reload lại danh sách
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Thêm xe mới",
          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader("Thông tin xe"),
              _buildInput("Tên gợi nhớ (VD: Xe đi làm)", _nameController),
              _buildInput("Hãng xe (VD: Honda Vision)", _brandController),
              _buildInput("Biển số xe", _plateController),

              const SizedBox(height: 16),
              const Text(
                "Loại xe",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile(
                      title: const Text("<175cc"),
                      value: "<175cc",
                      groupValue: _selectedType,
                      onChanged: (v) => setState(() => _selectedType = v!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile(
                      title: const Text(">175cc"),
                      value: ">175cc",
                      groupValue: _selectedType,
                      onChanged: (v) => setState(() => _selectedType = v!),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              _buildHeader("Thời hạn bảo hành"),
              Row(
                children: [
                  Expanded(
                    child: _buildDatePicker("Bắt đầu", _warrantyStart, true),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDatePicker("Kết thúc", _warrantyEnd, false),
                  ),
                ],
              ),

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveVehicle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(
                      0xFF59CBEF,
                    ), // Màu xanh giống design Booking
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Lưu thông tin",
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

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
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
          suffixIcon: const Icon(Icons.calendar_today, size: 18),
        ),
        child: Text(
          date != null ? DateFormat('dd/MM/yyyy').format(date) : "Chọn ngày",
          style: TextStyle(color: date != null ? Colors.black : Colors.grey),
        ),
      ),
    );
  }
}
