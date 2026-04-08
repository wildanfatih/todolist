import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Future<Database> initDB() async {
    final path = await getDatabasesPath();

    return openDatabase(
      join(path, 'todo.db'),
      version: 1,
      onCreate: (db, version) async {
        // TABEL TASK
        await db.execute(
          'CREATE TABLE tasks(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, done INTEGER)',
        );

        // TABEL USER
        await db.execute(
          'CREATE TABLE users(id INTEGER PRIMARY KEY AUTOINCREMENT, username TEXT, password TEXT)',
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

  static Future<bool> login(String username, String password) async {
    final db = await initDB();

    final result = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );

    return result.isNotEmpty;
  }

  // ================= TASK =================

  static Future<void> insertTask(String title) async {
    final db = await initDB();
    await db.insert('tasks', {'title': title, 'done': 0});
  }

  static Future<List<Map<String, dynamic>>> getTasks() async {
    final db = await initDB();
    return db.query('tasks');
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