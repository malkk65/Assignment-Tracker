// TODO: Add http or dio package to pubspec.yaml

class ApiService {
  // Base URL
  static const String baseUrl = 'https://your-api.com/api';

  // Auth
  Future<Map<String, dynamic>> login(String email, String password) async {
    // TODO: Implement API call
    throw UnimplementedError();
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    // TODO: Implement API call
    throw UnimplementedError();
  }

  Future<void> forgotPassword(String email) async {
    // TODO: Implement API call
    throw UnimplementedError();
  }

  // Assignments
  Future<List<Map<String, dynamic>>> getAssignments() async {
    // TODO: Implement API call
    throw UnimplementedError();
  }

  Future<Map<String, dynamic>> createAssignment(Map<String, dynamic> data) async {
    // TODO: Implement API call
    throw UnimplementedError();
  }

  Future<void> updateAssignment(String id, Map<String, dynamic> data) async {
    // TODO: Implement API call
    throw UnimplementedError();
  }

  Future<void> deleteAssignment(String id) async {
    // TODO: Implement API call
    throw UnimplementedError();
  }

  // Chat
  Future<List<Map<String, dynamic>>> getMessages(String chatRoomId) async {
    // TODO: Implement API call
    throw UnimplementedError();
  }

  Future<void> sendMessage(Map<String, dynamic> data) async {
    // TODO: Implement API call
    throw UnimplementedError();
  }
}
