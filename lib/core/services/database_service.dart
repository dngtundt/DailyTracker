import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user_model.dart';
import '../models/activity_model.dart';
import '../models/challenge_model.dart';
import '../models/post_model.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  DatabaseService._internal();

  Database? _db;
  
  Future<void> init() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'dailytracker_v5.db');
    
    // Copy pre-populated database from assets if it doesn't exist
    final exists = await databaseExists(path);
    if (!exists) {
      try {
        await Directory(dirname(path)).create(recursive: true);
        ByteData data = await rootBundle.load('assets/db/dailytracker_v5.db');
        List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await File(path).writeAsBytes(bytes, flush: true);
      } catch (e) {
        debugPrint('Error copying database from assets: $e');
      }
    }

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
    );
    await _seedDefaultData();
  }

  Database get db => _db!;

  Future<void> _createTables(Database db, int version) async {
    // ── Users (extended with profile fields) ─────────────────
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'user',
        points INTEGER NOT NULL DEFAULT 0,
        rank TEXT NOT NULL DEFAULT 'iron',
        avatarUrl TEXT,
        createdAt TEXT NOT NULL,
        gender TEXT,
        age INTEGER,
        heightCm REAL,
        weightKg REAL,
        country TEXT,
        occupation TEXT
      )
    ''');

    // ── Activities ────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE activities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        date TEXT NOT NULL,
        startTime TEXT NOT NULL,
        endTime TEXT,
        category TEXT NOT NULL,
        color TEXT,
        hasReminder INTEGER NOT NULL DEFAULT 0,
        reminderTime TEXT,
        isDone INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (userId) REFERENCES users(id)
      )
    ''');

    // ── Challenges ────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE challenges (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        points INTEGER NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        isCompleted INTEGER NOT NULL DEFAULT 0,
        userId INTEGER,
        FOREIGN KEY (userId) REFERENCES users(id)
      )
    ''');

    // ── Posts ─────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE posts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        adminId INTEGER NOT NULL,
        adminName TEXT NOT NULL,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        imageUrl TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (adminId) REFERENCES users(id)
      )
    ''');

    // ── User–Challenge join ───────────────────────────────────
    await db.execute('''
      CREATE TABLE user_challenges (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        challengeId INTEGER NOT NULL,
        isCompleted INTEGER NOT NULL DEFAULT 0,
        completedAt TEXT,
        UNIQUE(userId, challengeId),
        FOREIGN KEY (userId) REFERENCES users(id),
        FOREIGN KEY (challengeId) REFERENCES challenges(id)
      )
    ''');
  }

  // ──────────────────────────────────────────────────────────────
  // Seed
  // ──────────────────────────────────────────────────────────────
  Future<void> _seedDefaultData() async {
    final existing = await _db!.query('users',
        where: 'role = ?', whereArgs: ['admin'], limit: 1);
    if (existing.isNotEmpty) return;

    final now = DateTime.now();
    final todayStr = _dateStr(now);

    // Admin
    await _db!.insert('users', {
      'username': 'Admin',
      'email': 'admin@dailytracker.com',
      'password': 'admin123',
      'role': 'admin',
      'points': 99999,
      'rank': 'master',
      'gender': 'Nam',
      'country': 'Việt Nam',
      'occupation': 'Quản trị viên',
      'createdAt': now.toIso8601String(),
    });

    // Sample users with full profile
    final users = [
      {
        'username': 'Dang Anh Tuan',  'email': 'danganhtuan@gmail.com',
        'password': 'user123', 'points': 3800, 'rank': 'gold',
        'gender': 'Nam', 'age': 24, 'heightCm': 172.0, 'weightKg': 68.0,
        'country': 'Việt Nam', 'occupation': 'Lập trình viên',
      },
      {
        'username': 'Minh Thu',       'email': 'minhthu@gmail.com',
        'password': 'user123', 'points': 9200, 'rank': 'diamond',
        'gender': 'Nữ', 'age': 22, 'heightCm': 158.0, 'weightKg': 52.0,
        'country': 'Việt Nam', 'occupation': 'Sinh viên',
      },
      {
        'username': 'Minh Thuan',     'email': 'minhthuan@gmail.com',
        'password': 'user123', 'points': 1600, 'rank': 'gold',
        'gender': 'Nam', 'age': 26, 'heightCm': 175.0, 'weightKg': 72.0,
        'country': 'Việt Nam', 'occupation': 'Kỹ sư phần mềm',
      },
      {
        'username': 'Dinh Trung',     'email': 'dinhtrung@gmail.com',
        'password': 'user123', 'points': 650,  'rank': 'bronze',
        'gender': 'Nam', 'age': 20, 'heightCm': 168.0, 'weightKg': 65.0,
        'country': 'Việt Nam', 'occupation': 'Sinh viên',
      },
    ];

    for (final u in users) {
      await _db!.insert('users', {'role': 'user', 'createdAt': now.toIso8601String(), ...u});
    }

    // Today's challenges
    final challenges = [
      {'title': '🏃 Chạy bộ 30 phút',  'description': 'Hoàn thành 30 phút chạy bộ',  'points': 50, 'category': 'fitness'},
      {'title': '💧 Uống đủ 2L nước',  'description': 'Uống ít nhất 8 ly nước/ngày', 'points': 30, 'category': 'nutrition'},
      {'title': '🧘 Thiền 10 phút',    'description': '10 phút thiền định buổi sáng', 'points': 40, 'category': 'mindset'},
      {'title': '📚 Đọc sách 20 phút', 'description': 'Đọc sách 20 phút bất kỳ',     'points': 35, 'category': 'productivity'},
      {'title': '🥗 Ăn rau xanh',      'description': 'Bữa ăn có phần rau xanh',      'points': 25, 'category': 'nutrition'},
    ];
    for (final c in challenges) {
      await _db!.insert('challenges', {...c, 'date': todayStr, 'isCompleted': 0});
    }

    // Sample activities for each user (userId 2–5)
    final sampleActs = [
      // Dang Anh Tuan (id=2)
      {'userId': 2, 'title': '☀️ Kéo giãn cơ', 'description': 'Khởi động nhẹ', 'startTime': '06:00', 'endTime': '06:15', 'category': 'sport', 'isDone': 1},
      {'userId': 2, 'title': '🥚 Ăn sáng',     'description': 'Trứng luộc, bánh mì', 'startTime': '07:00', 'endTime': '07:30', 'category': 'food', 'isDone': 1},
      {'userId': 2, 'title': '💻 Code Flutter', 'description': 'Làm tính năng thông báo', 'startTime': '08:00', 'endTime': '11:00', 'category': 'work', 'isDone': 0},
      {'userId': 2, 'title': '🍜 Ăn trưa',     'description': 'Cơm gà rau xanh', 'startTime': '12:00', 'endTime': '13:00', 'category': 'food', 'isDone': 0},
      {'userId': 2, 'title': '🏋️ Tập gym',     'description': 'Ngực + vai 5 bài', 'startTime': '17:00', 'endTime': '18:30', 'category': 'sport', 'isDone': 0},
      {'userId': 2, 'title': '📖 Đọc sách',     'description': 'Atomic Habits ch.5', 'startTime': '21:00', 'endTime': '21:30', 'category': 'rest', 'isDone': 0},
      // Minh Thu (id=3)
      {'userId': 3, 'title': '🧘 Yoga sáng', 'description': 'Flow yoga 30 phút', 'startTime': '06:30', 'endTime': '07:00', 'category': 'sport', 'isDone': 1},
      {'userId': 3, 'title': '🥤 Uống nước + vitamin', 'description': 'Ly nước ấm sau ngủ', 'startTime': '07:00', 'endTime': '07:10', 'category': 'food', 'isDone': 1},
      {'userId': 3, 'title': '📊 Họp nhóm', 'description': 'Họp tiến độ Q2', 'startTime': '09:00', 'endTime': '10:30', 'category': 'work', 'isDone': 0},
      {'userId': 3, 'title': '🥗 Salad trưa', 'description': 'Salad + ức gà', 'startTime': '12:00', 'endTime': '12:45', 'category': 'food', 'isDone': 0},
      {'userId': 3, 'title': '🏃 Chạy bộ', 'description': 'Chạy 5km công viên', 'startTime': '17:30', 'endTime': '18:15', 'category': 'sport', 'isDone': 0},
      // Minh Thuan (id=4)
      {'userId': 4, 'title': '☕ Cà phê sáng', 'description': 'Cà phê sữa ít đường', 'startTime': '07:30', 'endTime': '08:00', 'category': 'food', 'isDone': 1},
      {'userId': 4, 'title': '📝 Review code', 'description': 'Review PR + fix bug', 'startTime': '09:00', 'endTime': '11:30', 'category': 'work', 'isDone': 0},
      {'userId': 4, 'title': '🏊 Bơi lội', 'description': 'Bơi 1km hồ bơi', 'startTime': '12:30', 'endTime': '13:30', 'category': 'sport', 'isDone': 0},
      // Dinh Trung (id=5)
      {'userId': 5, 'title': '🌅 Thiền sáng', 'description': 'Thiền 15 phút', 'startTime': '06:45', 'endTime': '07:00', 'category': 'rest', 'isDone': 0},
      {'userId': 5, 'title': '📱 Dự án mobile', 'description': 'Tính năng map tracking', 'startTime': '08:30', 'endTime': '12:00', 'category': 'work', 'isDone': 0},
      {'userId': 5, 'title': '⚽ Đá bóng', 'description': 'Giao hữu buổi chiều', 'startTime': '16:00', 'endTime': '17:30', 'category': 'sport', 'isDone': 0},
    ];

    for (final act in sampleActs) {
      await _db!.insert('activities', {
        'date': todayStr,
        'hasReminder': 0,
        'createdAt': now.toIso8601String(),
        ...act,
      });
    }

    // Welcome posts
    await _db!.insert('posts', {
      'adminId': 1, 'adminName': 'Admin',
      'title': '🎉 Chào mừng đến với DailyTracker!',
      'content': 'DailyTracker giúp bạn xây dựng thói quen tốt mỗi ngày. Theo dõi lịch trình, hoàn thành thử thách và leo lên bảng xếp hạng! 💪',
      'createdAt': now.toIso8601String(),
    });
    await _db!.insert('posts', {
      'adminId': 1, 'adminName': 'Admin',
      'title': '🔥 Tips tăng năng suất làm việc',
      'content': '3 tips vàng: 1️⃣ Kỹ thuật Pomodoro (25p làm – 5p nghỉ). 2️⃣ Lên 3 việc quan trọng nhất mỗi sáng. 3️⃣ Tắt thông báo mạng xã hội khi làm việc.',
      'createdAt': now.subtract(const Duration(hours: 2)).toIso8601String(),
    });
  }

  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ─── Users ───────────────────────────────────────────────────────
  Future<int> insertUser(UserModel user) => db.insert('users', user.toMap());

  Future<UserModel?> getUserByEmail(String email) async {
    final rows = await db.query('users', where: 'email = ?', whereArgs: [email], limit: 1);
    return rows.isEmpty ? null : UserModel.fromMap(rows.first);
  }

  Future<UserModel?> getUserById(int id) async {
    final rows = await db.query('users', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : UserModel.fromMap(rows.first);
  }

  Future<List<UserModel>> getAllUsers() async {
    final rows = await db.query('users', orderBy: 'points DESC');
    return rows.map(UserModel.fromMap).toList();
  }

  Future<void> updateUser(UserModel user) async {
    await db.update('users', user.toMap(), where: 'id = ?', whereArgs: [user.id]);
  }

  // ─── Activities ──────────────────────────────────────────────────
  Future<int> insertActivity(ActivityModel a) => db.insert('activities', a.toMap());

  Future<List<ActivityModel>> getActivitiesForDate(int userId, DateTime date) async {
    final dateStr = _dateStr(date);
    final rows = await db.query(
      'activities',
      where: 'userId = ? AND date LIKE ?',
      whereArgs: [userId, '$dateStr%'],
      orderBy: 'startTime ASC',
    );
    return rows.map(ActivityModel.fromMap).toList();
  }

  /// Returns activities for the last [days] days for the given user
  Future<List<ActivityModel>> getRecentActivities(int userId, {int days = 7}) async {
    final rows = await db.rawQuery('''
      SELECT * FROM activities
      WHERE userId = ?
        AND date >= date('now', '-$days days')
      ORDER BY date DESC, startTime ASC
    ''', [userId]);
    return rows.map(ActivityModel.fromMap).toList();
  }

  Future<void> updateActivityDone(int id, bool isDone) async {
    await db.update('activities', {'isDone': isDone ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteActivity(int id) async {
    await db.delete('activities', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Challenges ──────────────────────────────────────────────────
  Future<List<ChallengeModel>> getChallengesForDate(String date, int userId) async {
    final rows = await db.rawQuery('''
      SELECT c.*,
        COALESCE(uc.isCompleted, 0) as isCompleted
      FROM challenges c
      LEFT JOIN user_challenges uc ON c.id = uc.challengeId AND uc.userId = ?
      WHERE c.date = ?
      ORDER BY c.id ASC
    ''', [userId, date]);
    return rows.map(ChallengeModel.fromMap).toList();
  }

  Future<void> completeChallenge(int userId, int challengeId) async {
    await db.insert(
      'user_challenges',
      {
        'userId': userId,
        'challengeId': challengeId,
        'isCompleted': 1,
        'completedAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ─── Posts ───────────────────────────────────────────────────────
  Future<int> insertPost(PostModel post) => db.insert('posts', post.toMap());

  Future<List<PostModel>> getAllPosts() async {
    final rows = await db.query('posts', orderBy: 'createdAt DESC');
    return rows.map(PostModel.fromMap).toList();
  }

  Future<void> deletePost(int id) async {
    await db.delete('posts', where: 'id = ?', whereArgs: [id]);
  }
}
