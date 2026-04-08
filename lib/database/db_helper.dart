import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert'; // 🔥 Tambahan untuk konversi teks
import 'package:crypto/crypto.dart'; // 🔥 Tambahan untuk SHA-256

class DBHelper {
  static Future<Database> initDB() async {
    final path = await getDatabasesPath();

    return openDatabase(
      join(path, 'todo_v5.db'), // 🔥 GANTI KE v5 (Database Final!)
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE users(id INTEGER PRIMARY KEY AUTOINCREMENT, username TEXT, password TEXT)',
        );
        await db.execute(
          'CREATE TABLE tasks(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, done INTEGER, userId INTEGER, created_at TEXT, category TEXT)',
        );
      },
    );
  }

  // ================= KEAMANAN LEVEL PRO =================

  // 🔥 FUNGSI RAHASIA UNTUK MENGACAK PASSWORD
  static String _hashPassword(String password) {
    var bytes = utf8.encode(password); // Ubah teks jadi byte
    var digest = sha256.convert(bytes); // Acak pakai SHA-256
    return digest.toString(); // Kembalikan jadi teks acak
  }

  static Future<void> register(String username, String password) async {
    final db = await initDB();
    await db.insert('users', {
      'username': username,
      'password': _hashPassword(password) // 🔥 Simpan password yang SUDAH DIACAK
    });
  }

  static Future<int?> login(String username, String password) async {
    final db = await initDB();
    final result = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      // 🔥 Cek database menggunakan password inputan yang diacak juga
      whereArgs: [username, _hashPassword(password)],
    );
    if (result.isNotEmpty) return result.first['id'] as int;
    return null;
  }

  // ================= MANAJEMEN TUGAS =================

  static Future<void> insertTask(String title, int userId, String category) async {
    final db = await initDB();
    String currentTime = DateTime.now().toString();

    await db.insert('tasks', {
      'title': title,
      'done': 0,
      'userId': userId,
      'created_at': currentTime,
      'category': category
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