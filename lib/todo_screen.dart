import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'database/db_helper.dart';
// Import helper notifikasi yang tadi kita buat
import 'notification_helper.dart';
import 'session_helper.dart';
import 'login_screen.dart';

class TodoScreen extends StatefulWidget {
  final int userId;

  const TodoScreen({super.key, required this.userId});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  List<Map<String, dynamic>> tasks = [];
  final controller = TextEditingController();

  // === 1. VARIABEL UNTUK KALENDER & WAKTU ===
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  // === 2. VARIABEL KATEGORI ===
  String _selectedCategory = 'Umum';
  final List<String> _categories = ['Umum', 'Pekerjaan', 'Pribadi', 'Belanja'];

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  // === 3. LOGIKA LOAD DATA: FILTER BERDASARKAN TANGGAL ===
  void loadTasks() async {
    final data = await DBHelper.getTasks(widget.userId);
    // Format tanggal yang dipilih (misal: 2026-05-27)
    String selectedDateStr = DateFormat('yyyy-MM-dd').format(_selectedDay!);

    setState(() {
      // Cuma tampilkan tugas yang tanggalnya sama dengan tanggal di kalender
      tasks = data.where((task) => task['due_date'] == selectedDateStr).toList();
    });
  }

  // === 4. LOGIKA TAMBAH TUGAS + SETTING ALARM ===
  void addTask() async {
    if (controller.text.isEmpty) return;

    String dueDate = DateFormat('yyyy-MM-dd').format(_selectedDay!);
    String dueTime = '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

    // Simpan data ke SQLite
    await DBHelper.insertTask(controller.text, widget.userId, _selectedCategory, dueDate, dueTime);

    // Gabungkan tanggal dan jam untuk jadwal alarm
    DateTime scheduledDateTime = DateTime(
      _selectedDay!.year,
      _selectedDay!.month,
      _selectedDay!.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    // Buat ID unik agar alarm satu tidak menimpa alarm lainnya
    int notifId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

    // Jadwalkan Notifikasi muncul di HP
    await NotificationHelper.scheduleNotification(
      id: notifId,
      title: "Waktunya Tugas: ${controller.text}",
      body: "Kategori: $_selectedCategory. Jangan lupa dikerjakan!",
      scheduledTime: scheduledDateTime,
    );

    controller.clear();

    // Tutup pop-up tambah tugas
    if (!mounted) return;
    Navigator.pop(context);

    // Refresh daftar tugas
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

// ==== KELANJUTAN DARI PART 1 ====

  // === 5. LOGIKA LOGOUT ===
  void logout() async {
    await SessionHelper.clearSession();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  // === 6. UI POP-UP TAMBAH TUGAS (BOTTOM SHEET) ===
  void showAddTaskSheet() {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          // Gunakan StatefulBuilder agar Pop-up bisa update state sendiri (misal saat ganti jam/kategori)
          return StatefulBuilder(
              builder: (context, setModalState) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                    left: 20, right: 20, top: 20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("Tambah Tugas Baru", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 15),

                      // Input Nama Tugas
                      TextField(
                        controller: controller,
                        decoration: const InputDecoration(labelText: "Nama Tugas", border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 10),

                      // Input Pilihan Kategori
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCategory,
                        items: _categories.map((cat) {
                          return DropdownMenuItem(value: cat, child: Text(cat));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => _selectedCategory = val);
                        },
                        decoration: const InputDecoration(labelText: "Kategori", border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 10),

                      // Input Pilihan Jam
                      Row(
                        children: [
                          const Icon(Icons.access_alarm, color: Colors.indigo),
                          const SizedBox(width: 10),
                          Text("Jam Alarm: ${_selectedTime.format(context)}", style: const TextStyle(fontSize: 16)),
                          const Spacer(),
                          TextButton(
                            onPressed: () async {
                              final pickedTime = await showTimePicker(
                                context: context,
                                initialTime: _selectedTime,
                              );
                              if (pickedTime != null) {
                                setModalState(() => _selectedTime = pickedTime);
                              }
                            },
                            child: const Text("Pilih Jam"),
                          )
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Tombol Simpan
                      ElevatedButton(
                        onPressed: addTask, // Memanggil fungsi addTask di Part 1
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text("Simpan Tugas & Pasang Alarm"),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              }
          );
        }
    );
  }

  // === 7. TAMPILAN UTAMA APLIKASI ===
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Jadwal To-Do"),
        backgroundColor: Colors.indigo[100],
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: logout)
        ],
      ),
      body: Column(
        children: [
          // TAMPILAN KALENDER
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              loadTasks(); // Filter ulang daftar tugas sesuai tanggal yang diklik!
            },
            calendarFormat: CalendarFormat.week, // Menampilkan per minggu agar layar tidak penuh
            headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
          ),
          const Divider(thickness: 2),

          // TAMPILAN DAFTAR TUGAS
          Expanded(
            child: tasks.isEmpty
                ? const Center(child: Text("Belum ada tugas di tanggal ini. Yuk tambah!"))
                : ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, i) {
                final task = tasks[i];
                bool isDone = task['done'] == 1;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  child: ListTile(
                    leading: Checkbox(
                      value: isDone,
                      onChanged: (_) => toggleTask(task['id'], task['done']),
                    ),
                    title: Text(
                      task['title'],
                      style: TextStyle(
                        decoration: isDone ? TextDecoration.lineThrough : null,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text("Alarm: ${task['due_time'] ?? '-'}"),

                    // Label Kategori berwarna (mengembalikan kodemu sebelumnya)
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(task['category'] ?? 'Umum', style: const TextStyle(fontSize: 12)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () => deleteTask(task['id']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
      // Tombol mengambang di pojok kanan bawah
      floatingActionButton: FloatingActionButton(
        onPressed: showAddTaskSheet,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
} // <-- INI ADALAH KURUNG TUTUP UNTUK _TodoScreenState YANG DARI PART 1