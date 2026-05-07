import 'package:cloud_firestore/cloud_firestore.dart';

class Assignment {
  final String id;
  final String title;
  final String description;
  final String courseCode;
  final String courseName;
  final DateTime dueDate;
  final String status; // pending, in_progress, completed
  final String priority; // low, medium, high
  final int progress; // 0-100

  const Assignment({
    required this.id,
    required this.title,
    this.description = '',
    required this.courseCode,
    this.courseName = '',
    required this.dueDate,
    this.status = 'pending',
    this.priority = 'medium',
    this.progress = 0,
  });

  bool get isOverdue =>
      dueDate.isBefore(DateTime.now()) && status != 'completed';

  bool get isCompleted => status == 'completed';

  String get statusLabel {
    if (isOverdue) return 'OVERDUE';
    switch (status) {
      case 'in_progress':
        return 'IN PROGRESS';
      case 'completed':
        return 'COMPLETED';
      default:
        return 'PENDING';
    }
  }

  String get dueDateLabel {
    final now = DateTime.now();
    final diff = dueDate.difference(now).inDays;
    if (isCompleted) return 'Completed';
    if (diff < 0) return 'Overdue';
    if (diff == 0) return 'Due Today';
    if (diff == 1) return 'Due Tomorrow';
    return 'Due in $diff days';
  }

  factory Assignment.fromFirestore(Map<String, dynamic> data, String docId) {
    DateTime parsedDate;
    if (data['dueDate'] is Timestamp) {
      parsedDate = (data['dueDate'] as Timestamp).toDate();
    } else {
      parsedDate = DateTime.parse(data['dueDate'].toString());
    }

    return Assignment(
      id: docId,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      courseCode: data['courseCode'] ?? '',
      courseName: data['courseName'] ?? '',
      dueDate: parsedDate,
      status: data['status'] ?? 'pending',
      priority: data['priority'] ?? 'medium',
      progress: data['progress'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'description': description,
        'courseCode': courseCode,
        'courseName': courseName,
        'dueDate': Timestamp.fromDate(dueDate),
        'status': status,
        'priority': priority,
        'progress': progress,
        'createdAt': FieldValue.serverTimestamp(),
      };

  /// Sample data for development
  static List<Assignment> get sampleData => [
        Assignment(
          id: '1',
          title: '3D Character Modeling & Rigging',
          description: 'Create a complete 3D character model with full rigging.',
          courseCode: 'DIGITAL ARTS',
          courseName: 'Digital Arts',
          dueDate: DateTime.now().add(const Duration(days: 1)),
          status: 'in_progress',
          priority: 'high',
          progress: 60,
        ),
        Assignment(
          id: '2',
          title: 'Deconstructionism in Literature',
          description: 'Write a research paper on deconstructionism theory.',
          courseCode: 'LIT THEORY',
          courseName: 'Literature Theory',
          dueDate: DateTime.now().add(const Duration(days: 4)),
          status: 'in_progress',
          priority: 'medium',
          progress: 30,
        ),
        Assignment(
          id: '3',
          title: 'Infinite Series & Convergence',
          description: 'Solve problem set on infinite series convergence tests.',
          courseCode: 'CALCULUS II',
          courseName: 'Calculus II',
          dueDate: DateTime.now().subtract(const Duration(days: 2)),
          status: 'pending',
          priority: 'high',
          progress: 10,
        ),
        Assignment(
          id: '4',
          title: 'Database Normalization Essay',
          description: 'Create a complete ERD diagram and normalize to 3NF.',
          courseCode: 'CS101',
          courseName: 'Intro to Computer Science',
          dueDate: DateTime.now().subtract(const Duration(days: 5)),
          status: 'completed',
          priority: 'medium',
          progress: 100,
        ),
      ];
}
