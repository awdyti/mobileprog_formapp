// lib/pages/todo_list_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import 'profile_page.dart';
import '../model/task.dart';

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});
  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  final TextEditingController _taskController = TextEditingController();

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  void _addTask() {
    final text = _taskController.text.trim();
    if (text.isEmpty) return;
    Provider.of<TasksProvider>(context, listen: false).addTask(text);
    _taskController.clear();
    FocusScope.of(context).unfocus();
  }

  Future<void> _confirmClearAll(TasksProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Semua Tugas?'),
        content: const Text(
          'Tindakan ini akan menghapus semua tugas. Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await provider.clearAll();

      if (!context.mounted) return;

      // Pastikan UI sudah stabil (dialog ditutup) sebelum menampilkan SnackBar
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Semua tugas dihapus')));
      });
    }
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      labelText: 'Tugas Baru',
      prefixIcon: const Icon(Icons.edit_note),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TasksProvider>(context, listen: false);
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(''),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Profil',
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ProfilePage()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Hapus Semua',
            onPressed: () => _confirmClearAll(provider),
          ),
        ],
      ),

      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.95),
              theme.colorScheme.primary.withValues(alpha: 0.75),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),

        child: SafeArea(
          child: Column(
            children: [
              const StatsCard(),

              // Input task card modern
              Padding(
                padding: const EdgeInsets.all(14),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _taskController,
                            decoration: _inputDecoration(),
                            onSubmitted: (_) => _addTask(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.add, color: Colors.white),
                            onPressed: _addTask,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // daftar tugas
              Expanded(
                child: Consumer<TasksProvider>(
                  builder: (context, tasksProvider, child) {
                    final tasks = tasksProvider.tasks;

                    if (tasks.isEmpty) {
                      return const Center(
                        child: Text(
                          'Belum ada tugas\nTambah tugas di atas!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final t = tasks[index];

                        return Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Dismissible(
                            key: Key('${t.id}_$index'),
                            background: Container(
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                            direction: DismissDirection.endToStart,
                            onDismissed: (_) {
                              final removedTitle = tasksProvider.deleteTask(
                                index,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Tugas "$removedTitle" dihapus',
                                  ),
                                ),
                              );
                            },

                            child: ListTile(
                              onTap: () =>
                                  tasksProvider.toggleTaskCompletion(index),
                              leading: Icon(
                                t.isCompleted
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                                color: t.isCompleted
                                    ? Colors.green
                                    : Colors.grey,
                              ),
                              title: Text(
                                t.title,
                                style: TextStyle(
                                  decoration: t.isCompleted
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                  color: t.isCompleted
                                      ? Colors.grey
                                      : Colors.black,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stats card modern
// ---------------------------------------------------------------------------

class StatsCard extends StatelessWidget {
  const StatsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TasksProvider>(context, listen: false);

    return StreamBuilder<List<Task>>(
      stream: provider.broadcastStream,
      builder: (context, snapshot) {
        final tasks = snapshot.data ?? provider.tasks;
        final total = tasks.length;
        final done = tasks.where((t) => t.isCompleted).length;
        final percent = total == 0 ? 0 : ((done / total) * 100).round();

        return Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
          child: Card(
            elevation: 10,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.bar_chart, size: 30),
                  const SizedBox(width: 14),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total: $total • Selesai: $done',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Progress: $percent%',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),

                  const Spacer(),

                  SizedBox(
                    width: 100,
                    child: LinearProgressIndicator(
                      value: total == 0 ? 0 : done / total,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
