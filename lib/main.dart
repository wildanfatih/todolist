import 'session_helper.dart';
import 'package:flutter/material.dart';
import 'database/db_helper.dart';
import 'login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DBHelper.initDB();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Variabel untuk nentuin halaman pertama
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
        // Kalau sudah pernah login, langsung tembak ke TodoScreen bawa ID-nya
        initialScreen = TodoScreen(userId: loggedInUserId);
      } else {
        // Kalau belum, suruh login dulu
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
      home: initialScreen, // ⬅️ Halaman awalnya dinamis sekarang
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

  String selectedCategory = 'Umum';
  final List<String> categories = ['Umum', 'Pekerjaan', 'Pribadi', 'Belanja'];

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
            // 🔥 DROPDOWN PILIH KATEGORI (Gunakan StatefulBuilder agar Pop-up bisa refresh)
            StatefulBuilder(
                builder: (BuildContext context, StateSetter setModalState) {
                  return DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: categories.map((String category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setModalState(() {
                        selectedCategory = newValue!;
                      });
                    },
                  );
                }
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
    // 🔥 Kirim selectedCategory ke fungsi insert
    await DBHelper.insertTask(controller.text, widget.userId, selectedCategory);
    controller.clear();
    setState(() {
      selectedCategory = 'Umum'; // Reset dropdown ke Umum setelah tambah tugas
    });
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
            onPressed: () async {
              // 1. Hapus sesi
              await SessionHelper.clearSession();

              // 2. Gunakan context.mounted
              if (!context.mounted) return;

              // 3. Kembali ke layar login
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
            const SizedBox(height: 10),
            const Text("Belum ada tugas. List masih kosong!", style: TextStyle(color: Colors.grey)),
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

            // 🔥 FITUR POP-UP KONFIRMASI HAPUS
            confirmDismiss: (direction) async {
              return await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    title: const Text("Konfirmasi Hapus"),
                    content: const Text("Apakah kamu yakin ingin menghapus tugas ini?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false), // Batal
                        child: const Text("Batal", style: TextStyle(color: Colors.grey)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                        onPressed: () => Navigator.of(context).pop(true), // Hapus
                        child: const Text("Hapus", style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  );
                },
              );
            },

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

            // ISI KARTU TUGAS YANG SEMPAT TERHAPUS
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

                // JUDUL TUGAS
                title: Text(
                  task['title'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                    color: isDone ? Colors.grey : Colors.black87,
                  ),
                ),

                // 🔥 INI TAMBAHANNYA: MENAMPILKAN WAKTU
                subtitle: Text(
                  task['created_at'] != null
                      ? task['created_at'].toString().substring(0, 16)
                      : "Waktu tidak diketahui",
                  style: TextStyle(
                    fontSize: 12,
                    color: isDone ? Colors.grey[400] : Colors.grey[600],
                  ),
                ), // <-- KURUNG TUTUP SUBTITLE HARUS DI SINI

                // 🔥 MENAMPILKAN LABEL KATEGORI (Sejajar dengan subtitle)
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: task['category'] == 'Pekerjaan' ? Colors.blue[100] :
                    task['category'] == 'Pribadi' ? Colors.purple[100] :
                    task['category'] == 'Belanja' ? Colors.green[100] :
                    Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    task['category'] ?? 'Umum',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: task['category'] == 'Pekerjaan' ? Colors.blue[800] :
                      task['category'] == 'Pribadi' ? Colors.purple[800] :
                      task['category'] == 'Belanja' ? Colors.green[800] :
                      Colors.grey[800],
                    ),
                  ),
                ),

              ), // <-- KURUNG TUTUP LISTTILE
            ), // <-- KURUNG TUTUP CARD
          );
        },
      ),
    );
  }
}