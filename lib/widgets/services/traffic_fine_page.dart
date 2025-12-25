import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:go_router/go_router.dart';
import 'traffic_fine_mock_service.dart';

class TrafficFinePage extends StatefulWidget {
  final Map<String, dynamic> user;

  const TrafficFinePage({super.key, required this.user});

  @override
  State<TrafficFinePage> createState() => _TrafficFinePageState();
}

class _TrafficFinePageState extends State<TrafficFinePage> {
  // ================= HEADER STATE =================
  String city = '...';
  String currentDate = DateFormat('dd/MM/yyyy').format(DateTime.now());

  // ================= MOCK API STATE =================
  final _plateController = TextEditingController();
  String _vehicleType = 'car';

  final _service = TrafficFineMockService();

  bool _loading = false;
  String? _error;
  List<TrafficFineViolation> _results = [];

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  @override
  void dispose() {
    _plateController.dispose();
    super.dispose();
  }

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildTrafficFineContent(),
                  ),

                  // ❌ NÚT ĐÓNG
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      iconSize: 28,
                      color: Colors.black54,
                      onPressed: () {
                        context.pop(); // ← quay về HomePage
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /* ================= HEADER ================= */

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: const Color(0xFF4F6472),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Xin chào, ${getLastName(widget.user['full_name'] ?? 'Bạn')}!',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$city, $currentDate',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(60, 2, 3, 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: const DecorationImage(
                image: AssetImage('images/map.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Gara gần nhất',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '300m',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /* ================= BODY CONTENT ================= */

  Widget _buildTrafficFineContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tra cứu phạt nguội',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _plateController,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: 'Biển số xe',
              hintText: 'Ví dụ: 59A1-123.45',
              labelStyle: const TextStyle(color: Color(0xFF4F6472)),

              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF4F6472)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color.fromARGB(255, 0, 0, 0),
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _vehicleType,
            decoration: InputDecoration(
              labelText: 'Loại phương tiện',
              labelStyle: const TextStyle(color: Color(0xFF4F6472)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF4F6472)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color.fromARGB(255, 0, 0, 0),
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(12),
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            items: const [
              DropdownMenuItem(
                value: 'car',
                child: Row(
                  children: [
                    Icon(
                      Icons.directions_car_rounded,
                      size: 20,
                      color: Color(0xFF4F6472),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Ô tô',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: 'bike',
                child: Row(
                  children: [
                    Icon(
                      Icons.two_wheeler_rounded,
                      size: 20,
                      color: Color(0xFF4F6472),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Xe máy',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => _vehicleType = value);
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _onSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF41ACD8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: _loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Tra cứu',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFFFBC71C),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: Colors.red)),

          if (_error == null && !_loading && _results.isEmpty)
            const Text('Chưa có kết quả. Hãy nhập biển số và bấm Tra cứu.'),

          if (_results.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Kết quả',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._results.map(_violationCard),
          ],
        ],
      ),
    );
  }

  Widget _violationCard(TrafficFineViolation v) {
    final money = NumberFormat('#,###', 'vi_VN').format(v.amountVnd);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${v.behavior} • ${v.status}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text('Ngày: ${v.date}'),
          Text('Nơi: ${v.location}'),
          Text('Số tiền: $money đ'),
        ],
      ),
    );
  }

  Future<void> _onSearch() async {
    final plate = _plateController.text.trim();

    setState(() {
      _error = null;
      _results = [];
    });

    if (plate.isEmpty) {
      setState(() => _error = 'Vui lòng nhập biển số xe');
      return;
    }

    setState(() => _loading = true);

    try {
      final data = await _service.search(
        plate: plate,
        vehicleType: _vehicleType,
      );

      if (!mounted) return;
      setState(() => _results = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Không thể tra cứu lúc này. Thử lại sau.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /* ================= LOCATION ================= */

  Future<void> _loadLocation() async {
    try {
      final position = await _determinePosition();
      final cityName = await _getCityName(position);
      if (!mounted) return;
      setState(() => city = cityName);
    } catch (e) {
      if (!mounted) return;
      setState(() => city = 'Unknown');
    }
  }

  Future<Position> _determinePosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('GPS chưa bật');

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Quyền vị trí bị từ chối');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Quyền vị trí bị từ chối vĩnh viễn');
    }

    return Geolocator.getCurrentPosition();
  }

  Future<String> _getCityName(Position position) async {
    final placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    return placemarks.isNotEmpty
        ? (placemarks.first.locality ?? 'Unknown')
        : 'Unknown';
  }

  /* ================= UTILS ================= */

  String getLastName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    return parts.isNotEmpty ? parts.last : fullName;
  }
}
