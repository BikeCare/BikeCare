import 'dart:async';

class TrafficFineViolation {
  final String date; // dd/MM/yyyy
  final String location;
  final String behavior;
  final int amountVnd;
  final String status; // "Chưa nộp" | "Đã nộp"

  const TrafficFineViolation({
    required this.date,
    required this.location,
    required this.behavior,
    required this.amountVnd,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
    'date': date,
    'location': location,
    'behavior': behavior,
    'amountVnd': amountVnd,
    'status': status,
  };
}

class TrafficFineMockService {
  // Database giả: key = "plate|type"
  static final Map<String, List<TrafficFineViolation>> _db = {
    '59A1-123.45|car': [
      const TrafficFineViolation(
        date: '12/10/2025',
        location: 'Q.1, TP.HCM',
        behavior: 'Vượt đèn đỏ',
        amountVnd: 4500000,
        status: 'Chưa nộp',
      ),
      const TrafficFineViolation(
        date: '03/11/2025',
        location: 'Q.3, TP.HCM',
        behavior: 'Chạy quá tốc độ',
        amountVnd: 3000000,
        status: 'Đã nộp',
      ),
    ],
    '59X1-999.99|bike': [
      const TrafficFineViolation(
        date: '20/09/2025',
        location: 'TP. Thủ Đức, TP.HCM',
        behavior: 'Không đội mũ bảo hiểm',
        amountVnd: 400000,
        status: 'Chưa nộp',
      ),
    ],
    // 5 biển số xe máy mới
    '29A1-12345|bike': [
      const TrafficFineViolation(
        date: '15/12/2025',
        location: 'Q.1, TP.HCM',
        behavior: 'Vượt đèn đỏ',
        amountVnd: 800000,
        status: 'Chưa nộp',
      ),
      const TrafficFineViolation(
        date: '20/12/2025',
        location: 'Q.3, TP.HCM',
        behavior: 'Không có giấy phép lái xe',
        amountVnd: 2000000,
        status: 'Chưa nộp',
      ),
    ],
    '51B2-67890|bike': [
      const TrafficFineViolation(
        date: '10/11/2025',
        location: 'Hà Nội',
        behavior: 'Chạy quá tốc độ 25km/h',
        amountVnd: 1000000,
        status: 'Đã nộp',
      ),
    ],
    '72C3-11111|bike': [
      const TrafficFineViolation(
        date: '05/12/2025',
        location: 'Đà Nẵng',
        behavior: 'Không đội mũ bảo hiểm',
        amountVnd: 400000,
        status: 'Chưa nộp',
      ),
      const TrafficFineViolation(
        date: '08/12/2025',
        location: 'Đà Nẵng',
        behavior: 'Dừng đỗ sai quy định',
        amountVnd: 300000,
        status: 'Chưa nộp',
      ),
      const TrafficFineViolation(
        date: '12/12/2025',
        location: 'Đà Nẵng',
        behavior: 'Vượt đèn vàng',
        amountVnd: 600000,
        status: 'Chưa nộp',
      ),
    ],
    '43D4-22222|bike': [
      const TrafficFineViolation(
        date: '01/12/2025',
        location: 'Cần Thơ',
        behavior: 'Nồng độ cồn vượt mức cho phép',
        amountVnd: 3000000,
        status: 'Chưa nộp',
      ),
    ],
    '92E5-33333|bike': [
      const TrafficFineViolation(
        date: '18/11/2025',
        location: 'Hải Phòng',
        behavior: 'Chở quá số người quy định',
        amountVnd: 500000,
        status: 'Đã nộp',
      ),
      const TrafficFineViolation(
        date: '25/11/2025',
        location: 'Hải Phòng',
        behavior: 'Không bật đèn khi trời tối',
        amountVnd: 200000,
        status: 'Chưa nộp',
      ),
    ],
  };

  // Hàm “gọi API”
  Future<List<TrafficFineViolation>> search({
    required String plate,
    required String vehicleType, // 'car' | 'bike'
  }) async {
    // giả lập delay mạng
    await Future.delayed(const Duration(milliseconds: 900));

    final normalizedPlate = plate.trim().toUpperCase();
    final key = '$normalizedPlate|$vehicleType';

    // giả lập lỗi mạng 1% (cho giống thật) - có thể bỏ
    // if (DateTime.now().millisecond % 100 == 0) throw Exception('Network error');

    return _db[key] ?? [];
  }
}
