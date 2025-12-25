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
