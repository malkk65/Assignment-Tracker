import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/assignment.dart';
import 'storage_service.dart';

class AssignmentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'assignments';

  /// Uploads a file to Supabase Storage and returns the public download URL.
  static Future<String> uploadFile(File file, String folderPath) {
    return StorageService.uploadFile(file, folderPath);
  }

  /// Creates a new assignment in Firestore.
  static Future<void> createAssignment(Assignment assignment) async {
    await _firestore.collection(_collectionName).add(assignment.toFirestore());
  }

  /// Updates an existing assignment in Firestore.
  static Future<void> updateAssignment(Assignment assignment) async {
    await _firestore
        .collection(_collectionName)
        .doc(assignment.id)
        .update(assignment.toFirestore());
  }

  /// Deletes an assignment from Firestore.
  static Future<void> deleteAssignment(String id) async {
    await _firestore.collection(_collectionName).doc(id).delete();
  }

  /// Returns a realtime stream of all assignments from Firestore.
  static Stream<List<Assignment>> getAssignmentsStream() {
    return _firestore
        .collection(_collectionName)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Assignment.fromFirestore(doc.data(), doc.id);
      }).toList();
    });
  }

  static Stream<bool> hasStudentSubmittedStream(String assignmentId, String studentId) {
    return _firestore
        .collection(_collectionName)
        .doc(assignmentId)
        .collection('submissions')
        .doc(studentId)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  /// Submits a student's answer for an assignment.
  static Future<void> submitStudentAnswer({
    required String assignmentId,
    required String studentId,
    required String studentName,
    required String fileUrl,
    required String fileName,
  }) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(assignmentId)
          .collection('submissions')
          .doc(studentId)
          .set({
        'studentName': studentName,
        'fileUrl': fileUrl,
        'fileName': fileName,
        'submittedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to save submission info to database: $e');
    }
  }

  /// Calculates dynamic stats for a specific student.
  static Future<Map<String, int>> getStudentStats(String studentId) async {
    final assignmentsSnap = await _firestore.collection(_collectionName).get();
    int total = assignmentsSnap.docs.length;
    int completed = 0;
    int overdue = 0;

    final now = DateTime.now();

    for (var doc in assignmentsSnap.docs) {
      final assignment = Assignment.fromFirestore(doc.data(), doc.id);
      
      // Check if student has a submission for this assignment
      final submission = await _firestore
          .collection(_collectionName)
          .doc(doc.id)
          .collection('submissions')
          .doc(studentId)
          .get();

      if (submission.exists) {
        completed++;
      } else if (assignment.dueDate.isBefore(now)) {
        overdue++;
      }
    }

    int inProgress = total - completed - overdue;

    return {
      'total': total,
      'completed': completed,
      'inProgress': inProgress < 0 ? 0 : inProgress,
      'overdue': overdue,
    };
  }

  /// Calculates dynamic stats for the admin.
  static Future<Map<String, int>> getAdminStats() async {
    try {
      // 1. Get all assignments
      final assignmentsSnap = await _firestore.collection(_collectionName).get();
      int totalAssignments = assignmentsSnap.docs.length;
      int activeAssignments = 0;
      int expiredAssignments = 0;
      int totalSubmissions = 0;

      final now = DateTime.now();

      // 2. Count active/expired assignments and sum up all submissions
      for (var doc in assignmentsSnap.docs) {
        final assignment = Assignment.fromFirestore(doc.data(), doc.id);
        
        if (assignment.dueDate.isAfter(now)) {
          activeAssignments++;
        } else {
          expiredAssignments++;
        }

        final submissionsSnap = await _firestore
            .collection(_collectionName)
            .doc(doc.id)
            .collection('submissions')
            .get();
            
        totalSubmissions += submissionsSnap.docs.length;
      }

      // 3. Get total number of students
      final studentsSnap = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();
      int totalStudents = studentsSnap.docs.length;

      return {
        'totalAssignments': totalAssignments,
        'activeAssignments': activeAssignments,
        'expiredAssignments': expiredAssignments,
        'totalSubmissions': totalSubmissions,
        'totalStudents': totalStudents,
      };
    } catch (e) {
      return {
        'totalAssignments': 0,
        'activeAssignments': 0,
        'expiredAssignments': 0,
        'totalSubmissions': 0,
        'totalStudents': 0,
      };
    }
  }

  /// Deletes a student's submission and returns the file path to be deleted from storage.
  static Future<String?> deleteSubmission(String assignmentId, String studentId) async {
    try {
      final doc = await _firestore
          .collection(_collectionName)
          .doc(assignmentId)
          .collection('submissions')
          .doc(studentId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final fileUrl = data['fileUrl'] as String;
        
        // Delete from Firestore
        await _firestore
            .collection(_collectionName)
            .doc(assignmentId)
            .collection('submissions')
            .doc(studentId)
            .delete();
            
        return fileUrl;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to delete submission: $e');
    }
  }

  /// Gets a stream of all submissions for an assignment.
  static Stream<QuerySnapshot> getSubmissionsStream(String assignmentId) {
    return _firestore
        .collection(_collectionName)
        .doc(assignmentId)
        .collection('submissions')
        .orderBy('submittedAt', descending: true)
        .snapshots();
  }
}
