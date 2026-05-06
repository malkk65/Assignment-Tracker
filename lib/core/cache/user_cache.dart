class UserCache {
  static String university = 'Borg Alarab Technological University';
  static String faculty = 'Faculty of Information Technology';
  static String role = 'Student'; // Can be 'Student' or 'Admin'
  static bool get isAdmin => role == 'Admin';
}
