import 'package:flutter/material.dart';
import 'session_helper.dart';
import 'database/db_helper.dart';
import 'login_screen.dart';
import 'notification_helper.dart';
import 'todo_screen.dart'; // ⬅️ Ini yang akan memanggil kalendermu!

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Menyalakan mesin Database & Notifikasi
  await DBHelper.initDB();
  await NotificationHelper.init();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Widget initialScreen = const Scaffold(body: Center(child: CircularProgressIndicator()));

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
  }

  void checkLoginStatus() async {
    int? loggedInUserId = await SessionHelper.getSession();

    setState(() {
      if (loggedInUserId != null) {
        initialScreen = TodoScreen(userId: loggedInUserId);
      } else {
        initialScreen = const LoginScreen();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To-Do Pro',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
      ),
      home: initialScreen,
      debugShowCheckedModeBanner: false,
    );
  }
}