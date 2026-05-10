/// Centralized string constants used across the application.
///
/// Keeps all user-facing text in one place for easy maintenance
/// and future localization support.
class AppStrings {
  AppStrings._();

  // ── App ──
  static const String appName = 'Assignment Tracker';
  static const String appTagline = 'Simplify Your Studies';
  static const String brandName = 'Academic Editorial';
  static const String brandTag = 'THE CURATED SCHOLAR';

  // ── Auth ──
  static const String welcomeBack = 'Welcome\nBack';
  static const String loginSubtitle = 'Please enter your credentials to access your dashboard.';
  static const String signIn = 'Sign In';
  static const String signUp = 'Sign Up';
  static const String createAccount = 'Create Account';
  static const String forgotPassword = 'Forgot password?';
  static const String sendResetLink = 'Send Reset Link';
  static const String staySignedIn = 'Stay signed in';
  static const String dontHaveAccount = "Don't have an account? ";
  static const String alreadyMember = 'Already a member? ';

  // ── Fields ──
  static const String email = 'Email Address';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String fullName = 'Full Name';

  // ── Nav ──
  static const String dashboard = 'Dashboard';
  static const String assignments = 'Assignments';
  static const String chat = 'Chat';
  static const String profile = 'Profile';

  // ── Common Actions ──
  static const String save = 'Save';
  static const String cancel = 'Cancel';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String logout = 'Logout';
  static const String settings = 'Settings';

  // ── Empty States ──
  static const String noAssignments = 'No assignments found';
  static const String noNotifications = 'No notifications yet';
  static const String allCaughtUp = 'All caught up! 🎉';
  static const String chatComingSoon = 'Chat Coming Soon';

  // ── Assignment ──
  static const String addTask = 'Add Task';
  static const String searchAssignments = 'Search for assignments...';
  static const String assignmentDetail = 'Assignment Detail';
  static const String uploadAnswer = 'Upload Your Answer';
  static const String submitPdf = 'Submit PDF';
  static const String pdfOnly = 'PDF format only';
}
