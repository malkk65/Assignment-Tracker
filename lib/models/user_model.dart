class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String university;
  final String faculty;
  final String specialization;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.university,
    required this.faculty,
    required this.specialization,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      university: json['university'] ?? '',
      faculty: json['faculty'] ?? '',
      specialization: json['specialization'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'university': university,
      'faculty': faculty,
      'specialization': specialization,
    };
  }
}
