import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/assignment.dart';
import '../../../core/widgets/status_badge.dart';

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
            // ── Icon + Deadline Row ──
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: assignment.priorityColor.withValues(alpha: 0.1),
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
                  color: assignment.deadlineColor,
                ),
                const SizedBox(width: 4),
                Text(
                  assignment.dueDateLabel,
                  style: TextStyle(
                    color: assignment.deadlineColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Course Tag ──
            StatusBadge(
              label: assignment.courseCode,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              textColor: AppColors.primary,
            ),
            const SizedBox(height: 8),

            // ── Title ──
            Text(
              assignment.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // ── Status + Progress ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StatusBadge.fromColors(
                  label: assignment.statusLabel,
                  colors: assignment.statusColors,
                ),
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

            // ── Progress Bar ──
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

  IconData get _courseIcon {
    final code = assignment.courseCode.toLowerCase();
    if (code.contains('art') || code.contains('digital')) return Icons.architecture;
    if (code.contains('lit')) return Icons.book_outlined;
    if (code.contains('calc') || code.contains('math')) return Icons.functions;
    if (code.contains('cs')) return Icons.storage;
    return Icons.assignment_outlined;
  }
}
