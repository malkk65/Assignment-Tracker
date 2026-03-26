import 'package:flutter/material.dart';
import '../models/assignment_model.dart';

class AssignmentViewModel extends ChangeNotifier {
  List<AssignmentModel> _assignments = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<AssignmentModel> get assignments => _assignments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Fetch all assignments
  Future<void> fetchAssignments() async {
    _isLoading = true;
    notifyListeners();

    try {
      // TODO: Call API service
      await Future.delayed(const Duration(seconds: 1));
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add assignment
  Future<void> addAssignment(AssignmentModel assignment) async {
    // TODO: Call API service
    _assignments.add(assignment);
    notifyListeners();
  }

  // Update assignment
  Future<void> updateAssignment(AssignmentModel assignment) async {
    // TODO: Call API service
    final index = _assignments.indexWhere((a) => a.id == assignment.id);
    if (index != -1) {
      _assignments[index] = assignment;
      notifyListeners();
    }
  }

  // Delete assignment
  Future<void> deleteAssignment(String id) async {
    // TODO: Call API service
    _assignments.removeWhere((a) => a.id == id);
    notifyListeners();
  }
}
