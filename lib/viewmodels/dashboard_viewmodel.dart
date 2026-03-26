import 'package:flutter/material.dart';
import '../models/assignment_model.dart';

class DashboardViewModel extends ChangeNotifier {
  List<AssignmentModel> _assignments = [];
  bool _isLoading = false;

  // Getters
  List<AssignmentModel> get assignments => _assignments;
  bool get isLoading => _isLoading;

  int get totalAssignments => _assignments.length;
  int get completedCount => _assignments.where((a) => a.status == 'completed').length;
  int get pendingCount => _assignments.where((a) => a.status == 'pending').length;
  int get overdueCount => _assignments.where((a) => a.status == 'overdue').length;

  // Fetch dashboard data
  Future<void> loadDashboard() async {
    _isLoading = true;
    notifyListeners();

    try {
      // TODO: Call API service
      await Future.delayed(const Duration(seconds: 1));
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }
}
