class User {
  final String id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final List<String> permissions;
  final bool isActive;
  final DateTime? lastLogin;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.permissions,
    required this.isActive,
    this.lastLogin,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      role: json['role'] ?? '',
      permissions: List<String>.from(json['permissions'] ?? []),
      isActive: json['isActive'] ?? true,
      lastLogin: json['lastLogin'] != null 
          ? DateTime.parse(json['lastLogin']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'role': role,
      'permissions': permissions,
      'isActive': isActive,
      'lastLogin': lastLogin?.toIso8601String(),
    };
  }

  String get fullName => '$firstName $lastName';

  bool hasPermission(String permission) {
    return permissions.contains(permission) || role == 'admin';
  }
}
