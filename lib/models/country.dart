class Country {
  final String id;
  final String name;
  final String code;
  final bool isActive;

  Country({
    required this.id,
    required this.name,
    required this.code,
    required this.isActive,
  });

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'isActive': isActive,
    };
  }
}
