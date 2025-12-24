import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import '../widgets/booking/mock_seed_booking.dart';

// import '../widgets/maintenance_page/maintenance_tip_seed.dart';

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
    version: 2,
    onConfigure: (db) async {
      await db.execute('PRAGMA foreign_keys = ON');
    },
    onCreate: (db, version) async {
      // ================= USERS =================
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

      // ================= VEHICLES =================
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

      // ================= MAINTENANCE TIPS =================
      await db.execute('''
        CREATE TABLE maintenance_tips (
          tip_id INTEGER PRIMARY KEY AUTOINCREMENT,
          tip_title TEXT NOT NULL,
          tip_summary TEXT NOT NULL,
          tip_content TEXT NOT NULL
        )
      ''');

      // ================= GARAGES =================
      await db.execute('''
        CREATE TABLE garages (
          garage_id TEXT PRIMARY KEY,
          garage_name TEXT,
          address TEXT,
          latitude REAL,
          longitude REAL,
          phone TEXT,
          rating REAL
        )
      ''');

      // ================= SERVICES =================
      await db.execute('''
        CREATE TABLE services (
          service_id TEXT PRIMARY KEY,
          service_name TEXT
        )
      ''');

      // ================= BOOKINGS =================
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
          FOREIGN KEY (garage_id) REFERENCES garages(garage_id)
        )
      ''');

      // ================= BOOKING_SERVICES =================
      await db.execute('''
        CREATE TABLE booking_services (
          id TEXT PRIMARY KEY,
          booking_id TEXT,
          service_id TEXT,
          FOREIGN KEY (booking_id) REFERENCES bookings(booking_id),
          FOREIGN KEY (service_id) REFERENCES services(service_id)
        )
      ''');
      // ================= EXPENSES =================
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
          note TEXT,

          created_at TEXT DEFAULT CURRENT_TIMESTAMP,

          FOREIGN KEY (user_id) REFERENCES users(user_id),
          FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id),
          FOREIGN KEY (category_id) REFERENCES expense_categories(category_id)
        )
      ''');
      // ================= FAVORITES =================
      await db.execute('''
        CREATE TABLE favorites (
          favorite_id TEXT PRIMARY KEY,
          user_id TEXT,
          garage_id TEXT,
          FOREIGN KEY (user_id) REFERENCES users(user_id),
          FOREIGN KEY (garage_id) REFERENCES garages(garage_id)
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
    },
  );

  // 🔥 QUAN TRỌNG NHẤT: seed cho DB CŨ (KHÔNG xoá data khác)
  await seedMaintenanceTipsIfEmpty(db);
  await seedExpenseCategoriesIfEmpty(db);
  await MockSeed.seedBookingMockData(db);
  return db;
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
}) async {
  final db = await initializeDatabase();

  final uuid = const Uuid();

  await db.insert('vehicles', {
    'vehicle_id': uuid.v4(),
    'brand': brand,
    'vehicle_type': vehicleType,
    'user_id': userId,
  });
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
}) async {
  final db = await initializeDatabase();
  await db.update(
    'users',
    {
      'phone': phone,
      'location': location,
      'email': email,
      'date_of_birth': dateOfBirth,
      'gender': gender,
    },
    where: 'user_id = ?',
    whereArgs: [userId],
  );
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
    'note': note ?? '',
  });
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
      e.vehicle_id,
      c.category_name
    FROM expenses e
    JOIN expense_categories c ON c.category_id = e.category_id
    WHERE e.user_id = ?
    ORDER BY e.expense_date DESC
  ''',
    [userId],
  );
}
