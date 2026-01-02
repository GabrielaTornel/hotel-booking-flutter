import 'customer.dart';
import 'room.dart';
import 'user.dart';

class Booking {
  final String id;
  final String bookingNumber;
  final Customer customer;
  final Room room;
  final DateTime checkIn;
  final DateTime checkOut;
  final Guests guests;
  final String status;
  final double totalAmount;
  final String paymentStatus;
  final String? paymentMethod;
  final String? specialRequests;
  final String? notes;
  final User? createdBy;
  final String source;
  final DateTime createdAt;
  final DateTime updatedAt;

  Booking({
    required this.id,
    required this.bookingNumber,
    required this.customer,
    required this.room,
    required this.checkIn,
    required this.checkOut,
    required this.guests,
    required this.status,
    required this.totalAmount,
    required this.paymentStatus,
    this.paymentMethod,
    this.specialRequests,
    this.notes,
    this.createdBy,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    print('📦 Parseando Booking desde JSON: ${json['_id'] ?? json['id']}');
    
    // Manejar el caso donde customer o room pueden ser strings (IDs) en lugar de objetos
    Map<String, dynamic> customerData = {};
    if (json['customer'] != null) {
      print('  👤 Customer type: ${json['customer'].runtimeType}');
      if (json['customer'] is Map<String, dynamic>) {
        customerData = json['customer'];
      } else {
        // Si es un string (ID), crear un customer básico
        customerData = {
          'id': json['customer'],
          'firstName': 'Cliente',
          'lastName': 'No disponible',
          'email': 'no-email@example.com',
          'phone': 'N/A'
        };
      }
    }

    Map<String, dynamic> roomData = {};
    if (json['room'] != null) {
      print('  🛏️ Room type: ${json['room'].runtimeType}');
      if (json['room'] is Map<String, dynamic>) {
        roomData = json['room'];
        print('  🛏️ Room data keys: ${roomData.keys.toList()}');
        print('  🛏️ Room isAvailable value: ${roomData['isAvailable']} (type: ${roomData['isAvailable']?.runtimeType})');
        
        // Asegurar que isAvailable existe y es bool
        if (!roomData.containsKey('isAvailable') || roomData['isAvailable'] == null) {
          print('  ⚠️ isAvailable es null o no existe, estableciendo a true');
          roomData['isAvailable'] = true;
        } else if (roomData['isAvailable'] is! bool) {
          print('  ⚠️ isAvailable no es bool, convirtiendo...');
          roomData['isAvailable'] = roomData['isAvailable'].toString().toLowerCase() == 'true';
        }
      } else {
        print('  🛏️ Room es string/ID, creando room básico');
        // Si es un string (ID), crear un room básico
        roomData = {
          'id': json['room'],
          'number': 'N/A',
          'type': 'standard',
          'price': 0.0,
          'isAvailable': true,
          'currency': 'USD',
          'capacity': 1,
          'amenities': [],
          'images': [],
          'floor': 0,
        };
      }
    } else {
      print('  ⚠️ Room es null, creando room básico');
      // Si room es null, crear un room básico
      roomData = {
        'id': '',
        'number': 'N/A',
        'type': 'standard',
        'price': 0.0,
        'isAvailable': true,
        'currency': 'USD',
        'capacity': 1,
        'amenities': [],
        'images': [],
        'floor': 0,
      };
    }
    
    print('  ✅ Room data final - isAvailable: ${roomData['isAvailable']} (type: ${roomData['isAvailable'].runtimeType})');

    Map<String, dynamic>? createdByData;
    if (json['createdBy'] != null) {
      if (json['createdBy'] is Map<String, dynamic>) {
        createdByData = json['createdBy'];
      }
    }

    return Booking(
      id: json['_id'] ?? json['id'] ?? '',
      bookingNumber: json['bookingNumber'] ?? '',
      customer: Customer.fromJson(customerData),
      room: Room.fromJson(roomData),
      checkIn: json['checkIn'] != null 
          ? DateTime.parse(json['checkIn']) 
          : DateTime.now(),
      checkOut: json['checkOut'] != null 
          ? DateTime.parse(json['checkOut']) 
          : DateTime.now(),
      guests: Guests.fromJson(json['guests'] ?? {}),
      status: json['status'] ?? '',
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      paymentStatus: json['paymentStatus'] ?? '',
      paymentMethod: json['paymentMethod'],
      specialRequests: json['specialRequests'],
      notes: json['notes'],
      createdBy: createdByData != null 
          ? User.fromJson(createdByData) 
          : null,
      source: json['source'] ?? '',
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
      'customer': customer.id,
      'room': room.id,
      'checkIn': checkIn.toIso8601String(),
      'checkOut': checkOut.toIso8601String(),
      'guests': guests.toJson(),
      'specialRequests': specialRequests,
      'source': source,
    };
  }

  int get nights {
    return checkOut.difference(checkIn).inDays;
  }

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'confirmed':
        return 'Confirmada';
      case 'checked_in':
        return 'Check-in Realizado';
      case 'checked_out':
        return 'Check-out Realizado';
      case 'cancelled':
        return 'Cancelada';
      case 'no_show':
        return 'No Show';
      default:
        return status;
    }
  }

  String get paymentStatusLabel {
    switch (paymentStatus) {
      case 'pending':
        return 'Pendiente';
      case 'paid':
        return 'Pagado';
      case 'partial':
        return 'Pago Parcial';
      case 'refunded':
        return 'Reembolsado';
      default:
        return paymentStatus;
    }
  }

  String get sourceLabel {
    switch (source) {
      case 'online':
        return 'Online';
      case 'phone':
        return 'Teléfono';
      case 'walk_in':
        return 'Presencial';
      case 'agent':
        return 'Agente';
      default:
        return source;
    }
  }

  Booking copyWith({
    String? id,
    String? bookingNumber,
    Customer? customer,
    Room? room,
    DateTime? checkIn,
    DateTime? checkOut,
    Guests? guests,
    String? status,
    double? totalAmount,
    String? paymentStatus,
    String? paymentMethod,
    String? specialRequests,
    String? notes,
    User? createdBy,
    String? source,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Booking(
      id: id ?? this.id,
      bookingNumber: bookingNumber ?? this.bookingNumber,
      customer: customer ?? this.customer,
      room: room ?? this.room,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      guests: guests ?? this.guests,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      specialRequests: specialRequests ?? this.specialRequests,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class Guests {
  final int adults;
  final int children;

  Guests({
    required this.adults,
    required this.children,
  });

  factory Guests.fromJson(Map<String, dynamic> json) {
    return Guests(
      adults: json['adults'] ?? 1,
      children: json['children'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'adults': adults,
      'children': children,
    };
  }

  int get total => adults + children;
}
