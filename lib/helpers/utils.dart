import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';

// =========================================================
// DELETE OLD DB (DEV ONLY)
// =========================================================
Future<void> deleteOldDatabase() async {
  final dbPath = await getDatabasesPath();
  final path = join(dbPath, 'bikecare_database.db');
  await deleteDatabase(path);
}

// =========================================================
// INIT DATABASE
// =========================================================
Future<Database> initializeDatabase() async {
  final dbPath = await getDatabasesPath();
  final path = join(dbPath, 'bikecare_database.db');

  return openDatabase(
    path,
    version: 1,
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
    },
  );
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
// CHECK USERNAME EXISTS
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
// REGISTER USER + VEHICLE
// =========================================================
Future<String?> registerUser({
  required String username,
  required String email,
  required String password,
  required String fullName,

  // Vehicle info
  required String brand,
  required String vehicleType, // "<175cc" | ">=175cc"
}) async {
  final db = await initializeDatabase();

  // 1️⃣ Check username tồn tại
  final isExist = await checkUsernameExists(db, username);
  if (isExist) {
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
    'full_name': fullName, // (hash sau)
  });

  // 4️⃣ Insert VEHICLE
  await insertData(db, 'vehicles', {
    'vehicle_id': vehicleId,
    'brand': brand,
    'vehicle_type': vehicleType,
    'user_id': userId,
  });

  return null; // SUCCESS
}
