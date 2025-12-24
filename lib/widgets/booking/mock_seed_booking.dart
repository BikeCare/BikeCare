// lib/mock/mock_seed.dart
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class MockSeed {
  static const _uuid = Uuid();

  /// Gọi 1 hàm duy nhất để seed tất cả mock data cần cho booking
  static Future<void> seedBookingMockData(Database db) async {
    // Đảm bảo tạo tất cả tables cần thiết trước
    await _ensureTablesExist(db);

    await _seedGaragesIfEmpty(db);
    await _seedServicesIfEmpty(db);
    debugPrint('✅ Mock booking data seeded');
  }

  static Future<void> _ensureTablesExist(Database db) async {
    // Tạo bảng bookings nếu chưa có
    await db.execute('''
      CREATE TABLE IF NOT EXISTS bookings (
        booking_id TEXT PRIMARY KEY,
        user_id TEXT,
        vehicle_id TEXT,
        garage_id TEXT,
        booking_date TEXT,
        booking_time TEXT,
        FOREIGN KEY (user_id) REFERENCES users(user_id),
        FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id),
        FOREIGN KEY (garage_id) REFERENCES garages(garage_id)
      )
    ''');

    // Tạo bảng booking_services nếu chưa có
    await db.execute('''
      CREATE TABLE IF NOT EXISTS booking_services (
        id TEXT PRIMARY KEY,
        booking_id TEXT,
        service_id TEXT,
        FOREIGN KEY (booking_id) REFERENCES bookings(booking_id),
        FOREIGN KEY (service_id) REFERENCES services(service_id)
      )
    ''');
  }

  static Future<void> _seedGaragesIfEmpty(Database db) async {
    // đảm bảo bảng tồn tại (an toàn cho DB cũ)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS garages (
        garage_id TEXT PRIMARY KEY,
        garage_name TEXT,
        address TEXT,
        latitude REAL,
        longitude REAL,
        phone TEXT,
        rating REAL
      )
    ''');

    final count =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM garages'),
        ) ??
        0;
    if (count > 0) return;

    final garages = [
      {
        'garage_id': _uuid.v4(),
        'garage_name': 'BikeCare Garage - Q1',
        'address': '12 Nguyễn Huệ, Q1, TP.HCM',
        'latitude': 10.7731,
        'longitude': 106.7040,
        'phone': '0909000111',
        'rating': 4.6,
      },
      {
        'garage_id': _uuid.v4(),
        'garage_name': 'BikeCare Garage - Bình Thạnh',
        'address': '35 Xô Viết Nghệ Tĩnh, Bình Thạnh, TP.HCM',
        'latitude': 10.8036,
        'longitude': 106.7123,
        'phone': '0909000222',
        'rating': 4.4,
      },
      {
        'garage_id': _uuid.v4(),
        'garage_name': 'BikeCare Garage - Tân Bình',
        'address': '120 Cộng Hòa, Tân Bình, TP.HCM',
        'latitude': 10.8017,
        'longitude': 106.6520,
        'phone': '0909000333',
        'rating': 4.2,
      },
    ];

    final batch = db.batch();
    for (final g in garages) {
      batch.insert('garages', g, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
  }

  static Future<void> _seedServicesIfEmpty(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS services (
        service_id TEXT PRIMARY KEY,
        service_name TEXT
      )
    ''');

    final count =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM services'),
        ) ??
        0;
    if (count > 0) return;

    final services = [
      'Thay nhớt',
      'Kiểm tra phanh',
      'Bảo dưỡng định kỳ',
      'Kiểm tra lốp',
      'Vệ sinh lọc gió',
      'Kiểm tra ắc quy',
    ];

    final batch = db.batch();
    for (final name in services) {
      batch.insert('services', {
        'service_id': _uuid.v4(),
        'service_name': name,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
  }
}
