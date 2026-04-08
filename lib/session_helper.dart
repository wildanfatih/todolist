import 'package:shared_preferences/shared_preferences.dart';

class SessionHelper {
  static const String _keyUserId = 'user_id';
  static const String _keyIsLoggedIn = 'is_logged_in';

  // 1. Simpan Sesi (Dipanggil saat Login berhasil)
  static Future<void> saveSession(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setInt(_keyUserId, userId);
  }

  // 2. Ambil Sesi (Dipanggil saat aplikasi baru dibuka)
  // Menghasilkan ID User kalau sudah login, atau null kalau belum
  static Future<int?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;

    if (isLoggedIn) {
      return prefs.getInt(_keyUserId);
    }
    return null;
  }

  // 3. Hapus Sesi (Dipanggil saat Logout)
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyUserId);
  }
}