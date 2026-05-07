import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/assignment.dart';
import '../widgets/assignment_card.dart';
import 'assignment_detail_screen.dart';
import '../../admin/screens/admin_add_assignment_screen.dart';
import '../../../core/cache/user_cache.dart';

class AssignmentListScreen extends StatefulWidget {
  const AssignmentListScreen({super.key});

  @override
  State<AssignmentListScreen> createState() => _AssignmentListScreenState();
}

class _AssignmentListScreenState extends State<AssignmentListScreen> {
  String _selectedFilter = 'All';
  String _searchQuery = '';

  final List<Assignment> _assignments = Assignment.sampleData;

  List<Assignment> get _filteredAssignments {
    return _assignments.where((item) {
      final matchesSearch =
          item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              item.courseCode.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesFilter = _selectedFilter == 'All' ||
          (_selectedFilter == 'Overdue' && item.isOverdue) ||
          (_selectedFilter == 'Completed' && item.isCompleted) ||
          (_selectedFilter == 'In Progress' && item.status == 'in_progress') ||
          (_selectedFilter == 'Pending' && item.status == 'pending' && !item.isOverdue);

      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredAssignments;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: UserCache.isAdmin
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminAddAssignmentScreen(),
                  ),
                );
              },
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Add Task',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          : null,
      body: Column(
        children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search for assignments...',
              prefixIcon: const Icon(Icons.search, color: AppColors.textHint),
              filled: true,
              fillColor: AppColors.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: ['All', 'Pending', 'In Progress', 'Completed', 'Overdue']
                .map((f) => Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: _buildFilterChip(f),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 20),
        // Assignment list
        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_off, size: 48, color: AppColors.textHint),
                      SizedBox(height: 12),
                      Text(
                        'No assignments found',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final assignment = filtered[index];
                    return AssignmentCard(
                      assignment: assignment,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AssignmentDetailScreen(
                            assignment: assignment,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
