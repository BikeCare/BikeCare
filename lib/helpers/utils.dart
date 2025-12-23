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
      await _seedGarages(db);
      await _seedReviews(db);
      await _seedUser(db);
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

  await db.insert(
    'vehicles',
    {
      'vehicle_id': uuid.v4(), // Tạo ID ngẫu nhiên
      'user_id': userId,
      'brand': brand,
      'vehicle_type': vehicleType,
      // Lưu các trường mới (nếu null thì lưu chuỗi rỗng)
      'vehicle_name': name ?? '',
      'license_plate': licensePlate ?? '',
      'warranty_start': warrantyStart ?? '',
      'warranty_end': warrantyEnd ?? '',
    },
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
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
      'id': '4aGTqfCMzswPcxbF8',
      'name': 'Sửa Xe Lưu Động - Cứu Hộ Xe Máy Quận 10',
      'address': '44 Hùng Vương, Phường 1, Quận 10, Thành phố Hồ Chí Minh 700000, Việt Nam',
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
      'lng': 106.67929559931213
    },
    {
      'id': 'imCmKKFkH1Wgk3X16',
      'name': 'Sửa Xe Lưu Động - Cứu Hộ Xe Máy Quận 10 Minh Thành Motor',
      'address': '768c Sư Vạn Hạnh, Phường 12, Quận 10, Thành phố Hồ Chí Minh 700000, Việt Nam', 
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
      'lng': 106.66891008619393
    },
    {
      'id': 'FvvJ1BX9dpFW1c1m7',
      'name': 'Tiệm sửa xe THỨC NGUYỄN TRÃI',
      'address': '162 Hùng Vương, Phường 2, Quận 10, Thành phố Hồ Chí Minh 700000, Việt Nam', 
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
      'lng': 106.674858978084
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
      'lng': 106.66836596068599
    },
    {
      'id': 'wCTLzcF6xLbuPjMa9',
      'name': 'True Moto Care Hoàng Phương - Cửa hàng sửa xe (NanoAuto) - chi nhánh 3/2',
      'address': '1201 3 Tháng 2, Phường 7, Quận 11, Thành phố Hồ Chí Minh, Việt Nam', 
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
      'lng': 106.6527712686252
    },
    {
      'id': 'X8Nn3SNq5V8DUcS39',
      'name': 'Sửa xe Minh Tuấn',
      'address': '402 Vĩnh Viễn, Phường 8, Quận 10, Thành phố Hồ Chí Minh 72550, Việt Nam', 
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
      'lng': 106.66664678901783
    },
    {
      'id': '369bv4JBoCMkd2U6A',
      'name': 'SỬA XE MÁY LƯU ĐỘNG HẬU , CỨU HỘ XE MÁY',
      'address': '320 Đ. 3 Tháng 2, Phường 10, Quận 10, Thành phố Hồ Chí Minh, Việt Nam', 
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
      'lng': 106.67076679891399
    },
  ];

  for (var garage in garages) {
    await db.insert('garages', garage, conflictAlgorithm: ConflictAlgorithm.replace);
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
      'created_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String()
    },
    {
      'id': 'rv2',
      'garage_id': '4aGTqfCMzswPcxbF8',
      'user_name': 'Minh Tuấn',
      'rating': 4,
      'comment': 'Đông khách nên chờ hơi lâu.',
      'created_at': DateTime.now().subtract(const Duration(days: 5)).toIso8601String()
    },
    {
      'id': 'rv3',
      'garage_id': '4aGTqfCMzswPcxbF8', // Khớp ID Shop2banh
      'user_name': 'Hùng Lâm',
      'rating': 5,
      'comment': 'Nhiều đồ chơi xe đẹp, nhân viên nhiệt tình.',
      'created_at': DateTime.now().toString()
    },
    {
      'id': 'rv4',
      'garage_id': 'imCmKKFkH1Wgk3X16', // Khớp ID Honda
      'user_name': 'Minh Tùng',
      'rating': 5,
      'comment': 'Thợ giỏi và nhiệt tình.',
      'created_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String()
    },
    {
      'id': 'rv5',
      'garage_id': 'imCmKKFkH1Wgk3X16',
      'user_name': 'Minh Mẫn',
      'rating': 3.5,
      'comment': 'Giá cả hợp lý, sẽ quay lại lần sau. Mà đợi hơi lâu',
      'created_at': DateTime.now().subtract(const Duration(days: 5)).toIso8601String()
    },
    {
      'id': 'rv6',
      'garage_id': 'imCmKKFkH1Wgk3X16', // Khớp ID Shop2banh
      'user_name': 'Hùng Lâm',
      'rating': 4,
      'comment': 'Dịch vụ tốt, giá cả hợp lý.',
      'created_at': DateTime.now().toString()
    },
  ];
  for (var rv in reviews) {
    await db.insert('reviews', rv, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}

// =========================================================
// LẤY DANH SÁCH GARA GẦN NHẤT & TÍNH RATING THẬT
// =========================================================
Future<List<Map<String, dynamic>>> getNearestGarages(double userLat, double userLng) async {
  final db = await initializeDatabase();
  final List<Map<String, dynamic>> rawGarages = await db.query('garages');
  
  List<Map<String, dynamic>> processedGarages = [];

  for (var garage in rawGarages) {
    String garageId = garage['id'];

    // 1. Tự động tính Rating & Count từ bảng Reviews
    final countResult = await db.rawQuery('SELECT COUNT(*) as count FROM reviews WHERE garage_id = ?', [garageId]);
    int realReviewCount = Sqflite.firstIntValue(countResult) ?? 0;

    final ratingResult = await db.rawQuery('SELECT AVG(rating) as avgRating FROM reviews WHERE garage_id = ?', [garageId]);
    double realRating = 0.0;
    if (ratingResult.first['avgRating'] != null) {
      realRating = double.parse(ratingResult.first['avgRating'].toString());
    }

    // 2. Tính khoảng cách
    double garaLat = garage['lat'] ?? 0.0;
    double garaLng = garage['lng'] ?? 0.0;
    double distanceInMeters = Geolocator.distanceBetween(userLat, userLng, garaLat, garaLng);

    processedGarages.add({
      ...garage,
      'rating': double.parse(realRating.toStringAsFixed(1)), // Rating thật
      'review_count': realReviewCount, // Số lượng review thật
      'distance': double.parse((distanceInMeters / 1000).toStringAsFixed(1)),
      'raw_distance': distanceInMeters,
    });
  }

  // Sắp xếp theo khoảng cách
  processedGarages.sort((a, b) => (a['raw_distance'] as double).compareTo(b['raw_distance'] as double));
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
    await db.insert('favorites', {
      'user_id': userId,
      'garage_id': garageId,
    });
  }
}

// Lấy danh sách gara yêu thích
Future<List<Map<String, dynamic>>> getFavoriteGarages(String userId) async {
  final db = await initializeDatabase();
  // Join bảng favorites với bảng garages để lấy thông tin chi tiết
  return await db.rawQuery('''
    SELECT g.* FROM garages g
    INNER JOIN favorites f ON g.id = f.garage_id
    WHERE f.user_id = ?
  ''', [userId]);
}

// ================= REVIEWS HELPER =================
Future<void> addReview(String garageId, String userName, int rating, String comment) async {
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
  return await db.query('reviews', where: 'garage_id = ?', whereArgs: [garageId], orderBy: "created_at DESC");
}

// =========================================================
// SEED USER DEMO (TẠO TÀI KHOẢN MẶC ĐỊNH)
// =========================================================
Future<void> _seedUser(Database db) async {
  await db.insert(
    'users',
    {
      'user_id': 'user_001', 
      'username': 'Minh Anh',
      'password': '123',    
      'email': 'demo@gmail.com',
      'full_name': 'Người dùng Demo',
      'phone': '0909123456',
      'gender': 'Nam',
      'date_of_birth': '2000-01-01',
      'location': 'TP. Hồ Chí Minh'
    },
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
  
  // Kèm 1 chiếc xe cho user demo 
  await db.insert('vehicles', {
    'vehicle_id': 'xe_demo_01',
    'user_id': 'user_001',
    'vehicle_name': 'Honda AirBlade 2020',
    'brand': 'Honda AirBlade',
    'vehicle_type': '>175cc',
    'license_plate': '59-X1 123.45',
    'warranty_start': DateTime.now().subtract(const Duration(days: 365)).toIso8601String(),
    'warranty_end': DateTime.now().add(const Duration(days: 365)).toIso8601String(),
  });
}