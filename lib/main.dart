import 'package:flutter/material.dart';
import 'database/db_helper.dart';
import 'login_screen.dart';

void main() async {
  // Pastikan plugin internal Flutter siap sebelum database jalan
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi database SQLite
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
        colorSchemeSeed: Colors.indigo, // Tema warna dasar
      ),
      // Jalankan LoginScreen dulu sesuai kodemu sebelumnya
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// --- Tampilan TodoScreen yang sudah di-upgrade ---
class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

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

  void loadTasks() async {
    final data = await DBHelper.getTasks();
    setState(() {
      tasks = data;
    });
  }

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
                  Navigator.pop(context);
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

  void addTask() async {
    if (controller.text.isEmpty) return;
    await DBHelper.insertTask(controller.text);
    controller.clear();
    loadTasks();
  }

  void toggleTask(int id, int done) async {
    await DBHelper.updateTask(id, done == 0 ? 1 : 0);
    loadTasks();
  }

  void deleteTask(int id) async {
    await DBHelper.deleteTask(id);
    loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("My Daily Tasks",
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
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
            const SizedBox(height: 10),
            Text("Belum ada tugas. Santai dulu!",
                style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: tasks.length,
        itemBuilder: (context, i) {
          final task = tasks[i];
          final bool isDone = task['done'] == 1;

          return Dismissible(
            key: Key(task['id'].toString()),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (_) => deleteTask(task['id']),
            child: Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                leading: IconButton(
                  icon: Icon(
                    isDone ? Icons.check_circle : Icons.circle_outlined,
                    color: isDone ? Colors.green : Colors.grey,
                    size: 28,
                  ),
                  onPressed: () => toggleTask(task['id'], task['done']),
                ),
                title: Text(
                  task['title'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                    color: isDone ? Colors.grey : Colors.black87,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              ),
            ),
          );
        },
      ),
    );
  }
}