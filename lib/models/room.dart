class Room {
  final String id;
  final String number;
  final String type;
  final double price;
  final String currency; // USD o SOL
  final int capacity;
  final List<String> amenities;
  final List<String> images;
  final bool isAvailable;
  final String? description;
  final int floor;
  final DateTime createdAt;
  final DateTime updatedAt;

  Room({
    required this.id,
    required this.number,
    required this.type,
    required this.price,
    required this.currency,
    required this.capacity,
    required this.amenities,
    required this.images,
    required this.isAvailable,
    this.description,
    required this.floor,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['_id'] ?? json['id'] ?? '',
      number: json['number'] ?? '',
      type: json['type'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'USD',
      capacity: json['capacity'] ?? 0,
      amenities: List<String>.from(json['amenities'] ?? []),
      images: List<String>.from(json['images'] ?? []),
      isAvailable: json['isAvailable'] ?? true,
      description: json['description'],
      floor: json['floor'] ?? 0,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'type': type,
      'price': price,
      'currency': currency,
      'capacity': capacity,
      'amenities': amenities,
      'images': images,
      'isAvailable': isAvailable,
      'description': description,
      'floor': floor,
    };
  }

  String get typeLabel {
    switch (type) {
      case 'single':
        return 'Individual';
      case 'double':
        return 'Doble';
      case 'suite':
        return 'Suite';
      case 'family':
        return 'Familiar';
      default:
        return type;
    }
  }

  String get currencySymbol {
    switch (currency) {
      case 'USD':
        return '\$';
      case 'SOL':
        return 'S/';
      default:
        return '\$';
    }
  }

  String get formattedPrice {
    return '$currencySymbol${price.toStringAsFixed(2)}';
  }

  Room copyWith({
    String? id,
    String? number,
    String? type,
    double? price,
    String? currency,
    int? capacity,
    List<String>? amenities,
    List<String>? images,
    bool? isAvailable,
    String? description,
    int? floor,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Room(
      id: id ?? this.id,
      number: number ?? this.number,
      type: type ?? this.type,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      capacity: capacity ?? this.capacity,
      amenities: amenities ?? this.amenities,
      images: images ?? this.images,
      isAvailable: isAvailable ?? this.isAvailable,
      description: description ?? this.description,
      floor: floor ?? this.floor,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
