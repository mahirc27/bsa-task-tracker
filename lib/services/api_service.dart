import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/task.dart';

class ApiService {
  static const String baseUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://127.0.0.1:5001',
  );

  static Future<List<Task>> fetchTasks({String? department, String? pin}) async {
    final uri = Uri.parse('$baseUrl/tasks').replace(
      queryParameters: department != null && department.isNotEmpty
          ? {'department': department}
          : null,
    );

    final headers = <String, String>{};
    if (pin != null) headers['X-Admin-PIN'] = pin;

    final response = await http.get(uri, headers: headers);
    if (response.statusCode == 200) {
      final List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => Task.fromJson(item)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('Incorrect PIN');
    } else {
      throw Exception('Failed to load tasks');
    }
  }

  static Future<Task> createTask({
    required String title,
    required String assignee,
    required String department,
    required String pin,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/tasks'),
      headers: {
        'Content-Type': 'application/json',
        'X-Admin-PIN': pin,
      },
      body: jsonEncode({
        'title': title,
        'assignee': assignee,
        'department': department,
        'status': 'Pending',
      }),
    );

    if (response.statusCode == 201) {
      return Task.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create task');
    }
  }

  static Future<void> updateTaskStatus({
    required int taskId,
    required String status,
    String? userName,
    String? pin,
  }) async {
    final headers = {'Content-Type': 'application/json'};
    if (pin != null) headers['X-Admin-PIN'] = pin;

    final response = await http.patch(
      Uri.parse('$baseUrl/tasks/$taskId'),
      headers: headers,
      body: jsonEncode({
        'status': status,
        if (userName != null) 'user_name': userName,
      }),
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Failed to update task');
    }
  }
}
