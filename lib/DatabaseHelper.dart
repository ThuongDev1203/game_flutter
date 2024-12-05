import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'user_database.db');
    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute(
          '''
          CREATE TABLE users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT UNIQUE,
            level INTEGER DEFAULT 1
          )
          ''',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            "ALTER TABLE users ADD COLUMN level INTEGER DEFAULT 1",
          );
        }
      },
    );
  }

  /// Kiểm tra tài khoản có tồn tại không
  Future<bool> checkAccountExists(String name) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'name = ?',
      whereArgs: [name],
    );
    return result.isNotEmpty;
  }

  /// Tạo tài khoản mới
  Future<int> createAccount(String name) async {
    final db = await database;
    try {
      return await db.insert(
        'users',
        {'name': name, 'level': 0}, // Mặc định
      );
    } catch (e) {
      return -1; // Trả về -1 nếu xảy ra lỗi
    }
  }

  /// Cập nhật level nếu cao hơn
  Future<int> updateLevelIfHigher(int userId, int newLevel) async {
    final db = await database;

    final result = await db.query(
      'users',
      columns: ['level'],
      where: 'id = ?',
      whereArgs: [userId],
    );

    if (result.isNotEmpty) {
      final currentLevel = result.first['level'] as int;

      if (newLevel > currentLevel) {
        return await db.update(
          'users',
          {'level': newLevel},
          where: 'id = ?',
          whereArgs: [userId],
        );
      }
    }
    return 0; // Không cập nhật nếu level mới không cao hơn
  }

  Future<int> updateHighestLevel(int newLevel) async {
    final db = await database;

    // Lấy người chơi hiện tại
    final player = await db.query(
      'users',
      where: 'name = ?',
      whereArgs: ['Player1'], // Tên người chơi hiện tại
    );

    if (player.isNotEmpty) {
      final currentLevel = player.first['level'] as int;

      // Chỉ cập nhật nếu level mới cao hơn
      if (newLevel > currentLevel) {
        final result = await db.update(
          'users',
          {'level': newLevel},
          where: 'name = ?',
          whereArgs: ['Player1'], // Tên người chơi hiện tại
        );

        return result; // Trả về số lượng hàng bị ảnh hưởng
      }
    }

    return 0; // Trả về 0 nếu không có thay đổi
  }

  /// Lấy level hiện tại của người chơi
  Future<int?> getPlayerLevel(int userId) async {
    final db = await database;
    final result = await db.query(
      'users',
      columns: ['level'],
      where: 'id = ?',
      whereArgs: [userId],
    );
    if (result.isNotEmpty) {
      return result.first['level'] as int?;
    }
    return null;
  }

  /// Lấy danh sách người chơi
  Future<List<Map<String, dynamic>>> getPlayers() async {
    final db = await database;
    return await db.query(
      'users',
      orderBy: 'level DESC', // Sắp xếp theo level giảm dần
    );
  }

  /// Xóa tài khoản
  Future<int> deleteAccount(int userId) async {
    final db = await database;
    return await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  /// Lấy thông tin tài khoản theo tên
  Future<Map<String, dynamic>?> getAccountByName(String name) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'name = ?',
      whereArgs: [name],
    );
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }
}
