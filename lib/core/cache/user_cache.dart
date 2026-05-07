import '../models/user_role.dart';

/// In-memory cache for the current user's session data.
/// Populated from Firestore after login via [UserService].
class UserCache {
  static String university = 'Borg Alarab Technological University';
  static String faculty = 'Faculty of Information Technology';
  static UserRole role = UserRole.student;

  static bool get isAdmin => role == UserRole.admin;

  /// Resets all cached values to defaults (used on logout).
  static void clear() {
    university = 'Borg Alarab Technological University';
    faculty = 'Faculty of Information Technology';
    role = UserRole.student;
  }
}
