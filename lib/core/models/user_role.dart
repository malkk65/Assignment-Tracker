/// Defines the possible roles a user can have in the application.
enum UserRole {
  student,
  admin;

  /// Display name for UI purposes.
  String get displayName {
    switch (this) {
      case UserRole.student:
        return 'Student';
      case UserRole.admin:
        return 'Admin';
    }
  }

  /// Icon associated with the role.
  String get icon {
    switch (this) {
      case UserRole.student:
        return '🎓';
      case UserRole.admin:
        return '🛡️';
    }
  }

  /// Converts a string from Firestore to a UserRole.
  static UserRole fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.student;
    }
  }

  /// Converts the role to a string for Firestore storage.
  String toFirestore() => name;
}
