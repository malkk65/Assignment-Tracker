import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../features/assignments/models/assignment.dart';

class AssignmentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static const String _collectionName = 'assignments';

  /// Uploads a file to Firebase Storage and returns the download URL.
  static Future<String> uploadFile(File file, String folderPath) async {
    final fileName = path.basename(file.path);
    final destination = '$folderPath/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    
    final ref = _storage.ref(destination);
    await ref.putFile(file);
    return await ref.getDownloadURL();
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

  /// Submits a student's answer for an assignment.
  static Future<void> submitStudentAnswer({
    required String assignmentId,
    required String studentId,
    required String studentName,
    required String fileUrl,
    required String fileName,
  }) async {
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
