import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/assignments/models/assignment.dart';

class AssignmentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'assignments';

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
}
