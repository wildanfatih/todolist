import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Future<Database> initDB() async {
    final path = await getDatabasesPath();

    return openDatabase(
      join(path, 'todo_v2.db'), // Ganti nama db jadi v2 agar tabel ter-refresh
      version: 1,
      onCreate: (db, version) async {
        // TABEL USER
        await db.execute(
          'CREATE TABLE users(id INTEGER PRIMARY KEY AUTOINCREMENT, username TEXT, password TEXT)',
        );

        // TABEL TASK (Sekarang pakai userId sebagai label pemilik)
        await db.execute(
          'CREATE TABLE tasks(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, done INTEGER, userId INTEGER)',
        );
      },
    );
  }

  // ================= USER =================

  static Future<void> register(String username, String password) async {
    final db = await initDB();
    await db.insert('users', {
      'username': username,
      'password': password,
    });
  }

  // UBAH: Sekarang return int? (ID User) bukan bool
  static Future<int?> login(String username, String password) async {
    final db = await initDB();

    final result = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );

    if (result.isNotEmpty) {
      return result.first['id'] as int; // Ambil ID user pertama yang ditemukan
    }
    return null; // Return null kalau gagal login
  }

  // ================= TASK =================

  // UBAH: Tambah parameter userId saat simpan tugas
  static Future<void> insertTask(String title, int userId) async {
    final db = await initDB();
    await db.insert('tasks', {
      'title': title,
      'done': 0,
      'userId': userId // Labeli tugas ini milik siapa
    });
  }

  // UBAH: Hanya ambil tugas yang userId-nya cocok
  static Future<List<Map<String, dynamic>>> getTasks(int userId) async {
    final db = await initDB();
    return db.query(
        'tasks',
        where: 'userId = ?',
        whereArgs: [userId]
    );
  }

  static Future<void> updateTask(int id, int done) async {
    final db = await initDB();
    await db.update(
      'tasks',
      {'done': done},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> deleteTask(int id) async {
    final db = await initDB();
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }
}