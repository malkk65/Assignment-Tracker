import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';


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
  final String? fileAttachmentUrl;
  final String? fileAttachmentName;

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
    this.fileAttachmentUrl,
    this.fileAttachmentName,
  });

  // ── Computed Properties ──

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

  /// Returns the color associated with this assignment's priority level.
  /// Eliminates the duplicated `_priorityColor` getter across 3 files.
  Color get priorityColor {
    switch (priority) {
      case 'high':
        return AppColors.highPriority;
      case 'medium':
        return AppColors.mediumPriority;
      default:
        return AppColors.lowPriority;
    }
  }

  /// Returns the color for the deadline indicator.
  Color get deadlineColor {
    if (isOverdue) return AppColors.urgent;
    if (isCompleted) return AppColors.success;
    return AppColors.textSecondary;
  }

  /// Returns a status-appropriate background/text color pair.
  ({Color background, Color foreground}) get statusColors {
    if (isOverdue) {
      return (
        background: AppColors.urgent.withValues(alpha: 0.1),
        foreground: AppColors.urgent,
      );
    }
    if (isCompleted) {
      return (
        background: AppColors.success.withValues(alpha: 0.1),
        foreground: AppColors.success,
      );
    }
    return (
      background: AppColors.warning.withValues(alpha: 0.1),
      foreground: AppColors.warning,
    );
  }

  // ── Firestore Serialization ──

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
      fileAttachmentUrl: data['fileAttachmentUrl'],
      fileAttachmentName: data['fileAttachmentName'],
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
        'fileAttachmentUrl': fileAttachmentUrl,
        'fileAttachmentName': fileAttachmentName,
        'createdAt': FieldValue.serverTimestamp(),
      };

  Assignment copyWith({
    String? id,
    String? title,
    String? description,
    String? courseCode,
    String? courseName,
    DateTime? dueDate,
    String? status,
    String? priority,
    int? progress,
    String? fileAttachmentUrl,
    String? fileAttachmentName,
  }) {
    return Assignment(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      courseCode: courseCode ?? this.courseCode,
      courseName: courseName ?? this.courseName,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      progress: progress ?? this.progress,
      fileAttachmentUrl: fileAttachmentUrl ?? this.fileAttachmentUrl,
      fileAttachmentName: fileAttachmentName ?? this.fileAttachmentName,
    );
  }
}
