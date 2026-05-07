import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_role.dart';
import '../cache/user_cache.dart';

/// Service responsible for managing user data in Firestore.
/// Handles role persistence, user profile creation, and role loading.
class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _usersCollection = 'users';

  /// The secret code required to register as an admin.
  /// In production, this should come from a secure config / environment variable.
  static const String adminSecretCode = 'BATU2026';

  /// Verifies if the provided code matches the admin secret.
  static bool verifyAdminCode(String code) {
    return code.trim() == adminSecretCode;
  }

  /// Creates a new user document in Firestore after registration.
  static Future<void> createUserDocument({
    required String uid,
    required String name,
    required String email,
    required UserRole role,
    String? university,
    String? faculty,
  }) async {
    await _firestore.collection(_usersCollection).doc(uid).set({
      'name': name,
      'email': email,
      'role': role.toFirestore(),
      'university': university ?? 'Borg Alarab Technological University',
      'faculty': faculty ?? 'Faculty of Information Technology',
      'createdAt': FieldValue.serverTimestamp(),
      'lastLogin': FieldValue.serverTimestamp(),
    });
  }

  /// Loads the user's role and profile data from Firestore into UserCache.
  /// Returns the loaded [UserRole].
  static Future<UserRole> loadUserData(String uid) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(uid).get();

      if (doc.exists) {
        final data = doc.data()!;
        final role = UserRole.fromString(data['role'] as String?);

        // Update local cache with Firestore data
        UserCache.role = role;
        UserCache.university = data['university'] as String? ?? UserCache.university;
        UserCache.faculty = data['faculty'] as String? ?? UserCache.faculty;

        // Update last login timestamp
        await _firestore.collection(_usersCollection).doc(uid).update({
          'lastLogin': FieldValue.serverTimestamp(),
        });

        return role;
      }

      // If document doesn't exist (e.g., legacy user), create one with Student role
      final user = FirebaseAuth.instance.currentUser;
      await createUserDocument(
        uid: uid,
        name: user?.displayName ?? 'Student',
        email: user?.email ?? '',
        role: UserRole.student,
      );
      UserCache.role = UserRole.student;
      return UserRole.student;
    } catch (e) {
      // Fallback to student role on error
      UserCache.role = UserRole.student;
      return UserRole.student;
    }
  }

  /// Updates the user's profile data in Firestore and local cache.
  static Future<void> updateUserProfile({
    required String uid,
    String? name,
    String? university,
    String? faculty,
  }) async {
    final updates = <String, dynamic>{};

    if (name != null) updates['name'] = name;
    if (university != null) {
      updates['university'] = university;
      UserCache.university = university;
    }
    if (faculty != null) {
      updates['faculty'] = faculty;
      UserCache.faculty = faculty;
    }

    if (updates.isNotEmpty) {
      await _firestore.collection(_usersCollection).doc(uid).update(updates);
    }
  }
}
