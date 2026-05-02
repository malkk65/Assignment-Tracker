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

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      courseCode: json['courseCode'] ?? '',
      courseName: json['courseName'] ?? '',
      dueDate: DateTime.parse(json['dueDate']),
      status: json['status'] ?? 'pending',
      priority: json['priority'] ?? 'medium',
      progress: json['progress'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'courseCode': courseCode,
        'courseName': courseName,
        'dueDate': dueDate.toIso8601String(),
        'status': status,
        'priority': priority,
        'progress': progress,
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
