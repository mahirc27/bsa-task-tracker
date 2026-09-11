import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../services/api_service.dart';

class DepartmentView extends StatefulWidget {
  final String department;
  const DepartmentView({super.key, required this.department});

  @override
  State<DepartmentView> createState() => _DepartmentViewState();
}

class _DepartmentViewState extends State<DepartmentView> {
  String? _userName;
  late Future<List<Task>> _tasksFuture;

  @override
  void initState() {
    super.initState();
    _loadUserAndTasks();
  }

  Future<void> _loadUserAndTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('exec_user_name');
    setState(() {
      _userName = stored;
      _tasksFuture = ApiService.fetchTasks(department: widget.department);
    });

    if (_userName == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _promptNameDialog());
    }
  }

  void _promptNameDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Identify Yourself'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Enter your first name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('exec_user_name', name);
                setState(() => _userName = name);
                if (mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.department} Team'),
        actions: [
          if (_userName != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Center(
                child: ActionChip(
                  avatar: const Icon(Icons.person, size: 16),
                  label: Text(_userName!),
                  onPressed: _promptNameDialog,
                ),
              ),
            ),
        ],
      ),
      body: FutureBuilder<List<Task>>(
        future: _tasksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final tasks = snapshot.data ?? [];
          if (tasks.isEmpty) {
            return const Center(child: Text('No active tasks for this department.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12.0),
            itemCount: tasks.length,
            itemBuilder: (ctx, idx) {
              final task = tasks[idx];
              final isDone = task.status == 'Done';
              final isMyTask = _userName != null &&
                  _userName!.trim().toLowerCase() == task.assignee.trim().toLowerCase();

              return Card(
                elevation: isMyTask ? 3 : 1,
                margin: const EdgeInsets.symmetric(vertical: 6.0),
                child: ListTile(
                  title: Text(
                    task.title,
                    style: TextStyle(
                      fontWeight: isMyTask ? FontWeight.bold : FontWeight.normal,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  subtitle: Text(
                    isMyTask ? 'Assigned to: YOU' : 'Assigned to: ${task.assignee}',
                    style: TextStyle(
                      color: isMyTask ? Theme.of(context).colorScheme.primary : Colors.grey[700],
                    ),
                  ),
                  trailing: isDone
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : isMyTask
                          ? ElevatedButton(
                              onPressed: () async {
                                try {
                                  await ApiService.updateTaskStatus(
                                    taskId: task.id,
                                    status: 'Done',
                                    userName: _userName,
                                  );
                                  setState(() {
                                    _tasksFuture = ApiService.fetchTasks(department: widget.department);
                                  });
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(e.toString())),
                                    );
                                  }
                                }
                              },
                              child: const Text('Mark Done'),
                            )
                          : Chip(
                              label: Text(task.status),
                              backgroundColor: Colors.grey[200],
                            ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
