class Customer {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String documentType;
  final String documentNumber;
  final String nationality;
  final DateTime birthDate;
  final Address? address;
  final Preferences? preferences;
  final BillingInfo? billingInfo;
  final ParkingInfo? parkingInfo;
  final String? travelPurpose;
  final String gender;
  final OriginInfo? originInfo;
  final List<Companion> companions;
  final int loyaltyPoints;
  final DateTime createdAt;
  final DateTime updatedAt;

  Customer({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.documentType,
    required this.documentNumber,
    required this.nationality,
    required this.birthDate,
    this.address,
    this.preferences,
    this.billingInfo,
    this.parkingInfo,
    this.travelPurpose,
    this.gender = 'prefer_not_to_say',
    this.originInfo,
    this.companions = const [],
    required this.loyaltyPoints,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['_id'] ?? json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      documentType: json['documentType'] ?? '',
      documentNumber: json['documentNumber'] ?? '',
      nationality: json['nationality'] ?? '',
      birthDate: json['birthDate'] != null 
          ? DateTime.parse(json['birthDate']) 
          : DateTime.now(),
      address: json['address'] != null 
          ? Address.fromJson(json['address']) 
          : null,
      preferences: json['preferences'] != null 
          ? Preferences.fromJson(json['preferences']) 
          : null,
      billingInfo: json['billingInfo'] != null 
          ? BillingInfo.fromJson(json['billingInfo']) 
          : null,
      parkingInfo: json['parkingInfo'] != null 
          ? ParkingInfo.fromJson(json['parkingInfo']) 
          : null,
      travelPurpose: json['travelPurpose'],
      gender: json['gender'] ?? 'prefer_not_to_say',
      originInfo: json['originInfo'] != null 
          ? OriginInfo.fromJson(json['originInfo']) 
          : null,
      companions: json['companions'] != null 
          ? (json['companions'] as List).map((c) => Companion.fromJson(c)).toList()
          : [],
      loyaltyPoints: json['loyaltyPoints'] ?? 0,
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
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'documentType': documentType,
      'documentNumber': documentNumber,
      'nationality': nationality,
      'birthDate': birthDate.toIso8601String(),
      'address': address?.toJson(),
      'preferences': preferences?.toJson(),
      'billingInfo': billingInfo?.toJson(),
      'parkingInfo': parkingInfo?.toJson(),
      'travelPurpose': travelPurpose,
      'gender': gender,
      'originInfo': originInfo?.toJson(),
      'companions': companions.map((c) => c.toJson()).toList(),
    };
  }

  String get fullName => '$firstName $lastName';

  String get documentTypeLabel {
    switch (documentType) {
      case 'passport':
        return 'Pasaporte';
      case 'dni':
        return 'DNI';
      case 'ce':
        return 'CE';
      case 'ruc':
        return 'RUC';
      default:
        return documentType;
    }
  }
}

class Address {
  final String? street;
  final String? city;
  final String? country;
  final String? postalCode;

  Address({
    this.street,
    this.city,
    this.country,
    this.postalCode,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      street: json['street'],
      city: json['city'],
      country: json['country'],
      postalCode: json['postalCode'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'street': street,
      'city': city,
      'country': country,
      'postalCode': postalCode,
    };
  }
}

class Preferences {
  final bool smoking;
  final String? specialRequests;

  Preferences({
    required this.smoking,
    this.specialRequests,
  });

  factory Preferences.fromJson(Map<String, dynamic> json) {
    // Manejar smoking de forma segura
    bool smokingValue = false;
    if (json['smoking'] != null) {
      if (json['smoking'] is bool) {
        smokingValue = json['smoking'] as bool;
      } else if (json['smoking'] is String) {
        smokingValue = json['smoking'].toString().toLowerCase() == 'true';
      }
    }
    
    return Preferences(
      smoking: smokingValue,
      specialRequests: json['specialRequests'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'smoking': smoking,
      'specialRequests': specialRequests,
    };
  }
}

class BillingInfo {
  final bool requiresInvoice;
  final bool requiresReceipt;
  final String? ruc;
  final String? businessName;

  BillingInfo({
    this.requiresInvoice = false,
    this.requiresReceipt = false,
    this.ruc,
    this.businessName,
  });

  factory BillingInfo.fromJson(Map<String, dynamic> json) {
    // Manejar campos booleanos de forma segura
    bool invoiceValue = false;
    if (json['requiresInvoice'] != null) {
      if (json['requiresInvoice'] is bool) {
        invoiceValue = json['requiresInvoice'] as bool;
      } else if (json['requiresInvoice'] is String) {
        invoiceValue = json['requiresInvoice'].toString().toLowerCase() == 'true';
      }
    }
    
    bool receiptValue = false;
    if (json['requiresReceipt'] != null) {
      if (json['requiresReceipt'] is bool) {
        receiptValue = json['requiresReceipt'] as bool;
      } else if (json['requiresReceipt'] is String) {
        receiptValue = json['requiresReceipt'].toString().toLowerCase() == 'true';
      }
    }
    
    return BillingInfo(
      requiresInvoice: invoiceValue,
      requiresReceipt: receiptValue,
      ruc: json['ruc'],
      businessName: json['businessName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'requiresInvoice': requiresInvoice,
      'requiresReceipt': requiresReceipt,
      'ruc': ruc,
      'businessName': businessName,
    };
  }
}

class ParkingInfo {
  final bool requiresParking;
  final String? licensePlate;

  ParkingInfo({
    this.requiresParking = false,
    this.licensePlate,
  });

  factory ParkingInfo.fromJson(Map<String, dynamic> json) {
    // Manejar requiresParking de forma segura
    bool parkingValue = false;
    if (json['requiresParking'] != null) {
      if (json['requiresParking'] is bool) {
        parkingValue = json['requiresParking'] as bool;
      } else if (json['requiresParking'] is String) {
        parkingValue = json['requiresParking'].toString().toLowerCase() == 'true';
      }
    }
    
    return ParkingInfo(
      requiresParking: parkingValue,
      licensePlate: json['licensePlate'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'requiresParking': requiresParking,
      'licensePlate': licensePlate,
    };
  }
}

class OriginInfo {
  final String? country;
  final String? department;

  OriginInfo({
    this.country,
    this.department,
  });

  factory OriginInfo.fromJson(Map<String, dynamic> json) {
    return OriginInfo(
      country: json['country'],
      department: json['department'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'country': country,
      'department': department,
    };
  }
}

class Companion {
  final String documentType;
  final String documentNumber;
  final DateTime birthDate;
  final String gender;
  final String nationality;

  Companion({
    required this.documentType,
    required this.documentNumber,
    required this.birthDate,
    required this.gender,
    required this.nationality,
  });

  factory Companion.fromJson(Map<String, dynamic> json) {
    return Companion(
      documentType: json['documentType'] ?? '',
      documentNumber: json['documentNumber'] ?? '',
      birthDate: json['birthDate'] != null 
          ? DateTime.parse(json['birthDate']) 
          : DateTime.now(),
      gender: json['gender'] ?? 'prefer_not_to_say',
      nationality: json['nationality'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'documentType': documentType,
      'documentNumber': documentNumber,
      'birthDate': birthDate.toIso8601String(),
      'gender': gender,
      'nationality': nationality,
    };
  }
}
