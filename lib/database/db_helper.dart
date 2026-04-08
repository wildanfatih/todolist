import 'package:flutter/material.dart';
import 'database/db_helper.dart';
import 'main.dart'; // Pastikan TodoScreen ada di sini

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
      showSnackBar("Isi username & password!");
      return;
    }

    // 🔥 PERUBAHAN DISINI: Sekarang menangkap int? userId
    int? userId = await DBHelper.login(username.text, password.text);

    if (userId != null) {
      if (!mounted) return;

      // 🔥 KIRIM userId ke TodoScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TodoScreen(userId: userId),
        ),
      );
    } else {
      showSnackBar("Username atau Password salah!");
    }
  }

  void register() async {
    if (username.text.isEmpty || password.text.isEmpty) {
      showSnackBar("Lengkapi data daftar");
      return;
    }
    await DBHelper.register(username.text, password.text);
    showSnackBar("Berhasil daftar! Silakan login.");
    username.clear();
    password.clear();
  }

  void showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- HEADER ---
            Container(
              height: 250,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Colors.indigo, Colors.blueAccent]),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(80)),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_person, size: 70, color: Colors.white),
                  SizedBox(height: 10),
                  Text("Welcome Back", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 40),
            // --- FORM ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  TextField(
                    controller: username,
                    decoration: InputDecoration(
                      labelText: "Username",
                      prefixIcon: const Icon(Icons.person),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: password,
                    obscureText: isObscure,
                    decoration: InputDecoration(
                      labelText: "Password",
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(isObscure ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => isObscure = !isObscure),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: const Text("LOGIN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  TextButton(onPressed: register, child: const Text("Belum punya akun? Daftar")),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}