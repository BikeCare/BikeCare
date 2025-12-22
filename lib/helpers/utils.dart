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

  await db.insert('vehicles', {
    'vehicle_id': DateTime.now().millisecondsSinceEpoch.toString(),
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

  return result.isNotEmpty ? result.first : null;
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
    orderBy: 'warranty_start DESC', // optional
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
  );

  if (result.isEmpty) return false;

  await db.update(
    'users',
    {'password': newPassword},
    where: 'username = ?',
    whereArgs: [username],
  );

  return true;
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
