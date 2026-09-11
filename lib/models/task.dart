class Task {
  final int id;
  final String title;
  final String assignee;
  final String department;
  final String status;

  Task({
    required this.id,
    required this.title,
    required this.assignee,
    required this.department,
    required this.status,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as int,
      title: json['title'] as String,
      assignee: json['assignee'] as String,
      department: json['department'] as String,
      status: json['status'] as String,
    );
  }
}
