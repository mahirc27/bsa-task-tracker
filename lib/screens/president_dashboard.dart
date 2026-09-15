import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/api_service.dart';

const List<String> kDepartments = [
  'All',
  'Admin',
  'Finance and External',
  'Marketing',
  'Operations',
  'Events',
  'Graphics',
  'Photography',
];

class PresidentDashboard extends StatefulWidget {
  const PresidentDashboard({super.key});

  @override
  State<PresidentDashboard> createState() => _PresidentDashboardState();
}

class _PresidentDashboardState extends State<PresidentDashboard> {
  String? _pin;
  Future<List<Task>>? _tasksFuture;
  String _selectedDepartment = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _promptPinDialog());
  }

  void _promptPinDialog() {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('President Authorization'),
        content: TextField(
          controller: pinController,
          obscureText: true,
          autofocus: true,
          keyboardType: TextInputType.number,
          maxLength: 4,
          decoration: const InputDecoration(
            labelText: 'Enter 4-Digit PIN',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final entered = pinController.text.trim();
              Navigator.pop(ctx);
              setState(() {
                _pin = entered;
                _loadTasks();
              });
            },
            child: const Text('Unlock'),
          ),
        ],
      ),
    );
  }

  void _loadTasks() {
    if (_pin != null) {
      setState(() {
        _tasksFuture = ApiService.fetchTasks(pin: _pin);
      });
    }
  }

  void _showCreateTaskDialog() {
    final titleController = TextEditingController();
    final assigneeController = TextEditingController();
    String targetDept = kDepartments[1];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Assign New Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Task Title'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: assigneeController,
                decoration: const InputDecoration(labelText: 'Assignee Name'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: targetDept,
                decoration: const InputDecoration(
                  labelText: 'Department',
                  border: OutlineInputBorder(),
                ),
                items: kDepartments.where((d) => d != 'All').map((d) {
                  return DropdownMenuItem(value: d, child: Text(d));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => targetDept = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty &&
                    assigneeController.text.isNotEmpty &&
                    _pin != null) {
                  try {
                    await ApiService.createTask(
                      title: titleController.text.trim(),
                      assignee: assigneeController.text.trim(),
                      department: targetDept,
                      pin: _pin!,
                    );
                    if (mounted) {
                      Navigator.pop(ctx);
                      _loadTasks();
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to assign task. Check PIN.')),
                      );
                    }
                  }
                }
              },
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusColumn(String status, List<Task> tasks, {bool isMobileTab = false}) {
    final filtered = tasks.where((t) => t.status == status).toList();

    Widget content = Card(
      margin: const EdgeInsets.all(6.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
              child: Text(
                '$status (${filtered.length})',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(),
            if (filtered.isEmpty)
              const Expanded(
                child: Center(
                  child: Text('No tasks here', style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (ctx, idx) {
                    final task = filtered[idx];
                    return Card(
                      child: ListTile(
                        title: Text(task.title),
                        subtitle: Text('${task.department} • ${task.assignee}'),
                        trailing: PopupMenuButton<String>(
                          initialValue: task.status,
                          onSelected: (newStatus) async {
                            await ApiService.updateTaskStatus(
                              taskId: task.id,
                              status: newStatus,
                              pin: _pin,
                            );
                            _loadTasks();
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'Pending', child: Text('Pending')),
                            PopupMenuItem(value: 'In Progress', child: Text('In Progress')),
                            PopupMenuItem(value: 'Done', child: Text('Done')),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );

    return isMobileTab ? content : Expanded(child: content);
  }

  @override
  Widget build(BuildContext context) {
    if (_pin == null || _tasksFuture == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('President Board')),
        body: const Center(child: Text('PIN Required to unlock.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('President Board'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadTasks)],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateTaskDialog,
        child: const Icon(Icons.add),
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

          final allTasks = snapshot.data ?? [];
          final displayTasks = _selectedDepartment == 'All'
              ? allTasks
              : allTasks.where((t) => t.department == _selectedDepartment).toList();

          return Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Row(
                  children: kDepartments.map((dept) {
                    final isSelected = _selectedDepartment == dept;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ChoiceChip(
                        label: Text(dept),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedDepartment = dept);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 600) {
                      return DefaultTabController(
                        length: 3,
                        child: Column(
                          children: [
                            const TabBar(
                              labelColor: Colors.blueAccent,
                              unselectedLabelColor: Colors.grey,
                              indicatorColor: Colors.blueAccent,
                              tabs: [
                                Tab(text: 'Pending'),
                                Tab(text: 'In Progress'),
                                Tab(text: 'Done'),
                              ],
                            ),
                            Expanded(
                              child: TabBarView(
                                children: [
                                  _buildStatusColumn('Pending', displayTasks, isMobileTab: true),
                                  _buildStatusColumn('In Progress', displayTasks, isMobileTab: true),
                                  _buildStatusColumn('Done', displayTasks, isMobileTab: true),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatusColumn('Pending', displayTasks),
                        _buildStatusColumn('In Progress', displayTasks),
                        _buildStatusColumn('Done', displayTasks),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}