import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class DBHelper {
  static Future<Database> initDB() async {
    final path = await getDatabasesPath();

    return openDatabase(
      // 1. Nama database dinaikkan ke v6 agar tabelnya otomatis diperbarui di HP/Emulator
      join(path, 'todo_v6.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE users(id INTEGER PRIMARY KEY AUTOINCREMENT, username TEXT, password TEXT)',
        );
        // 2. Di sini kita tambahkan kolom due_date dan due_time
        await db.execute(
          'CREATE TABLE tasks(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, done INTEGER, userId INTEGER, created_at TEXT, category TEXT, due_date TEXT, due_time TEXT)',
        );
      },
    );
  }

  // ================= KEAMANAN LEVEL PRO =================

  static String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  static Future<void> register(String username, String password) async {
    final db = await initDB();
    await db.insert('users', {
      'username': username,
      'password': _hashPassword(password)
    });
  }

  static Future<int?> login(String username, String password) async {
    final db = await initDB();
    final result = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, _hashPassword(password)],
    );
    if (result.isNotEmpty) return result.first['id'] as int;
    return null;
  }

  // ================= MANAJEMEN TUGAS =================

  // 3. Fungsi insertTask sekarang menerima parameter dueDate dan dueTime tambahan
  static Future<void> insertTask(String title, int userId, String category, String dueDate, String dueTime) async {
    final db = await initDB();
    String currentTime = DateTime.now().toString();

    await db.insert('tasks', {
      'title': title,
      'done': 0,
      'userId': userId,
      'created_at': currentTime,
      'category': category,
      'due_date': dueDate,   // Menyimpan tanggal target (YYYY-MM-DD)
      'due_time': dueTime    // Menyimpan jam alarm (HH:MM)
    });
  }

  static Future<List<Map<String, dynamic>>> getTasks(int userId) async {
    final db = await initDB();
    return db.query('tasks', where: 'userId = ?', whereArgs: [userId]);
  }

  static Future<void> updateTask(int id, int done) async {
    final db = await initDB();
    await db.update('tasks', {'done': done}, where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> deleteTask(int id) async {
    final db = await initDB();
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }
}