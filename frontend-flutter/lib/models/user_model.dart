class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String role;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      // Backend MongoDB trả về _id, nhưng ta map sang id
      id: json['_id'] ?? json['id'] ?? '',
      name: json['fullName'] ?? 'Người dùng',
      email: json['username'] ?? '',
      phone: json['phone'],
      role: json['role'] ?? 'user',
    );
  }
}
