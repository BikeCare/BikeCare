import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';

import '../widgets/maintenance_page/maintenance_tip_seed.dart';

// Test comment to refresh analyzer

// =========================================================
// DELETE OLD DB (DEV ONLY)
// =========================================================
Future<void> deleteOldDatabase() async {
  final dbPath = await getDatabasesPath();
  final path = join(dbPath, 'bikecare_database.db');
  await deleteDatabase(path);
}

// =========================================================
// GENERIC GET ITEMS (USED BY BOOKING FLOW WHICH PASSES DB)
// =========================================================
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

// =========================================================
// INIT DATABASE
// =========================================================
Future<Database> initializeDatabase() async {
  final dbPath = await getDatabasesPath();
  final path = join(dbPath, 'bikecare_database.db');

  final db = await openDatabase(
    path,
    version: 4,
    onConfigure: (db) async {
      await db.execute('PRAGMA foreign_keys = ON');
    },
    onOpen: (db) async {
      // Check if maintenance_tips is empty and seed it if needed
      final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM maintenance_tips'),
      );
      if (count == 0) {
        await _seedMaintenanceTips(db);
      }
    },
    onCreate: (db, version) async {
      // =================1.USERS =================
      await db.execute('''
        CREATE TABLE users (
          user_id TEXT PRIMARY KEY,
          username TEXT NOT NULL,
          email TEXT NOT NULL,
          password TEXT NOT NULL,
          full_name TEXT NOT NULL,
          phone TEXT,
          gender TEXT,
          date_of_birth TEXT,
          avatar_image TEXT,
          location TEXT
        )
      ''');

      // =================2. VEHICLES =================
      await db.execute('''
        CREATE TABLE vehicles (
          vehicle_id TEXT PRIMARY KEY,
          vehicle_name TEXT,
          brand TEXT NOT NULL,
          vehicle_type TEXT NOT NULL,
          license_plate TEXT,
          warranty_start TEXT,
          warranty_end TEXT,
          user_id TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users(user_id)
        )
      ''');
      // ================= 3.GARAGES =================
      await db.execute('''
        CREATE TABLE garages (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          address TEXT NOT NULL,
          phone TEXT,
          rating REAL,
          review_count INTEGER,
          image TEXT,
          images TEXT,
          lat REAL,
          lng REAL
        )
      ''');

      // ================= 4. FAVORITES =================

      await db.execute('''
        CREATE TABLE favorites (
          user_id TEXT,
          garage_id TEXT,
          PRIMARY KEY (user_id, garage_id)
        )
      ''');
      // ================= 5. REVIEWS =================
      await db.execute('''
        CREATE TABLE reviews (
          id TEXT PRIMARY KEY,
          garage_id TEXT NOT NULL,
          user_name TEXT,
          rating INTEGER,
          comment TEXT,
          created_at TEXT
        )
      ''');
      // Nạp dữ liệu mẫu
      if (kDebugMode) {
        await _seedGarages(db);
        await _seedReviews(db);
        await _seedUser(db);
        await _seedMaintenanceTips(db);
      }

      // ================= 6. MAINTENANCE TIPS =================
      await db.execute('''
        CREATE TABLE maintenance_tips (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          summary TEXT NOT NULL,
          content TEXT NOT NULL
        )
      ''');

      // ================= 7. SERVICES =================
      await db.execute('''
        CREATE TABLE services (
          service_id TEXT PRIMARY KEY,
          service_name TEXT
        )
      ''');

      // ================= 8. BOOKINGS =================
      await db.execute('''
        CREATE TABLE bookings (
          booking_id TEXT PRIMARY KEY,
          user_id TEXT,
          vehicle_id TEXT,
          garage_id TEXT,
          booking_date TEXT,
          booking_time TEXT,
          FOREIGN KEY (user_id) REFERENCES users(user_id),
          FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id),
          FOREIGN KEY (garage_id) REFERENCES garages(id)
        )
      ''');

      // ================= 9. BOOKING_SERVICES =================
      await db.execute('''
        CREATE TABLE booking_services (
          id TEXT PRIMARY KEY,
          booking_id TEXT,
          service_id TEXT,
          FOREIGN KEY (booking_id) REFERENCES bookings(booking_id),
          FOREIGN KEY (service_id) REFERENCES services(service_id)
        )
      ''');
      // ================= 10. EXPENSES =================
      await db.execute('''
        CREATE TABLE expense_categories (
          category_id INTEGER PRIMARY KEY AUTOINCREMENT,
          category_name TEXT NOT NULL UNIQUE
        )
      ''');
      await db.execute('''
        CREATE TABLE expenses (
          expense_id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          vehicle_id TEXT NOT NULL,
          booking_id TEXT,                 -- nullable (để mở rộng sau)
          amount INTEGER NOT NULL,         -- lưu số dương
          expense_date TEXT NOT NULL,      -- ISO yyyy-MM-dd
          category_id INTEGER NOT NULL,
          garage_name TEXT,                -- THÊM CỘT NÀY
          note TEXT,

          created_at TEXT DEFAULT CURRENT_TIMESTAMP,

          FOREIGN KEY (user_id) REFERENCES users(user_id),
          FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id),
          FOREIGN KEY (category_id) REFERENCES expense_categories(category_id)
        )
      ''');
    },
    onUpgrade: (db, oldVersion, newVersion) async {
      if (oldVersion < 2) {
        // Migration từ version 1 lên 2: Thêm bảng expenses
        await db.execute('''
          CREATE TABLE IF NOT EXISTS expenses (
            expense_id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            vehicle_id TEXT NOT NULL,
            booking_id TEXT,                 -- nullable (để mở rộng sau)
            amount INTEGER NOT NULL,         -- lưu số dương
            expense_date TEXT NOT NULL,      -- ISO yyyy-MM-dd
            category_id INTEGER NOT NULL,
            note TEXT,

            created_at TEXT DEFAULT CURRENT_TIMESTAMP,

            FOREIGN KEY (user_id) REFERENCES users(user_id),
            FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id),
            FOREIGN KEY (category_id) REFERENCES expense_categories(category_id)
          )
        ''');
      }
      if (oldVersion < 3) {
        // Migration lên v3: Thêm favorites và reviews
        await db.execute('''
          CREATE TABLE IF NOT EXISTS favorites (
            user_id TEXT,
            garage_id TEXT,
            PRIMARY KEY (user_id, garage_id)
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS reviews (
            id TEXT PRIMARY KEY,
            garage_id TEXT NOT NULL,
            user_name TEXT,
            rating INTEGER,
            comment TEXT,
            created_at TEXT
          )
        ''');
        // Seed dữ liệu mẫu cho bản mới
        await _seedReviews(db);
      }
      if (oldVersion < 4) {
        // Upgrade to 4: Recreate maintenance_tips with correct schema for UI
        await db.execute('DROP TABLE IF EXISTS maintenance_tips');
        await db.execute('''
          CREATE TABLE maintenance_tips (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            summary TEXT NOT NULL,
            content TEXT NOT NULL
          )
        ''');
        await _seedMaintenanceTips(db);
      }
    },
  );

  // 🔥 QUAN TRỌNG NHẤT: seed cho DB CŨ (KHÔNG xoá data khác)
  await seedMaintenanceTipsIfEmpty(db);
  await seedExpenseCategoriesIfEmpty(db);

  // FIX LỖI: Kiểm tra lại xem bảng reviews có thật sự tồn tại chưa (phòng trường hợp migration lỗi)

  await _seedReviews(db);

  // 🔥 QUAN TRỌNG: Kiểm tra và sửa cấu trúc bảng vehicles (Self-healing)
  try {
    // Kiểm tra xem cột 'license_plate' có tồn tại chưa
    final List<Map<String, dynamic>> columns = await db.rawQuery(
      'PRAGMA table_info(vehicles)',
    );
    final bool hasLicensePlate = columns.any(
      (c) => c['name'] == 'license_plate',
    );

    if (!hasLicensePlate) {
      debugPrint('🚧 Migrating vehicles table: adding missing columns...');
      await db.execute('ALTER TABLE vehicles ADD COLUMN vehicle_name TEXT');
      await db.execute('ALTER TABLE vehicles ADD COLUMN license_plate TEXT');
      await db.execute('ALTER TABLE vehicles ADD COLUMN warranty_start TEXT');
      await db.execute('ALTER TABLE vehicles ADD COLUMN warranty_end TEXT');
      debugPrint('✅ vehicles table migrated successfully.');
    }
  } catch (e) {
    debugPrint('⚠️ Error migrating vehicles table: $e');
  }
  await ensureDatabaseHealthy(db);
  return db;
}
// =========================================================
// DB SELF-HEALING (NO RESET NEEDED)
// =========================================================

Future<void> addColumnIfMissing(
  Database db,
  String table,
  String column,
  String columnDef,
) async {
  final cols = await db.rawQuery('PRAGMA table_info($table)');
  final exists = cols.any((c) => c['name'] == column);
  if (!exists) {
    debugPrint('➕ Adding column $column to $table');
    await db.execute('ALTER TABLE $table ADD COLUMN $column $columnDef');
  }
}

Future<void> ensureDatabaseHealthy(Database db) async {
  // 1) đảm bảo các bảng “hay bị thiếu” vẫn tồn tại (DB cũ / migrate fail)
  await db.execute('''
    CREATE TABLE IF NOT EXISTS favorites (
      user_id TEXT,
      garage_id TEXT,
      PRIMARY KEY (user_id, garage_id)
    )
  ''');

  await db.execute('''
    CREATE TABLE IF NOT EXISTS reviews (
      id TEXT PRIMARY KEY,
      garage_id TEXT NOT NULL,
      user_name TEXT,
      rating REAL,
      comment TEXT,
      created_at TEXT
    )
  ''');

  await db.execute('''
    CREATE TABLE IF NOT EXISTS expense_categories (
      category_id INTEGER PRIMARY KEY AUTOINCREMENT,
      category_name TEXT NOT NULL UNIQUE
    )
  ''');

  await db.execute('''
    CREATE TABLE IF NOT EXISTS maintenance_tips (
      tip_id INTEGER PRIMARY KEY AUTOINCREMENT,
      tip_title TEXT NOT NULL,
      tip_summary TEXT NOT NULL,
      tip_content TEXT NOT NULL
    )
  ''');

  // 2) tự bổ sung cột thiếu (chỉ ADD COLUMN, không phá data)
  // garages (đảm bảo các cột UI hay dùng tồn tại)
  await addColumnIfMissing(db, 'garages', 'images', 'TEXT');
  await addColumnIfMissing(db, 'garages', 'image', 'TEXT');
  await addColumnIfMissing(db, 'garages', 'rating', 'REAL');
  await addColumnIfMissing(db, 'garages', 'review_count', 'INTEGER');
  await addColumnIfMissing(db, 'garages', 'lat', 'REAL');
  await addColumnIfMissing(db, 'garages', 'lng', 'REAL');
  await addColumnIfMissing(db, 'garages', 'phone', 'TEXT');

  // vehicles (bạn đã có self-healing rồi, nhưng giữ thêm cho đồng bộ)
  await addColumnIfMissing(db, 'vehicles', 'vehicle_name', 'TEXT');
  await addColumnIfMissing(db, 'vehicles', 'license_plate', 'TEXT');
  await addColumnIfMissing(db, 'vehicles', 'warranty_start', 'TEXT');
  await addColumnIfMissing(db, 'vehicles', 'warranty_end', 'TEXT');

  // expenses
  await addColumnIfMissing(db, 'expenses', 'garage_name', 'TEXT');

  // 3) seed “an toàn” (chỉ seed khi trống) — bạn đã có 2 hàm này
}

Future<void> seedExpenseCategoriesIfEmpty(Database db) async {
  // đảm bảo bảng tồn tại nếu DB cũ
  await db.execute('''
    CREATE TABLE IF NOT EXISTS expense_categories (
      category_id INTEGER PRIMARY KEY AUTOINCREMENT,
      category_name TEXT NOT NULL UNIQUE
    )
  ''');

  final count =
      Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM expense_categories'),
      ) ??
      0;

  if (count > 0) return;

  final categories = [
    'Bảo dưỡng định kỳ',
    'Sửa chữa khẩn cấp',
    'Nâng cấp & tân trang',
    'Phụ tùng',
  ];

  final batch = db.batch();
  for (final name in categories) {
    batch.insert('expense_categories', {
      'category_name': name,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }
  await batch.commit(noResult: true);
}

Future<void> seedMaintenanceTipsIfEmpty(Database db) async {
  // đảm bảo bảng tồn tại (phòng trường hợp DB cũ thiếu bảng)
  await db.execute('''
    CREATE TABLE IF NOT EXISTS maintenance_tips (
      tip_id INTEGER PRIMARY KEY AUTOINCREMENT,
      tip_title TEXT NOT NULL,
      tip_summary TEXT NOT NULL,
      tip_content TEXT NOT NULL
    )
  ''');

  final count =
      Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM maintenance_tips'),
      ) ??
      0;

  if (count > 0) return;

  await db.transaction((txn) async {
    final batch = txn.batch();
    // for (final tip in maintenanceTipsSeed) {
    //   batch.insert('maintenance_tips', tip);
    // }
    await batch.commit(noResult: true);
  });

  debugPrint('🌱 maintenance_tips seeded (batch)');
}

// =========================================================
// INSERT GENERIC DATA
// =========================================================
Future<void> insertData(
  Database db,
  String tableName,
  Map<String, dynamic> data,
) async {
  await db.insert(
    tableName,
    data,
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

// =========================================================
// CHECK USERNAME EXISTS (REGISTER)
// =========================================================
Future<bool> checkUsernameExists(Database db, String username) async {
  final result = await db.query(
    'users',
    where: 'username = ?',
    whereArgs: [username],
  );
  return result.isNotEmpty;
}

// =========================================================
// REGISTER USER + VEHICLE (LOCAL)
// =========================================================
Future<String?> registerUser({
  required String username,
  required String email,
  required String password,
  required String fullName,
  required String brand,
  required String vehicleType,
}) async {
  final db = await initializeDatabase();

  // 1️⃣ Check username
  if (await checkUsernameExists(db, username)) {
    return 'USERNAME_EXISTS';
  }

  // 2️⃣ Generate IDs
  final uuid = const Uuid();
  final userId = uuid.v4();
  final vehicleId = uuid.v4();

  // 3️⃣ Insert USER
  await insertData(db, 'users', {
    'user_id': userId,
    'username': username,
    'email': email,
    'password': password,
    'full_name': fullName,
  });

  // 4️⃣ Insert VEHICLE
  await insertData(db, 'vehicles', {
    'vehicle_id': vehicleId,
    'brand': brand,
    'vehicle_type': vehicleType,
    'user_id': userId,
  });

  debugPrint('✅ User registered: $userId, vehicle: $vehicleId');
  return null; // SUCCESS
}

// =========================================================
// SAVE USER'S VEHICLE
// =========================================================

Future<void> saveUserVehicle({
  required String userId,
  required String brand,
  required String vehicleType,
  String? name,
  String? licensePlate,
  String? warrantyStart,
  String? warrantyEnd,
}) async {
  final db = await initializeDatabase();
  final uuid = const Uuid(); // Nhớ import package uuid nếu chưa có
  await db.insert('vehicles', {
    'vehicle_id': uuid.v4(), // Tạo ID ngẫu nhiên
    'user_id': userId,
    'brand': brand,
    'vehicle_type': vehicleType,
    // Lưu các trường mới (nếu null thì lưu chuỗi rỗng)
    'vehicle_name': name ?? '',
    'license_plate': licensePlate ?? '',
    'warranty_start': warrantyStart ?? '',
    'warranty_end': warrantyEnd ?? '',
  }, conflictAlgorithm: ConflictAlgorithm.replace);

  debugPrint('✅ Vehicle saved successfully for user: $userId');
}

// =========================================================
// LOGIN WITH USERNAME + PASSWORD (LOCAL ONLY)
// =========================================================
Future<Map<String, dynamic>?> loginUser({
  required String username,
  required String password,
}) async {
  final db = await initializeDatabase();

  final result = await db.query(
    'users',
    where: 'username = ? AND password = ?',
    whereArgs: [username, password],
  );

  if (result.isNotEmpty) {
    return result.first;
  }
  return null;
}

// =========================================================
// Homepage
// =========================================================
String getLastName(String fullName) {
  final parts = fullName.trim().split(RegExp(r'\s+'));
  return parts.isNotEmpty ? parts.last : fullName;
}

double getVehicleImageHeight(String vehicleType) {
  switch (vehicleType) {
    case '<175cc':
      return 110;
    default:
      return 95;
  }
}

// =========================================================
// RESET PASSWORD (LOCAL)
// =========================================================
Future<bool> resetPassword({
  required String username,
  required String email,
  required String newPassword,
}) async {
  final db = await initializeDatabase();

  final result = await db.query(
    'users',
    where: 'username = ? AND email = ?',
    whereArgs: [username, email],
    limit: 1,
  );

  if (result.isEmpty) return false;

  await db.update(
    'users',
    {'password': newPassword},
    where: 'username = ? AND email = ?',
    whereArgs: [username, email],
  );

  return true;
}

// =========================================================
// GET USER VEHICLES
// =========================================================
Future<List<Map<String, dynamic>>> getUserVehicles(String userId) async {
  final db = await initializeDatabase();

  final result = await db.query(
    'vehicles',
    where: 'user_id = ?',
    whereArgs: [userId],
    orderBy: 'vehicle_id DESC', // optional
  );

  return result;
}

// =========================================================
// VEHICLE DISPLAY NAME (vehicle_name -> brand fallback)
// =========================================================
String getVehicleDisplayName(Map<String, dynamic> vehicle) {
  final name = vehicle['vehicle_name'];
  final brand = vehicle['brand'];

  if (name != null && name.toString().trim().isNotEmpty) {
    return name;
  }

  return brand; // fallback nếu chưa đặt tên xe
}

// =========================================================
// VEHICLE IMAGE BY TYPE
// =========================================================
String getVehicleImageByType(String vehicleType) {
  switch (vehicleType) {
    case '<175cc':
      return 'images/motorbike.png';
    default:
      return 'images/motor.png';
  }
}

// =========================================================
// GET ALL MAINTENANCE TIPS
// =========================================================
Future<List<Map<String, dynamic>>> getMaintenanceTips() async {
  final db = await initializeDatabase();

  return db.query('maintenance_tips', orderBy: 'tip_id DESC');
}

Future<Map<String, dynamic>?> getUserById(String userId) async {
  final db = await initializeDatabase();
  final result = await db.query(
    'users',
    where: 'user_id = ?',
    whereArgs: [userId],
    limit: 1,
  );
  return result.isNotEmpty ? result.first : null;
}

Future<void> updateUserProfile({
  required String userId,
  String? phone,
  String? location,
  String? email,
  String? dateOfBirth,
  String? gender,
  String? avatarImage,
}) async {
  final db = await initializeDatabase();
  final Map<String, dynamic> data = {};
  if (phone != null) data['phone'] = phone;
  if (location != null) data['location'] = location;
  if (email != null) data['email'] = email;
  if (dateOfBirth != null) data['date_of_birth'] = dateOfBirth;
  if (gender != null) data['gender'] = gender;
  if (avatarImage != null) data['avatar_image'] = avatarImage;

  if (data.isEmpty) return;
  await db.update('users', data, where: 'user_id = ?', whereArgs: [userId]);
}

Future<List<Map<String, dynamic>>> getExpenseCategories() async {
  final db = await initializeDatabase();
  return db.query('expense_categories', orderBy: 'category_name ASC');
}

Future<void> addExpense({
  required String userId,
  required String vehicleId,
  required int amount,
  required String expenseDateIso, // yyyy-MM-dd
  required int categoryId,
  String? bookingId,
  String? garageName, // KHÔI PHỤC TRƯỜNG NÀY
  String? note,
}) async {
  final db = await initializeDatabase();
  final uuid = const Uuid();

  await db.insert('expenses', {
    'expense_id': uuid.v4(),
    'user_id': userId,
    'vehicle_id': vehicleId,
    'booking_id': bookingId,
    'amount': amount,
    'expense_date': expenseDateIso,
    'category_id': categoryId,
    'garage_name': garageName ?? '', // KHÔI PHỤC TRƯỜNG NÀY
    'note': note ?? '',
  });
}

Future<void> updateExpense({
  required String expenseId,
  required int amount,
  required String expenseDateIso,
  required int categoryId,
  String? garageName,
  String? note,
  String? vehicleId,
}) async {
  final db = await initializeDatabase();
  final Map<String, dynamic> data = {
    'amount': amount,
    'expense_date': expenseDateIso,
    'category_id': categoryId,
    'garage_name': garageName ?? '',
    'note': note ?? '',
  };
  if (vehicleId != null) data['vehicle_id'] = vehicleId;

  await db.update(
    'expenses',
    data,
    where: 'expense_id = ?',
    whereArgs: [expenseId],
  );
}

Future<void> deleteExpense(String expenseId) async {
  final db = await initializeDatabase();
  await db.delete('expenses', where: 'expense_id = ?', whereArgs: [expenseId]);
}

Future<List<Map<String, dynamic>>> getRecentRepairsByVehicle({
  required String userId,
  required String vehicleId,
  int limit = 2,
}) async {
  final db = await initializeDatabase();

  return db.rawQuery(
    '''
    SELECT 
      e.expense_id,
      e.amount,
      e.expense_date,
      e.note,
      e.garage_name,
      e.vehicle_id,
      e.category_id,
      c.category_name
    FROM expenses e
    JOIN expense_categories c ON c.category_id = e.category_id
    WHERE e.user_id = ?
      AND e.vehicle_id = ?
      AND (e.category_id IN (1, 2) OR c.category_name LIKE '%bảo dưỡng%' OR c.category_name LIKE '%sửa chữa%')
    ORDER BY e.expense_date DESC
    LIMIT ?
    ''',
    [userId, vehicleId, limit],
  );
}

Future<List<Map<String, dynamic>>> getUserExpenses(String userId) async {
  final db = await initializeDatabase();

  return db.rawQuery(
    '''
    SELECT 
      e.expense_id,
      e.amount,
      e.expense_date,
      e.note,
      e.garage_name,
      e.vehicle_id,
      e.category_id,
      c.category_name
    FROM expenses e
    JOIN expense_categories c ON c.category_id = e.category_id
    WHERE e.user_id = ?
    ORDER BY e.expense_date DESC
  ''',
    [userId],
  );
}

// =========================================================
// SEED GARAGE DATA (NẠP DỮ LIỆU GARA MẪU VÀO DB)
// =========================================================
Future<void> _seedGarages(Database db) async {
  final List<Map<String, dynamic>> garages = [
    {
      'id': '4aGTqfCMzswPcxbF8',
      'name': 'Sửa Xe Lưu Động - Cứu Hộ Xe Máy Quận 10',
      'address':
          '44 Hùng Vương, Phường 1, Quận 10, Thành phố Hồ Chí Minh 700000, Việt Nam',
      'phone': '1800577736',
      'rating': 0.0,
      'review_count': 0,
      'image': 'image/store_giahung1.png',
      'images': jsonEncode([
        'images/store_giahung1.png',
        'images/store_giahung2.png',
        'images/store_giahung3.png',
      ]),
      'lat': 10.766110263654424,
      'lng': 106.67929559931213,
    },
    {
      'id': 'imCmKKFkH1Wgk3X16',
      'name': 'Sửa Xe Lưu Động - Cứu Hộ Xe Máy Quận 10 Minh Thành Motor',
      'address':
          '768c Sư Vạn Hạnh, Phường 12, Quận 10, Thành phố Hồ Chí Minh 700000, Việt Nam',
      'phone': '02839695678',
      'rating': 0.0,
      'review_count': 0,
      'image': 'images/store_minhthanh1.png',
      'images': jsonEncode([
        'images/store_minhthanh1.png',
        'images/store_minhthanh2.png',
        'images/store_minhthanh3.png',
      ]),
      'lat': 10.775385308494414,
      'lng': 106.66891008619393,
    },
    {
      'id': 'FvvJ1BX9dpFW1c1m7',
      'name': 'Tiệm sửa xe THỨC NGUYỄN TRÃI',
      'address':
          '162 Hùng Vương, Phường 2, Quận 10, Thành phố Hồ Chí Minh 700000, Việt Nam',
      'phone': '0909123456',
      'rating': 0.0,
      'review_count': 0,
      'image': 'images/store_thuc1.png',
      'images': jsonEncode([
        'images/store_thuc1.png',
        'images/store_thuc2.png',
        'images/store_thuc3.png',
      ]),
      'lat': 10.762704590130419,
      'lng': 106.674858978084,
    },
    {
      'id': '1JCEsPi8dLb2LrSc6',
      'name': 'Sửa - rửa xe HOÀNG THƯƠNG',
      'address': 'Phường 12, Quận 10, Thành phố Hồ Chí Minh, Việt Nam',
      'phone': '0909123456',
      'rating': 0.0,
      'review_count': 0,
      'image': 'images/store_thuong1.png',
      'images': jsonEncode([
        'images/store_thuong1.png',
        'images/store_thuong2.png',
        'images/store_thuong3.png',
      ]),
      'lat': 10.772237456728373,
      'lng': 106.66836596068599,
    },
    {
      'id': 'wCTLzcF6xLbuPjMa9',
      'name':
          'True Moto Care Hoàng Phương - Cửa hàng sửa xe (NanoAuto) - chi nhánh 3/2',
      'address':
          '1201 3 Tháng 2, Phường 7, Quận 11, Thành phố Hồ Chí Minh, Việt Nam',
      'phone': '0355585261',
      'rating': 0.0,
      'review_count': 0,
      'image': 'images/store_hoangphuong1.png',
      'images': jsonEncode([
        'images/store_hoangphuong1.png',
        'images/store_hoangphuong2.png',
        'images/store_hoangphuong3.png',
      ]),
      'lat': 10.761767691595875,
      'lng': 106.6527712686252,
    },
    {
      'id': 'X8Nn3SNq5V8DUcS39',
      'name': 'Sửa xe Minh Tuấn',
      'address':
          '402 Vĩnh Viễn, Phường 8, Quận 10, Thành phố Hồ Chí Minh 72550, Việt Nam',
      'phone': '0776600718',
      'rating': 0.0,
      'review_count': 0,
      'image': 'images/store2_minhtuan.png',
      'images': jsonEncode([
        'images/store1.png',
        'images/store_thuong2.png',
        'images/store_thuong3.png',
      ]),
      'lat': 10.765293565021995,
      'lng': 106.66664678901783,
    },
    {
      'id': '369bv4JBoCMkd2U6A',
      'name': 'SỬA XE MÁY LƯU ĐỘNG HẬU , CỨU HỘ XE MÁY',
      'address':
          '320 Đ. 3 Tháng 2, Phường 10, Quận 10, Thành phố Hồ Chí Minh, Việt Nam',
      'phone': '0783731402',
      'rating': 0.0,
      'review_count': 0,
      'image': 'images/store_hau1.png',
      'images': jsonEncode([
        'images/store_hau1.png',
        'images/store_hau2.png',
        'images/store_hau3.png',
      ]),
      'lat': 10.770849800479093,
      'lng': 106.67076679891399,
    },
  ];

  for (var garage in garages) {
    await db.insert(
      'garages',
      garage,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}

Future<void> _seedMaintenanceTips(Database db) async {
  for (var tip in maintenanceTipsSeed) {
    await db.insert('maintenance_tips', {
      'title': tip['tip_title'],
      'summary': tip['tip_summary'],
      'content': tip['tip_content'],
    });
  }
}

// =========================================================
// SEED REVIEWS (REVIEW MẪU KHỚP ID)
// =========================================================
Future<void> _seedReviews(Database db) async {
  final reviews = [
    {
      'id': 'rv1',
      'garage_id': '4aGTqfCMzswPcxbF8', // Khớp ID Honda
      'user_name': 'Thanh Tùng',
      'rating': 5,
      'comment': 'Thợ hãng làm kỹ, phụ tùng chính hãng.',
      'created_at': DateTime.now()
          .subtract(const Duration(days: 2))
          .toIso8601String(),
    },
    {
      'id': 'rv2',
      'garage_id': '4aGTqfCMzswPcxbF8',
      'user_name': 'Minh Tuấn',
      'rating': 4,
      'comment': 'Đông khách nên chờ hơi lâu.',
      'created_at': DateTime.now()
          .subtract(const Duration(days: 5))
          .toIso8601String(),
    },
    {
      'id': 'rv3',
      'garage_id': '4aGTqfCMzswPcxbF8', // Khớp ID Shop2banh
      'user_name': 'Hùng Lâm',
      'rating': 5,
      'comment': 'Nhiều đồ chơi xe đẹp, nhân viên nhiệt tình.',
      'created_at': DateTime.now().toString(),
    },
    {
      'id': 'rv4',
      'garage_id': 'imCmKKFkH1Wgk3X16', // Khớp ID Honda
      'user_name': 'Minh Tùng',
      'rating': 5,
      'comment': 'Thợ giỏi và nhiệt tình.',
      'created_at': DateTime.now()
          .subtract(const Duration(days: 2))
          .toIso8601String(),
    },
    {
      'id': 'rv5',
      'garage_id': 'imCmKKFkH1Wgk3X16',
      'user_name': 'Minh Mẫn',
      'rating': 3.5,
      'comment': 'Giá cả hợp lý, sẽ quay lại lần sau. Mà đợi hơi lâu',
      'created_at': DateTime.now()
          .subtract(const Duration(days: 5))
          .toIso8601String(),
    },
    {
      'id': 'rv6',
      'garage_id': 'imCmKKFkH1Wgk3X16', // Khớp ID Shop2banh
      'user_name': 'Hùng Lâm',
      'rating': 4,
      'comment': 'Dịch vụ tốt, giá cả hợp lý.',
      'created_at': DateTime.now().toString(),
    },
  ];
  for (var rv in reviews) {
    await db.insert(
      'reviews',
      rv,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}

// =========================================================
// LẤY DANH SÁCH GARA GẦN NHẤT & TÍNH RATING THẬT
// =========================================================
Future<List<Map<String, dynamic>>> getNearestGarages(
  double userLat,
  double userLng,
) async {
  final db = await initializeDatabase();
  final List<Map<String, dynamic>> rawGarages = await db.query('garages');

  List<Map<String, dynamic>> processedGarages = [];

  for (var garage in rawGarages) {
    String garageId = garage['id'];

    // 1. Tự động tính Rating & Count từ bảng Reviews
    final countResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM reviews WHERE garage_id = ?',
      [garageId],
    );
    int realReviewCount = Sqflite.firstIntValue(countResult) ?? 0;

    final ratingResult = await db.rawQuery(
      'SELECT AVG(rating) as avgRating FROM reviews WHERE garage_id = ?',
      [garageId],
    );
    double realRating = 0.0;
    if (ratingResult.first['avgRating'] != null) {
      realRating = double.parse(ratingResult.first['avgRating'].toString());
    }

    // 2. Tính khoảng cách
    double garaLat = garage['lat'] ?? 0.0;
    double garaLng = garage['lng'] ?? 0.0;
    double distanceInMeters = Geolocator.distanceBetween(
      userLat,
      userLng,
      garaLat,
      garaLng,
    );

    processedGarages.add({
      ...garage,
      'rating': double.parse(realRating.toStringAsFixed(1)), // Rating thật
      'review_count': realReviewCount, // Số lượng review thật
      'distance': double.parse((distanceInMeters / 1000).toStringAsFixed(1)),
      'raw_distance': distanceInMeters,
    });
  }

  // Sắp xếp theo khoảng cách
  processedGarages.sort(
    (a, b) =>
        (a['raw_distance'] as double).compareTo(b['raw_distance'] as double),
  );
  return processedGarages;
}

// =========================================================
// SEARCH GARAGES (TÌM KIẾM GARA)
// =========================================================
Future<List<Map<String, dynamic>>> searchGarages(String keyword) async {
  final db = await initializeDatabase();

  if (keyword.isEmpty) {
    // Nếu không nhập gì thì lấy hết
    return await db.query('garages');
  } else {
    // Nếu có từ khóa thì tìm theo Tên hoặc Địa chỉ
    return await db.query(
      'garages',
      where: 'name LIKE ? OR address LIKE ?',
      whereArgs: ['%$keyword%', '%$keyword%'],
    );
  }
}

// ================= FAVORITES LOGIC =================

// Kiểm tra xem user đã like gara này chưa
Future<bool> isFavorite(String userId, String garageId) async {
  final db = await initializeDatabase();
  final result = await db.query(
    'favorites',
    where: 'user_id = ? AND garage_id = ?',
    whereArgs: [userId, garageId],
  );
  return result.isNotEmpty;
}

// Bật/Tắt like
Future<void> toggleFavorite(String userId, String garageId) async {
  final db = await initializeDatabase();
  final isExist = await isFavorite(userId, garageId);

  if (isExist) {
    // Nếu có rồi thì xóa (Un-like)
    await db.delete(
      'favorites',
      where: 'user_id = ? AND garage_id = ?',
      whereArgs: [userId, garageId],
    );
  } else {
    // Chưa có thì thêm vào (Like)
    await db.insert('favorites', {'user_id': userId, 'garage_id': garageId});
  }
}

// Lấy danh sách gara yêu thích
Future<List<Map<String, dynamic>>> getFavoriteGarages(String userId) async {
  final db = await initializeDatabase();
  // Join bảng favorites với bảng garages để lấy thông tin chi tiết
  return await db.rawQuery(
    '''
    SELECT g.* FROM garages g
    INNER JOIN favorites f ON g.id = f.garage_id
    WHERE f.user_id = ?
  ''',
    [userId],
  );
}

// ================= REVIEWS HELPER =================
Future<void> addReview(
  String garageId,
  String userName,
  int rating,
  String comment,
) async {
  final db = await initializeDatabase();
  await db.insert('reviews', {
    'id': const Uuid().v4(),
    'garage_id': garageId,
    'user_name': userName,
    'rating': rating,
    'comment': comment,
    'created_at': DateTime.now().toIso8601String(),
  });
}

Future<List<Map<String, dynamic>>> getReviews(String garageId) async {
  final db = await initializeDatabase();
  return await db.query(
    'reviews',
    where: 'garage_id = ?',
    whereArgs: [garageId],
    orderBy: "created_at DESC",
  );
}

// =========================================================
// GET USER REVIEWS (LẤY ĐÁNH GIÁ CỦA USER)
// =========================================================
Future<List<Map<String, dynamic>>> getUserReviews(String userName) async {
  final db = await initializeDatabase();
  // Join với bảng garages để lấy tên Gara đã đánh giá
  return await db.rawQuery(
    '''
    SELECT r.*, g.name as garage_name
    FROM reviews r
    LEFT JOIN garages g ON r.garage_id = g.id
    WHERE r.user_name = ?
    ORDER BY r.created_at DESC
  ''',
    [userName],
  );
}

// =========================================================
// SEED USER DEMO (TẠO TÀI KHOẢN MẶC ĐỊNH)
// =========================================================
Future<void> _seedUser(Database db) async {
  await db.insert('users', {
    'user_id': 'user_001',
    'username': 'Minh Anh',
    'password': '123',
    'email': 'demo@gmail.com',
    'full_name': 'Người dùng Demo',
    'phone': '0909123456',
    'gender': 'Nam',
    'date_of_birth': '2000-01-01',
    'location': 'TP. Hồ Chí Minh',
  }, conflictAlgorithm: ConflictAlgorithm.replace);

  // Kèm 1 chiếc xe cho user demo
  await db.insert('vehicles', {
    'vehicle_id': 'xe_demo_01',
    'user_id': 'user_001',
    'vehicle_name': 'Honda AirBlade 2020',
    'brand': 'Honda AirBlade',
    'vehicle_type': '>175cc',
    'license_plate': '59-X1 123.45',
    'warranty_start': DateTime.now()
        .subtract(const Duration(days: 365))
        .toIso8601String(),
    'warranty_end': DateTime.now()
        .add(const Duration(days: 365))
        .toIso8601String(),
  });
}

// =========================================================
// GET ALL GARAGES (FOR SELECTION)
// =========================================================
Future<List<Map<String, dynamic>>> getAllGarages() async {
  final db = await initializeDatabase();
  return db.query(
    'garages',
    columns: ['id', 'name', 'address'],
    orderBy: 'name ASC',
  );
}
