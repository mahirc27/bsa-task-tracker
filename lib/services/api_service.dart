import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/task.dart';

class ApiService {
  static const String baseUrl = 'https://bsa-tasks-backend.onrender.com';

  static Future<List<Task>> fetchTasks({String? department, String? pin}) async {
    final Map<String, String> queryParams = {};
    if (department != null) {
      queryParams['department'] = department;
    }
    if (pin != null && pin.isNotEmpty) {
      queryParams['pin'] = pin.trim();
    }

    final uri = Uri.parse('$baseUrl/tasks').replace(
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Task.fromJson(json)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized');
    } else {
      throw Exception('Failed to load tasks');
    }
  }

  static Future<void> createTask({
    required String title,
    required String assignee,
    required String department,
    required String pin,
    String? deadline,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/tasks'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': title,
        'assignee': assignee,
        'department': department,
        'pin': pin.trim(),
        'deadline': deadline,
      }),
    );

    if (response.statusCode == 401) {
      throw Exception('Unauthorized');
    } else if (response.statusCode != 201) {
      throw Exception('Failed to create task: ${response.body}');
    }
  }

  // Accepts positional parameters (taskId, status) and optional named parameter {pin}
  static Future<void> updateTaskStatus(int taskId, String status, {String? pin}) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/tasks/$taskId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'status': status,
        if (pin != null) 'pin': pin.trim(),
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update task status');
    }
  }
}