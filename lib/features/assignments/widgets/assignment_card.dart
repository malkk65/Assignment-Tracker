import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/assignment.dart';

class AssignmentCard extends StatelessWidget {
  final Assignment assignment;
  final VoidCallback onTap;

  const AssignmentCard({
    super.key,
    required this.assignment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon + deadline row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _priorityColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _courseIcon,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: _deadlineColor,
                ),
                const SizedBox(width: 4),
                Text(
                  assignment.dueDateLabel,
                  style: TextStyle(
                    color: _deadlineColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Course tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                assignment.courseCode,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Title
            Text(
              assignment.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Status + progress
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusTag(),
                Text(
                  '${assignment.progress}%',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: assignment.progress / 100,
                backgroundColor: AppColors.divider,
                valueColor: AlwaysStoppedAnimation(
                  assignment.isCompleted ? AppColors.success : AppColors.primary,
                ),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTag() {
    Color bg;
    Color text;
    final label = assignment.statusLabel;

    if (assignment.isOverdue) {
      bg = AppColors.urgent.withValues(alpha: 0.1);
      text = AppColors.urgent;
    } else if (assignment.isCompleted) {
      bg = AppColors.success.withValues(alpha: 0.1);
      text = AppColors.success;
    } else {
      bg = AppColors.warning.withValues(alpha: 0.1);
      text = AppColors.warning;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color get _priorityColor {
    switch (assignment.priority) {
      case 'high':
        return AppColors.highPriority;
      case 'medium':
        return AppColors.mediumPriority;
      default:
        return AppColors.lowPriority;
    }
  }

  Color get _deadlineColor {
    if (assignment.isOverdue) return AppColors.urgent;
    if (assignment.isCompleted) return AppColors.success;
    return AppColors.textSecondary;
  }

  IconData get _courseIcon {
    final code = assignment.courseCode.toLowerCase();
    if (code.contains('art') || code.contains('digital')) return Icons.architecture;
    if (code.contains('lit')) return Icons.book_outlined;
    if (code.contains('calc') || code.contains('math')) return Icons.functions;
    if (code.contains('cs')) return Icons.storage;
    return Icons.assignment_outlined;
  }
}
