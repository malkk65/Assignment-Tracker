class AssignmentModel {
  final String id;
  final String title;
  final String description;
  final String courseName;
  final DateTime dueDate;
  final String status; // pending, inProgress, completed, overdue
  final String priority; // low, medium, high

  AssignmentModel({
    required this.id,
    required this.title,
    required this.description,
    required this.courseName,
    required this.dueDate,
    required this.status,
    required this.priority,
  });

  factory AssignmentModel.fromJson(Map<String, dynamic> json) {
    return AssignmentModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      courseName: json['courseName'] ?? '',
      dueDate: DateTime.parse(json['dueDate']),
      status: json['status'] ?? 'pending',
      priority: json['priority'] ?? 'medium',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'courseName': courseName,
      'dueDate': dueDate.toIso8601String(),
      'status': status,
      'priority': priority,
    };
  }
}
