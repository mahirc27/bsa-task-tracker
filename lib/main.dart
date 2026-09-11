import 'package:flutter/material.dart';
import 'screens/president_dashboard.dart';
import 'screens/department_view.dart';

void main() {
  runApp(const ClubTaskApp());
}

class ClubTaskApp extends StatelessWidget {
  const ClubTaskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BSA Task Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/president': (context) => const PresidentDashboard(),
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  final List<Map<String, dynamic>> departments = const [
    {'name': 'Events', 'icon': Icons.celebration},
    {'name': 'Marketing', 'icon': Icons.campaign},
    {'name': 'Finance', 'icon': Icons.account_balance_wallet},
    {'name': 'Logistics', 'icon': Icons.local_shipping},
    {'name': 'Internal', 'icon': Icons.groups},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BSA Task Tracker'),
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.shield_outlined),
                label: const Text('President Board (PIN Required)'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)),
                onPressed: () => Navigator.pushNamed(context, '/president'),
              ),
              const SizedBox(height: 24),
              const Text(
                'Select Your Department',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: departments.length,
                  itemBuilder: (ctx, idx) {
                    final dept = departments[idx];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6.0),
                      child: ListTile(
                        leading: Icon(dept['icon'] as IconData, color: Theme.of(context).primaryColor),
                        title: Text(dept['name'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DepartmentView(department: dept['name'] as String),
                            ),
                          );
                        },
                      ),
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
