import 'package:flutter/material.dart';
import 'database/db_helper.dart';
import 'login_screen.dart'; 
void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // ⬅️ WAJIB
  await DBHelper.initDB(); // ⬅️ WAJIB
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

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
      appBar: AppBar(title: const Text("To-Do Database")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: "Tambah tugas...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: addTask,
                  child: const Text("Tambah"),
                )
              ],
            ),
          ),

          Expanded(
            child: ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, i) {
                final task = tasks[i];
                return ListTile(
                  leading: Checkbox(
                    value: task['done'] == 1,
                    onChanged: (_) =>
                        toggleTask(task['id'], task['done']),
                  ),
                  title: Text(
                    task['title'],
                    style: TextStyle(
                      decoration: task['done'] == 1
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => deleteTask(task['id']),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}