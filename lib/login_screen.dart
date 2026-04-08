import 'session_helper.dart';
import 'package:flutter/material.dart';
import 'database/db_helper.dart';
import 'main.dart'; // Pastikan TodoScreen ada di main.dart

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final username = TextEditingController();
  final password = TextEditingController();
  bool isObscure = true;

  void login() async {
    if (username.text.isEmpty || password.text.isEmpty) {
      showSnackBar("Isi username & password dulu ya!");
      return;
    }

    // Await pertama
    int? userId = await DBHelper.login(username.text, password.text);

    if (userId != null) {
      // Await kedua
      await SessionHelper.saveSession(userId);

      // Cek context sebelum pindah layar
      if (!context.mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TodoScreen(userId: userId),
        ),
      );
    } else {
      // 🔥 Nah, di sini juga butuh perlindungan, karena showSnackBar pakai context!
      if (!context.mounted) return;
      showSnackBar("Username atau Password salah!");
    }
  }

  void register() async {
    if (username.text.isEmpty || password.text.isEmpty) {
      showSnackBar("Lengkapi data untuk mendaftar");
      return;
    }

    // Await database
    await DBHelper.register(username.text, password.text);

    // 🔥 Di sini juga wajib dicek sebelum nampilin SnackBar
    if (!context.mounted) return;

    showSnackBar("Berhasil terdaftar! Silakan login.");

    username.clear();
    password.clear();
  }

  // Fungsi bantuan untuk memunculkan pesan pop-up di bawah
  void showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Warna background soft
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- HEADER GRADIENT ---
            Container(
              height: 300,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.indigo, Colors.blueAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(80),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.task_alt, size: 80, color: Colors.white),
                  const SizedBox(height: 10),
                  const Text(
                    "To-Do Pro",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Manage your tasks elegantly",
                    style: TextStyle(color: Colors.white.withAlpha(204)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // --- FORM LOGIN ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  // Field Username
                  TextField(
                    controller: username,
                    decoration: InputDecoration(
                      labelText: "Username",
                      prefixIcon: const Icon(Icons.person_outline),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Field Password
                  TextField(
                    controller: password,
                    obscureText: isObscure,
                    decoration: InputDecoration(
                      labelText: "Password",
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(isObscure ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => isObscure = !isObscure),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Tombol Login
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 5,
                      ),
                      child: const Text(
                        "Login",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Tombol Register
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Belum punya akun?"),
                      TextButton(
                        onPressed: register,
                        child: const Text(
                          "Daftar Sekarang",
                          style: TextStyle(
                            color: Colors.indigo,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}