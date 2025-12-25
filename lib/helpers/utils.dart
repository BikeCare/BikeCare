import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert'; // <--- Để xử lý JSON ảnh

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
    onConfigure: (db) async {
      // Bật foreign key
      await db.execute('PRAGMA foreign_keys = ON');
    },
    onCreate: (db, version) async {
      // ================= 1. USERS =================
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

      // ================= 2. VEHICLES =================
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
          garage_id TEXT PRIMARY KEY, 
          garage_name TEXT NOT NULL,
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

      //  ================= 4. SERVICES (Cho Booking)=================
      await db.execute('''
        CREATE TABLE services (
          service_id TEXT PRIMARY KEY,
          service_name TEXT
        )
      ''');
      // ================= 5. BOOKINGS (Cho Booking)=================
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
      //================= 6. BOOKING_SERVICES=================
      await db.execute('''
        CREATE TABLE booking_services (
          id TEXT PRIMARY KEY,
          booking_id TEXT,
          service_id TEXT,
          FOREIGN KEY (booking_id) REFERENCES bookings(booking_id),
          FOREIGN KEY (service_id) REFERENCES services(service_id)
        )
      ''');
      // ================= 7. FAVORITES =================

      await db.execute('''
        CREATE TABLE favorites (
          user_id TEXT,
          garage_id TEXT,
          PRIMARY KEY (user_id, garage_id)
        )
      ''');
      // ================= 8. REVIEWS =================

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
      // ================= 9.EXPENSE_CATEGORIES =================
      await db.execute('''
        CREATE TABLE expense_categories (
          category_id INTEGER PRIMARY KEY AUTOINCREMENT,
          category_name TEXT NOT NULL UNIQUE
        )
      ''');

      // ================= 10. EXPENSES =================
      await db.execute('''
        CREATE TABLE expenses (
          expense_id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          vehicle_id TEXT NOT NULL,
          booking_id TEXT,
          amount INTEGER NOT NULL,
          expense_date TEXT NOT NULL,
          category_id INTEGER NOT NULL,
          garage_name TEXT,
          note TEXT,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (user_id) REFERENCES users(user_id),
          FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id),
          FOREIGN KEY (booking_id) REFERENCES bookings(booking_id),
          FOREIGN KEY (category_id) REFERENCES expense_categories(category_id)
        )
      ''');

      // ================= 11. MAINTENANCE_TIPS =================
      await db.execute('''
        CREATE TABLE maintenance_tips (
          tip_id INTEGER PRIMARY KEY AUTOINCREMENT,
          tip_title TEXT NOT NULL,
          tip_summary TEXT NOT NULL,
          tip_content TEXT NOT NULL
        )
      ''');

      // Nạp dữ liệu mẫu
      await _seedGarages(db);
      await _seedServices(db);
      await _seedReviews(db);
      await _seedUser(db);
      await _seedMaintenanceTips(db);
      await _seedExpenseCategories(db);
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
  // Thêm các tham số mới (cho phép null để tránh lỗi code cũ)
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

// =========================================================
// SEED GARAGE DATA (NẠP DỮ LIỆU GARA MẪU VÀO DB)
// =========================================================
Future<void> _seedGarages(Database db) async {
  final List<Map<String, dynamic>> garages = [
    {
      'garage_id': '4aGTqfCMzswPcxbF8',
      'garage_name': 'Sửa Xe Lưu Động - Cứu Hộ Xe Máy Quận 10',
      'address':
          '44 Hùng Vương, Phường 1, Quận 10, Thành phố Hồ Chí Minh 700000, Việt Nam',
      'phone': '1800577736',
      'rating': 0.0,
      'review_count': 0,
      'image': 'images/store_giahung1.png',
      'images': jsonEncode([
        'images/store_giahung1.png',
        'images/store_giahung2.png',
        'images/store_giahung3.png',
      ]),
      'lat': 10.766110263654424,
      'lng': 106.67929559931213,
    },
    {
      'garage_id': 'imCmKKFkH1Wgk3X16',
      'garage_name': 'Sửa Xe Lưu Động - Cứu Hộ Xe Máy Quận 10 Minh Thành Motor',
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
      'garage_id': 'FvvJ1BX9dpFW1c1m7',
      'garage_name': 'Tiệm sửa xe THỨC NGUYỄN TRÃI',
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
      'garage_id': '1JCEsPi8dLb2LrSc6',
      'garage_name': 'Sửa - rửa xe HOÀNG THƯƠNG',
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
      'garage_id': 'wCTLzcF6xLbuPjMa9',
      'garage_name':
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
      'garage_id': 'X8Nn3SNq5V8DUcS39',
      'garage_name': 'Sửa xe Minh Tuấn',
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
      'garage_id': '369bv4JBoCMkd2U6A',
      'garage_name': 'SỬA XE MÁY LƯU ĐỘNG HẬU , CỨU HỘ XE MÁY',
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
// LẤY DANH SÁCH GARA GẦN NHẤT (ĐÃ FIX CHO CẢ 2 BÊN)
// =========================================================
Future<List<Map<String, dynamic>>> getNearestGarages(
  double userLat,
  double userLng,
) async {
  final db = await initializeDatabase();
  final List<Map<String, dynamic>> rawGarages = await db.query('garages');

  List<Map<String, dynamic>> processedGarages = [];

  for (var garage in rawGarages) {
    // Sửa: Lấy ID từ cột garage_id
    String garageId = garage['garage_id'];

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
      'id': garageId,
      'name': garage['garage_name'],

      'rating': double.parse(realRating.toStringAsFixed(1)),
      'review_count': realReviewCount,
      'distance': double.parse((distanceInMeters / 1000).toStringAsFixed(1)),
      'raw_distance': distanceInMeters,
    });
  }
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
    return await getNearestGarages(0, 0);
  } else {
    // [FIX] Đổi 'name' thành 'garage_name'
    final res = await db.query(
      'garages',
      where: 'garage_name LIKE ? OR address LIKE ?',
      whereArgs: ['%$keyword%', '%$keyword%'],
    );
    // Map lại key cho UI cũ
    return res
        .map((g) => {...g, 'id': g['garage_id'], 'name': g['garage_name']})
        .toList();
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
  // [FIX] Đổi 'g.id' thành 'g.garage_id'
  final res = await db.rawQuery(
    '''
    SELECT g.* FROM garages g
    INNER JOIN favorites f ON g.garage_id = f.garage_id
    WHERE f.user_id = ?
  ''',
    [userId],
  );

  // Map lại key cho UI cũ
  return res
      .map((g) => {...g, 'id': g['garage_id'], 'name': g['garage_name']})
      .toList();
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

// Hỗ trợ lấy danh sách chung (Dùng cho Booking Step 1 & 3)
Future<List<Map<String, dynamic>>> getItems(Database db, String table) async {
  return await db.query(table);
}

// Nạp dữ liệu dịch vụ mẫu
Future<void> _seedServices(Database db) async {
  final services = [
    {'service_id': 'sv1', 'service_name': 'Thay nhớt'},
    {'service_id': 'sv2', 'service_name': 'Bảo dưỡng toàn bộ'},
    {'service_id': 'sv3', 'service_name': 'Vá vỏ xe'},
    {'service_id': 'sv4', 'service_name': 'Thay nhông sên dĩa'},
  ];
  for (var s in services) {
    await db.insert(
      'services',
      s,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}

// =========================================================
// SEED MAINTENANCE TIPS (MẸO BẢO DƯỠNG MẪU)
// =========================================================
Future<void> _seedMaintenanceTips(Database db) async {
  final tips = [
    {
      'tip_title': 'Thay nhớt định kỳ',
      'tip_summary': 'Nhớt giúp bôi trơn động cơ, giảm ma sát và hao mòn.',
      'tip_content':
          '''Thay nhớt định kỳ là một trong những bước bảo dưỡng quan trọng nhất cho xe máy của bạn.

🔧 Tại sao cần thay nhớt?
- Nhớt giúp bôi trơn các bộ phận động cơ, giảm ma sát
- Làm mát động cơ và ngăn ngừa quá nhiệt
- Loại bỏ cặn bẩn và mạt kim loại

⏰ Khi nào nên thay?
- Xe số: 1,000 - 1,500 km
- Xe tay ga: 2,000 - 3,000 km
- Hoặc mỗi 3 tháng (tùy điều kiện sử dụng)

💡 Lưu ý:
- Chọn loại nhớt phù hợp với dòng xe
- Kiểm tra mức nhớt thường xuyên
- Không để nhớt quá cũ vì sẽ mất tác dụng bôi trơn''',
    },
    {
      'tip_title': 'Kiểm tra áp suất lốp',
      'tip_summary':
          'Lốp đúng áp suất giúp xe vận hành êm ái và tiết kiệm xăng.',
      'tip_content':
          '''Áp suất lốp ảnh hưởng trực tiếp đến độ an toàn và hiệu suất xe.

🔧 Tầm quan trọng:
- Lốp non hơi: tăng tiêu hao nhiên liệu, mòn lốp không đều
- Lốp căng quá: giảm độ bám đường, dễ nổ lốp

⏰ Tần suất kiểm tra:
- Mỗi tuần hoặc trước chuyến đi xa
- Kiểm tra khi lốp nguội (chưa chạy xe)

💡 Áp suất khuyến nghị:
- Xe số: 28-32 PSI (bánh trước), 32-36 PSI (bánh sau)
- Xe tay ga: 25-30 PSI
- Tham khảo tem dán trên xe để biết chính xác''',
    },
    {
      'tip_title': 'Vệ sinh bộ lọc gió',
      'tip_summary': 'Lọc gió sạch giúp động cơ hoạt động hiệu quả hơn.',
      'tip_content':
          '''Bộ lọc gió giữ vai trò quan trọng trong việc cung cấp không khí sạch cho động cơ.

🔧 Chức năng:
- Lọc bụi bẩn trước khi không khí vào buồng đốt
- Giúp hỗn hợp nhiên liệu cháy hoàn toàn

⏰ Bảo dưỡng định kỳ:
- Vệ sinh: mỗi 3,000 - 5,000 km
- Thay mới: mỗi 10,000 - 15,000 km

💡 Dấu hiệu cần thay:
- Xe yếu, không tăng tốc tốt
- Tiêu hao xăng tăng
- Lọc gió bị đen, bẩn nhiều''',
    },
    {
      'tip_title': 'Bảo dưỡng hệ thống phanh',
      'tip_summary': 'Phanh an toàn là yếu tố sống còn khi lái xe.',
      'tip_content':
          '''Hệ thống phanh cần được kiểm tra thường xuyên để đảm bảo an toàn.

🔧 Các bộ phận cần kiểm tra:
- Má phanh (bố thắng)
- Dầu phanh
- Đĩa phanh
- Dây phanh (phanh cơ)

⏰ Thời điểm bảo dưỡng:
- Kiểm tra má phanh: mỗi 5,000 km
- Thay dầu phanh: mỗi năm hoặc 20,000 km
- Thay má phanh khi độ dày < 2mm

💡 Dấu hiệu phanh có vấn đề:
- Tiếng kêu rin rít khi phanh
- Phanh bị bó hoặc nhẹ hẫng
- Xe bị kéo lệch khi phanh''',
    },
    {
      'tip_title': 'Kiểm tra và thay bugi',
      'tip_summary': 'Bugi tốt giúp xe khởi động dễ dàng và chạy êm.',
      'tip_content':
          '''Bugi đảm nhận việc đánh lửa để đốt cháy hỗn hợp nhiên liệu trong động cơ.

🔧 Vai trò của bugi:
- Tạo tia lửa điện đốt cháy nhiên liệu
- Ảnh hưởng đến khả năng khởi động
- Quyết định hiệu suất động cơ

⏰ Thời điểm thay:
- Bugi thường: mỗi 10,000 - 15,000 km
- Bugi iridium: mỗi 40,000 - 60,000 km

💡 Dấu hiệu bugi hỏng:
- Xe khó khởi động
- Động cơ rung, chạy không êm
- Tiêu hao nhiên liệu tăng
- Bugi đen muội hoặc bị ăn mòn''',
    },
  ];

  for (var tip in tips) {
    await db.insert(
      'maintenance_tips',
      tip,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}

// =========================================================
// GET MAINTENANCE TIPS (LẤY DANH SÁCH MẸO BẢO DƯỠNG)
// =========================================================
Future<List<Map<String, dynamic>>> getMaintenanceTips() async {
  final db = await initializeDatabase();
  return db.query('maintenance_tips', orderBy: 'tip_id DESC');
}

// =========================================================
// SEED EXPENSE CATEGORIES
// =========================================================
Future<void> _seedExpenseCategories(Database db) async {
  final categories = [
    {'category_name': 'Bảo dưỡng định kỳ'},
    {'category_name': 'Sửa chữa khẩn cấp'},
    {'category_name': 'Nâng cấp & tân trang'},
    {'category_name': 'Phụ tùng'},
  ];

  for (var category in categories) {
    await db.insert(
      'expense_categories',
      category,
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }
}

// =========================================================
// GET EXPENSE CATEGORIES
// =========================================================
Future<List<Map<String, dynamic>>> getExpenseCategories() async {
  final db = await initializeDatabase();
  return db.query('expense_categories', orderBy: 'category_name ASC');
}

// =========================================================
// ADD EXPENSE
// =========================================================
Future<void> addExpense({
  required String userId,
  required String vehicleId,
  required int amount,
  required String expenseDateIso,
  required int categoryId,
  String? bookingId,
  String? garageName,
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
    'garage_name': garageName,
    'note': note,
  });
}

// =========================================================
// UPDATE EXPENSE
// =========================================================
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

  final data = {
    'amount': amount,
    'expense_date': expenseDateIso,
    'category_id': categoryId,
    'garage_name': garageName,
    'note': note,
  };

  if (vehicleId != null) {
    data['vehicle_id'] = vehicleId;
  }

  await db.update(
    'expenses',
    data,
    where: 'expense_id = ?',
    whereArgs: [expenseId],
  );
}

// =========================================================
// DELETE EXPENSE
// =========================================================
Future<void> deleteExpense(String expenseId) async {
  final db = await initializeDatabase();
  await db.delete('expenses', where: 'expense_id = ?', whereArgs: [expenseId]);
}

// =========================================================
// GET RECENT REPAIRS BY VEHICLE
// =========================================================
Future<List<Map<String, dynamic>>> getRecentRepairsByVehicle({
  required String userId,
  required String vehicleId,
  int limit = 2,
}) async {
  final db = await initializeDatabase();

  final result = await db.rawQuery(
    '''
    SELECT e.*, c.category_name
    FROM expenses e
    INNER JOIN expense_categories c ON e.category_id = c.category_id
    WHERE e.user_id = ? 
      AND e.vehicle_id = ?
    ORDER BY e.expense_date DESC
    LIMIT ?
  ''',
    [userId, vehicleId, limit],
  );

  return result;
}

// =========================================================
// GET USER EXPENSES
// =========================================================
Future<List<Map<String, dynamic>>> getUserExpenses(String userId) async {
  final db = await initializeDatabase();

  final result = await db.rawQuery(
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
    INNER JOIN expense_categories c ON e.category_id = c.category_id
    WHERE e.user_id = ?
    ORDER BY e.expense_date DESC
  ''',
    [userId],
  );

  return result;
}

// =========================================================
// GET ALL GARAGES
// =========================================================
Future<List<Map<String, dynamic>>> getAllGarages() async {
  final db = await initializeDatabase();
  final result = await db.query('garages', orderBy: 'garage_name ASC');

  // Map garage_id -> id, garage_name -> name for compatibility
  return result
      .map(
        (g) => {
          'id': g['garage_id'],
          'name': g['garage_name'],
          'address': g['address'],
        },
      )
      .toList();
}

// =========================================================
// GET USER BY ID
// =========================================================
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

// =========================================================
// UPDATE USER PROFILE
// =========================================================
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

// =========================================================
// GET USER REVIEWS
// =========================================================
Future<List<Map<String, dynamic>>> getUserReviews(String fullName) async {
  final db = await initializeDatabase();

  final result = await db.rawQuery(
    '''
    SELECT 
      r.*,
      g.garage_name
    FROM reviews r
    LEFT JOIN garages g ON r.garage_id = g.garage_id
    WHERE r.user_name = ?
    ORDER BY r.created_at DESC
  ''',
    [fullName],
  );

  return result;
}

// =========================================================
// GET RECENT EXPENSES BY USER
// =========================================================
Future<List<Map<String, dynamic>>> getRecentRepairsByUser({
  required String userId,
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
    ORDER BY e.expense_date DESC
    LIMIT ?
  ''',
    [userId, limit],
  );
}
