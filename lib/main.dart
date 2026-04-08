import 'package:flutter/material.dart';
import 'database/db_helper.dart';
import 'login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DBHelper.initDB();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To-Do Pro',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
      ),
      // Aplikasi pertama kali buka akan masuk ke LoginScreen
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// --- Tampilan TodoScreen yang sudah pakai ID User ---
class TodoScreen extends StatefulWidget {
  final int userId; // Menerima ID dari LoginScreen

  const TodoScreen({super.key, required this.userId});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  List<Map<String, dynamic>> tasks = [];
  final controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  // 1. Ambil tugas HANYA MILIK user yang sedang login
  void loadTasks() async {
    final data = await DBHelper.getTasks(widget.userId);
    setState(() {
      tasks = data;
    });
  }

  // Desain pop-up dari bawah untuk tambah tugas
  void showAddTaskSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 20, left: 20, right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Tambah Tugas Baru",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: "Apa rencana kamu hari ini?",
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: () {
                  addTask();
                  Navigator.pop(context); // Tutup pop-up setelah simpan
                },
                child: const Text("Simpan Tugas", style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // 2. Simpan tugas DENGAN MENYERTAKAN label pemilknya (userId)
  void addTask() async {
    if (controller.text.isEmpty) return;
    await DBHelper.insertTask(controller.text, widget.userId);
    controller.clear();
    loadTasks();
  }

  // 3. Update status selesai/belum
  void toggleTask(int id, int done) async {
    await DBHelper.updateTask(id, done == 0 ? 1 : 0);
    loadTasks();
  }

  // 4. Hapus tugas
  void deleteTask(int id) async {
    await DBHelper.deleteTask(id);
    loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: const Text("My Daily Tasks", style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          actions: [
            // TOMBOL LOGOUT KITA TARUH DI SINI
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              tooltip: 'Logout',
              onPressed: () {
                // Hapus semua rute sebelumnya dan kembali ke Login
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                );
              },
            )
          ],
        ),

        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.indigo,
          onPressed: showAddTaskSheet,
          child: const Icon(Icons.add, size: 30, color: Colors.white),
        ),

        body: tasks.isEmpty
            ? Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              Icon(Icons.assignment_turned_in_outlined, size: 80, color: Colors.grey[300]),