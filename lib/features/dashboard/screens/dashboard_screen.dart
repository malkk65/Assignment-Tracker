import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/cache/user_cache.dart';
import '../../../core/models/assignment.dart';
import '../../assignments/screens/assignment_detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/assignment_service.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Assignment>>(
      stream: AssignmentService.getAssignmentsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final assignments = snapshot.data ?? [];
        final upcoming = assignments
            .where((a) => !a.isCompleted && !a.isOverdue)
            .toList()
          ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

        return SafeArea(
          child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with role indicator
            Row(
              children: [
                Icon(
                  UserCache.isAdmin ? Icons.admin_panel_settings : Icons.menu_book,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  UserCache.isAdmin ? 'Admin Panel' : 'Student panel',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (UserCache.isAdmin)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified, color: AppColors.primary, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'ADMIN',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Admin Stats ──
            if (UserCache.isAdmin)
              _AdminStats(assignments: assignments),

            // ── Course Breakdown ──
            _CourseBreakdown(assignments: assignments),
            const SizedBox(height: 24),

            // Upcoming
            Text(
              UserCache.isAdmin ? 'Recent Assignments' : 'Upcoming',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            if (upcoming.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, color: AppColors.success, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        UserCache.isAdmin ? 'No pending assignments' : 'All caught up! 🎉',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...upcoming.take(3).map(
                    (a) => _UpcomingCard(
                      assignment: a,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AssignmentDetailScreen(assignment: a),
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
      },
    );
  }
}

class _UpcomingCard extends StatelessWidget {
  final Assignment assignment;
  final VoidCallback onTap;

  const _UpcomingCard({
    required this.assignment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    assignment.courseCode,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: assignment.priorityColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${assignment.priority.toUpperCase()} PRIORITY',
                    style: TextStyle(
                      fontSize: 10,
                      color: assignment.priorityColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '📅 ${assignment.dueDateLabel}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              assignment.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            const SizedBox(height: 12),
            if (UserCache.isAdmin || FirebaseAuth.instance.currentUser == null)
              _buildProgress(
                assignment.statusLabel,
                assignment.progress,
                assignment.isCompleted,
              )
            else
              StreamBuilder<bool>(
                stream: AssignmentService.hasStudentSubmittedStream(
                  assignment.id,
                  FirebaseAuth.instance.currentUser!.uid,
                ),
                builder: (context, snapshot) {
                  final hasSubmitted = snapshot.data ?? false;
                  final progress = hasSubmitted ? 100 : assignment.progress;
                  final isCompleted = hasSubmitted || assignment.isCompleted;
                  final statusLabel = hasSubmitted ? 'COMPLETED' : assignment.statusLabel;

                  return _buildProgress(statusLabel, progress, isCompleted);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgress(String statusLabel, int progress, bool isCompleted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              statusLabel,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              '$progress%',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress / 100,
            backgroundColor: AppColors.divider,
            valueColor: AlwaysStoppedAnimation(
              isCompleted ? AppColors.success : AppColors.primary,
            ),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

}

class _AdminStats extends StatelessWidget {
  final List<Assignment> assignments;

  const _AdminStats({required this.assignments});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AggregateQuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
          .count()
          .get(),
      builder: (context, snapshot) {
        final studentCount = snapshot.data?.count ?? 0;
        final totalAssignments = assignments.length;
        final overdue = assignments.where((a) => a.isOverdue).length;
        final courses = assignments
            .map((a) => a.courseName.isNotEmpty ? a.courseName : a.courseCode)
            .toSet()
            .length;

        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Total Students',
                      value: studentCount.toString(),
                      icon: Icons.people_rounded,
                      color: const Color(0xFF6366F1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'Assignments',
                      value: totalAssignments.toString(),
                      icon: Icons.assignment_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Overdue',
                      value: overdue.toString(),
                      icon: Icons.warning_amber_rounded,
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'Courses',
                      value: courses.toString(),
                      icon: Icons.menu_book_rounded,
                      color: const Color(0xFFD97706),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseBreakdown extends StatelessWidget {
  final List<Assignment> assignments;

  const _CourseBreakdown({required this.assignments});

  static const List<Color> _courseColors = [
    Color(0xFFE8D5C4),
    Color(0xFFFFE0CC),
    Color(0xFFD4EDDA),
    Color(0xFFD6E9F8),
    Color(0xFFF3E5F5),
    Color(0xFFFFF9C4),
  ];

  static const List<IconData> _courseIcons = [
    Icons.architecture,
    Icons.menu_book,
    Icons.functions,
    Icons.science,
    Icons.computer,
    Icons.palette,
  ];

  static const List<Color> _courseIconColors = [
    Color(0xFFC9784D),
    Color(0xFFD97706),
    Color(0xFF289898),
    Color(0xFF6366F1),
    Color(0xFF059669),
    Color(0xFFDB2777),
  ];

  @override
  Widget build(BuildContext context) {
    if (assignments.isEmpty) return const SizedBox.shrink();

    final Map<String, List<Assignment>> courseMap = {};
    for (final a in assignments) {
      final key = a.courseName.isNotEmpty ? a.courseName : a.courseCode;
      courseMap.putIfAbsent(key, () => []).add(a);
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Course Breakdown',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          ...courseMap.entries.toList().asMap().entries.map((entry) {
            final idx = entry.key;
            final courseName = entry.value.key;
            final courseAssignments = entry.value.value;
            final total = courseAssignments.length;
            final bgColor = _courseColors[idx % _courseColors.length];
            final iconData = _courseIcons[idx % _courseIcons.length];
            final iconColor = _courseIconColors[idx % _courseIconColors.length];

            if (UserCache.isAdmin || uid == null) {
              final completed = courseAssignments.where((a) => a.isCompleted).length;
              return _CourseRow(
                courseName: courseName,
                completed: completed,
                total: total,
                bgColor: bgColor,
                iconData: iconData,
                iconColor: iconColor,
              );
            } else {
              return FutureBuilder<int>(
                future: _countStudentCompletedInCourse(courseAssignments, uid),
                builder: (context, snap) {
                  final completed = snap.data ?? 0;
                  return _CourseRow(
                    courseName: courseName,
                    completed: completed,
                    total: total,
                    bgColor: bgColor,
                    iconData: iconData,
                    iconColor: iconColor,
                  );
                },
              );
            }
          }),
        ],
      ),
    );
  }

  Future<int> _countStudentCompletedInCourse(
      List<Assignment> courseAssignments, String uid) async {
    int count = 0;
    for (final a in courseAssignments) {
      final doc = await FirebaseFirestore.instance
          .collection('assignments')
          .doc(a.id)
          .collection('submissions')
          .doc(uid)
          .get();
      if (doc.exists) count++;
    }
    return count;
  }
}

class _CourseRow extends StatelessWidget {
  final String courseName;
  final int completed;
  final int total;
  final Color bgColor;
  final IconData iconData;
  final Color iconColor;

  const _CourseRow({
    required this.courseName,
    required this.completed,
    required this.total,
    required this.bgColor,
    required this.iconData,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? completed / total : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(iconData, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        courseName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '$completed/$total',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.divider,
                    valueColor: AlwaysStoppedAnimation(iconColor),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
