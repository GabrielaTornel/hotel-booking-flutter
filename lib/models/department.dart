class Department {
  final String id;
  final String name;
  final String code;
  final String country;
  final bool isActive;

  Department({
    required this.id,
    required this.name,
    required this.code,
    required this.country,
    required this.isActive,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      country: json['country'] ?? '',
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'country': country,
      'isActive': isActive,
    };
  }
}
