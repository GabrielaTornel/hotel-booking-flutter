import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/room.dart';
import '../models/customer.dart';
import '../models/booking.dart';

/// Servicio de Firebase para reemplazar las llamadas a la API REST
/// Implementa todas las operaciones CRUD necesarias
class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // ==================== UTILIDADES ====================

  static DateTime? _convertTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return null;
    return timestamp.toDate();
  }

  static Timestamp _convertToTimestamp(DateTime date) {
    return Timestamp.fromDate(date);
  }

  // ==================== AUTENTICACIÓN ====================

  /// Iniciar sesión
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print('🔐 Intentando login con Firebase: $email');
      
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw Exception('Error al obtener usuario');
      }

      // Obtener datos adicionales del usuario desde Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.exists ? userDoc.data() : null;

      print('✅ Login exitoso: ${user.uid}');

      return {
        'success': true,
        'data': {
          'token': await user.getIdToken(),
          'user': {
            'id': user.uid,
            'email': user.email,
            ...?userData,
          }
        }
      };
    } catch (e) {
      print('❌ Error en login: $e');
      throw Exception('Error al iniciar sesión: ${e.toString()}');
    }
  }

  /// Obtener perfil del usuario actual
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.exists ? userDoc.data() : null;

      return {
        'success': true,
        'data': {
          'user': {
            'id': user.uid,
            'email': user.email,
            ...?userData,
          }
        }
      };
    } catch (e) {
      throw Exception('Error al obtener perfil: ${e.toString()}');
    }
  }

  /// Cerrar sesión
  static Future<void> logout() async {
    await _auth.signOut();
  }

  // ==================== HABITACIONES (ROOMS) ====================

  /// Obtener todas las habitaciones con filtros opcionales
  static Future<List<Room>> getRooms({
    String? type,
    double? minPrice,
    double? maxPrice,
    bool? available,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      Query query = _firestore.collection('rooms');

      if (type != null) {
        query = query.where('type', isEqualTo: type);
      }
      if (minPrice != null) {
        query = query.where('price', isGreaterThanOrEqualTo: minPrice);
      }
      if (maxPrice != null) {
        query = query.where('price', isLessThanOrEqualTo: maxPrice);
      }
      if (available != null) {
        query = query.where('isAvailable', isEqualTo: available);
      }

      query = query.orderBy('price', descending: false);

      final snapshot = await query.get();
      final rooms = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Room.fromJson({
          '_id': doc.id,
          'id': doc.id,
          ...data,
          'createdAt': _convertTimestamp(data['createdAt'] as Timestamp?)?.toIso8601String(),
          'updatedAt': _convertTimestamp(data['updatedAt'] as Timestamp?)?.toIso8601String(),
        });
      }).toList();

      return rooms;
    } catch (e) {
      print('Error obteniendo habitaciones: $e');
      throw Exception('Error al obtener habitaciones: ${e.toString()}');
    }
  }

  /// Obtener una habitación por ID
  static Future<Room> getRoomById(String id) async {
    try {
      final doc = await _firestore.collection('rooms').doc(id).get();
      
      if (!doc.exists) {
        throw Exception('Habitación no encontrada');
      }

      final data = doc.data()!;
      return Room.fromJson({
        '_id': doc.id,
        'id': doc.id,
        ...data,
        'createdAt': _convertTimestamp(data['createdAt'] as Timestamp?)?.toIso8601String(),
        'updatedAt': _convertTimestamp(data['updatedAt'] as Timestamp?)?.toIso8601String(),
      });
    } catch (e) {
      throw Exception('Error al obtener habitación: ${e.toString()}');
    }
  }

  /// Crear una nueva habitación
  static Future<Room> createRoom(Room room) async {
    try {
      final data = room.toJson();
      // Remover campos que no deben guardarse
      data.remove('_id');
      data.remove('id');
      data.remove('createdAt');
      data.remove('updatedAt');

      final docRef = await _firestore.collection('rooms').add({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return await getRoomById(docRef.id);
    } catch (e) {
      throw Exception('Error al crear habitación: ${e.toString()}');
    }
  }

  /// Actualizar una habitación
  static Future<Room> updateRoom(String id, Room room) async {
    try {
      final data = room.toJson();
      data.remove('_id');
      data.remove('id');
      data.remove('createdAt');
      data.remove('updatedAt');

      await _firestore.collection('rooms').doc(id).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return await getRoomById(id);
    } catch (e) {
      throw Exception('Error al actualizar habitación: ${e.toString()}');
    }
  }

  /// Eliminar una habitación
  static Future<void> deleteRoom(String id) async {
    try {
      await _firestore.collection('rooms').doc(id).delete();
    } catch (e) {
      throw Exception('Error al eliminar habitación: ${e.toString()}');
    }
  }

  /// Verificar disponibilidad de una habitación
  static Future<Map<String, dynamic>> checkRoomAvailability(
    String roomId,
    DateTime checkIn,
    DateTime checkOut, {
    String? excludeBookingId,
  }) async {
    try {
      Query query = _firestore.collection('bookings')
          .where('roomId', isEqualTo: roomId)
          .where('status', whereIn: ['pending', 'confirmed', 'checked_in']);

      final snapshot = await query.get();
      
      final conflictingBookings = snapshot.docs.where((doc) {
        if (excludeBookingId != null && doc.id == excludeBookingId) return false;
        
        final booking = doc.data() as Map<String, dynamic>;
        final bookingCheckIn = _convertTimestamp(booking['checkIn'] as Timestamp?);
        final bookingCheckOut = _convertTimestamp(booking['checkOut'] as Timestamp?);

        if (bookingCheckIn == null || bookingCheckOut == null) return false;

        return (
          (checkIn.isAfter(bookingCheckIn) && checkIn.isBefore(bookingCheckOut)) ||
          (checkOut.isAfter(bookingCheckIn) && checkOut.isBefore(bookingCheckOut)) ||
          (checkIn.isBefore(bookingCheckIn) && checkOut.isAfter(bookingCheckOut))
        );
      }).toList();

      return {
        'available': conflictingBookings.isEmpty,
        'conflictingBookings': conflictingBookings.length,
      };
    } catch (e) {
      throw Exception('Error al verificar disponibilidad: ${e.toString()}');
    }
  }

  // ==================== CLIENTES (CUSTOMERS) ====================

  /// Obtener todos los clientes
  static Future<List<Customer>> getCustomers({
    String? search,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      Query query = _firestore.collection('customers')
          .orderBy('createdAt', descending: true);

      final snapshot = await query.get();
      var customers = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Customer.fromJson({
          '_id': doc.id,
          'id': doc.id,
          ...data,
          'birthDate': _convertTimestamp(data['birthDate'] as Timestamp?)?.toIso8601String(),
          'createdAt': _convertTimestamp(data['createdAt'] as Timestamp?)?.toIso8601String(),
          'updatedAt': _convertTimestamp(data['updatedAt'] as Timestamp?)?.toIso8601String(),
        });
      }).toList();

      // Filtrar por búsqueda si se proporciona
      if (search != null && search.isNotEmpty) {
        final searchLower = search.toLowerCase();
        customers = customers.where((customer) {
          return customer.firstName.toLowerCase().contains(searchLower) ||
                 customer.lastName.toLowerCase().contains(searchLower) ||
                 customer.email.toLowerCase().contains(searchLower) ||
                 customer.documentNumber.contains(search);
        }).toList();
      }

      return customers;
    } catch (e) {
      throw Exception('Error al obtener clientes: ${e.toString()}');
    }
  }

  /// Obtener un cliente por ID
  static Future<Customer> getCustomerById(String id) async {
    try {
      final doc = await _firestore.collection('customers').doc(id).get();
      
      if (!doc.exists) {
        throw Exception('Cliente no encontrado');
      }

      final data = doc.data()!;
      return Customer.fromJson({
        '_id': doc.id,
        'id': doc.id,
        ...data,
        'birthDate': _convertTimestamp(data['birthDate'] as Timestamp?)?.toIso8601String(),
        'createdAt': _convertTimestamp(data['createdAt'] as Timestamp?)?.toIso8601String(),
        'updatedAt': _convertTimestamp(data['updatedAt'] as Timestamp?)?.toIso8601String(),
      });
    } catch (e) {
      throw Exception('Error al obtener cliente: ${e.toString()}');
    }
  }

  /// Crear un nuevo cliente
  static Future<Customer> createCustomer(Customer customer) async {
    try {
      final data = customer.toJson();
      data.remove('_id');
      data.remove('id');
      data.remove('createdAt');
      data.remove('updatedAt');

      if (data['birthDate'] != null) {
        data['birthDate'] = _convertToTimestamp(DateTime.parse(data['birthDate']));
      }

      final docRef = await _firestore.collection('customers').add({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return await getCustomerById(docRef.id);
    } catch (e) {
      throw Exception('Error al crear cliente: ${e.toString()}');
    }
  }

  /// Actualizar un cliente
  static Future<Customer> updateCustomer(String id, Customer customer) async {
    try {
      final data = customer.toJson();
      data.remove('_id');
      data.remove('id');
      data.remove('createdAt');
      data.remove('updatedAt');

      if (data['birthDate'] != null) {
        data['birthDate'] = _convertToTimestamp(DateTime.parse(data['birthDate']));
      }

      await _firestore.collection('customers').doc(id).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return await getCustomerById(id);
    } catch (e) {
      throw Exception('Error al actualizar cliente: ${e.toString()}');
    }
  }

  /// Eliminar un cliente
  static Future<void> deleteCustomer(String id) async {
    try {
      await _firestore.collection('customers').doc(id).delete();
    } catch (e) {
      throw Exception('Error al eliminar cliente: ${e.toString()}');
    }
  }

  /// Buscar cliente por número de documento
  static Future<Customer?> searchCustomerByDocument(String documentNumber) async {
    try {
      final snapshot = await _firestore.collection('customers')
          .where('documentNumber', isEqualTo: documentNumber)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      final doc = snapshot.docs.first;
      final data = doc.data();
      return Customer.fromJson({
        '_id': doc.id,
        'id': doc.id,
        ...data,
        'birthDate': _convertTimestamp(data['birthDate'] as Timestamp?)?.toIso8601String(),
        'createdAt': _convertTimestamp(data['createdAt'] as Timestamp?)?.toIso8601String(),
        'updatedAt': _convertTimestamp(data['updatedAt'] as Timestamp?)?.toIso8601String(),
      });
    } catch (e) {
      throw Exception('Error al buscar cliente: ${e.toString()}');
    }
  }

  // ==================== RESERVAS (BOOKINGS) ====================

  /// Obtener todas las reservas
  static Future<List<Booking>> getBookings({
    String? status,
    DateTime? checkIn,
    DateTime? checkOut,
    String? customer,
    String? room,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      Query query = _firestore.collection('bookings');

      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }
      if (customer != null) {
        query = query.where('customerId', isEqualTo: customer);
      }
      if (room != null) {
        query = query.where('roomId', isEqualTo: room);
      }

      query = query.orderBy('createdAt', descending: true);

      final snapshot = await query.get();
      print('📋 Obtenidas ${snapshot.docs.length} reservas de Firestore');
      final bookings = <Booking>[];
      
      for (final doc in snapshot.docs) {
        try {
          print('\n🔄 Procesando reserva: ${doc.id}');
          final data = doc.data() as Map<String, dynamic>;
          print('  📊 Data keys: ${data.keys.toList()}');
          
          // Asegurar que room tenga isAvailable si viene como objeto
          if (data['room'] != null) {
            print('  🛏️ Room presente, tipo: ${data['room'].runtimeType}');
            if (data['room'] is Map<String, dynamic>) {
              final roomData = data['room'] as Map<String, dynamic>;
              print('  🛏️ Room es objeto, keys: ${roomData.keys.toList()}');
              print('  🛏️ Room isAvailable: ${roomData['isAvailable']} (type: ${roomData['isAvailable']?.runtimeType})');
              
              if (!roomData.containsKey('isAvailable') || roomData['isAvailable'] == null) {
                print('  ⚠️ Room isAvailable es null, estableciendo a true');
                roomData['isAvailable'] = true;
              } else if (roomData['isAvailable'] is! bool) {
                print('  ⚠️ Room isAvailable no es bool, convirtiendo...');
                roomData['isAvailable'] = roomData['isAvailable'].toString().toLowerCase() == 'true';
              }
            } else {
              print('  🛏️ Room es ${data['room'].runtimeType}, será manejado en Booking.fromJson');
            }
          } else {
            print('  ⚠️ Room es null en Firestore');
          }
          
          final booking = Booking.fromJson({
            '_id': doc.id,
            'id': doc.id,
            ...data,
            'checkIn': _convertTimestamp(data['checkIn'] as Timestamp?)?.toIso8601String(),
            'checkOut': _convertTimestamp(data['checkOut'] as Timestamp?)?.toIso8601String(),
            'createdAt': _convertTimestamp(data['createdAt'] as Timestamp?)?.toIso8601String(),
            'updatedAt': _convertTimestamp(data['updatedAt'] as Timestamp?)?.toIso8601String(),
          });
          
          print('  ✅ Reserva parseada exitosamente');
          bookings.add(booking);
        } catch (e, stackTrace) {
          print('❌ Error parseando reserva ${doc.id}: $e');
          print('Stack trace: $stackTrace');
          // Continuar con la siguiente reserva en lugar de fallar completamente
        }
      }
      
      print('\n✅ Total de reservas parseadas: ${bookings.length}');

      return bookings;
    } catch (e) {
      throw Exception('Error al obtener reservas: ${e.toString()}');
    }
  }

  /// Obtener una reserva por ID
  static Future<Booking> getBookingById(String id) async {
    try {
      final doc = await _firestore.collection('bookings').doc(id).get();
      
      if (!doc.exists) {
        throw Exception('Reserva no encontrada');
      }

      final data = doc.data()!;
      return Booking.fromJson({
        '_id': doc.id,
        'id': doc.id,
        ...data,
        'checkIn': _convertTimestamp(data['checkIn'] as Timestamp?)?.toIso8601String(),
        'checkOut': _convertTimestamp(data['checkOut'] as Timestamp?)?.toIso8601String(),
        'createdAt': _convertTimestamp(data['createdAt'] as Timestamp?)?.toIso8601String(),
        'updatedAt': _convertTimestamp(data['updatedAt'] as Timestamp?)?.toIso8601String(),
      });
    } catch (e) {
      throw Exception('Error al obtener reserva: ${e.toString()}');
    }
  }

  /// Crear una nueva reserva
  static Future<Booking> createBooking(Booking booking) async {
    try {
      // Generar número de reserva
      final bookingsSnapshot = await _firestore.collection('bookings').get();
      final bookingNumber = 'HB${(bookingsSnapshot.docs.length + 1).toString().padLeft(6, '0')}';

      final data = booking.toJson();
      data.remove('_id');
      data.remove('id');
      data.remove('bookingNumber');
      data.remove('createdAt');
      data.remove('updatedAt');

      if (data['checkIn'] != null) {
        data['checkIn'] = _convertToTimestamp(DateTime.parse(data['checkIn']));
      }
      if (data['checkOut'] != null) {
        data['checkOut'] = _convertToTimestamp(DateTime.parse(data['checkOut']));
      }

      final docRef = await _firestore.collection('bookings').add({
        ...data,
        'bookingNumber': bookingNumber,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return await getBookingById(docRef.id);
    } catch (e) {
      throw Exception('Error al crear reserva: ${e.toString()}');
    }
  }

  /// Actualizar una reserva
  static Future<Booking> updateBooking(String id, Booking booking) async {
    try {
      final data = booking.toJson();
      data.remove('_id');
      data.remove('id');
      data.remove('createdAt');
      data.remove('updatedAt');

      if (data['checkIn'] != null) {
        data['checkIn'] = _convertToTimestamp(DateTime.parse(data['checkIn']));
      }
      if (data['checkOut'] != null) {
        data['checkOut'] = _convertToTimestamp(DateTime.parse(data['checkOut']));
      }

      await _firestore.collection('bookings').doc(id).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return await getBookingById(id);
    } catch (e) {
      throw Exception('Error al actualizar reserva: ${e.toString()}');
    }
  }

  /// Eliminar una reserva
  static Future<void> deleteBooking(String id) async {
    try {
      await _firestore.collection('bookings').doc(id).delete();
    } catch (e) {
      throw Exception('Error al eliminar reserva: ${e.toString()}');
    }
  }

  /// Check-in de una reserva
  static Future<Booking> checkIn(String id) async {
    try {
      await _firestore.collection('bookings').doc(id).update({
        'status': 'checked_in',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return await getBookingById(id);
    } catch (e) {
      throw Exception('Error al hacer check-in: ${e.toString()}');
    }
  }

  /// Check-out de una reserva
  static Future<Booking> checkOut(String id) async {
    try {
      await _firestore.collection('bookings').doc(id).update({
        'status': 'checked_out',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return await getBookingById(id);
    } catch (e) {
      throw Exception('Error al hacer check-out: ${e.toString()}');
    }
  }

  /// Renovar una reserva (extender fecha de check-out)
  static Future<Booking> renewBooking(String bookingId, DateTime newCheckOut) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'checkOut': _convertToTimestamp(newCheckOut),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return await getBookingById(bookingId);
    } catch (e) {
      throw Exception('Error al renovar reserva: ${e.toString()}');
    }
  }

  /// Obtener reservas disponibles para check-in por nombre de cliente
  static Future<List<Booking>> getBookingsForCheckIn(String customerName) async {
    try {
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      // Buscar clientes por nombre
      final customersSnapshot = await _firestore.collection('customers')
          .where('firstName', isGreaterThanOrEqualTo: customerName)
          .where('firstName', isLessThan: customerName + '\uf8ff')
          .get();

      if (customersSnapshot.docs.isEmpty) {
        return [];
      }

      final customerIds = customersSnapshot.docs.map((doc) => doc.id).toList();

      // Buscar reservas de esos clientes que estén confirmadas y con check-in hoy
      final bookingsSnapshot = await _firestore.collection('bookings')
          .where('customerId', whereIn: customerIds)
          .where('status', isEqualTo: 'confirmed')
          .where('checkIn', isGreaterThanOrEqualTo: _convertToTimestamp(todayStart))
          .where('checkIn', isLessThan: _convertToTimestamp(todayEnd))
          .get();

      return bookingsSnapshot.docs.map((doc) {
        final data = doc.data();
        return Booking.fromJson({
          '_id': doc.id,
          'id': doc.id,
          ...data,
          'checkIn': _convertTimestamp(data['checkIn'] as Timestamp?)?.toIso8601String(),
          'checkOut': _convertTimestamp(data['checkOut'] as Timestamp?)?.toIso8601String(),
          'createdAt': _convertTimestamp(data['createdAt'] as Timestamp?)?.toIso8601String(),
          'updatedAt': _convertTimestamp(data['updatedAt'] as Timestamp?)?.toIso8601String(),
        });
      }).toList();
    } catch (e) {
      throw Exception('Error al obtener reservas para check-in: ${e.toString()}');
    }
  }

  /// Check-in directo (crear reserva y hacer check-in inmediatamente)
  static Future<Booking> directCheckIn(Booking booking) async {
    try {
      // Crear la reserva
      final newBooking = await createBooking(booking);
      
      // Hacer check-in inmediatamente
      await _firestore.collection('bookings').doc(newBooking.id).update({
        'status': 'checked_in',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      return await getBookingById(newBooking.id);
    } catch (e) {
      throw Exception('Error al hacer check-in directo: ${e.toString()}');
    }
  }

  /// Obtener estadísticas del dashboard
  static Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      print('📊 Obteniendo estadísticas del dashboard...');
      final bookingsSnapshot = await _firestore.collection('bookings').get();
      final roomsSnapshot = await _firestore.collection('rooms').get();
      final customersSnapshot = await _firestore.collection('customers').get();

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      int totalBookings = bookingsSnapshot.docs.length;
      int pendingBookings = 0;
      int confirmedBookings = 0;
      int checkedInBookings = 0;
      int todayCheckIns = 0;
      int todayCheckOuts = 0;
      int todayBookings = 0;
      int pendingCheckIns = 0;

      for (var doc in bookingsSnapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String?;
        
        if (status == 'pending') pendingBookings++;
        if (status == 'confirmed') {
          confirmedBookings++;
          pendingCheckIns++;
        }
        if (status == 'checked_in') checkedInBookings++;

        final checkIn = _convertTimestamp(data['checkIn'] as Timestamp?);
        final checkOut = _convertTimestamp(data['checkOut'] as Timestamp?);
        final createdAt = _convertTimestamp(data['createdAt'] as Timestamp?);

        if (checkIn != null) {
          final checkInDate = DateTime(checkIn.year, checkIn.month, checkIn.day);
          if (checkInDate.isAtSameMomentAs(today)) {
            todayCheckIns++;
          }
        }

        if (checkOut != null) {
          final checkOutDate = DateTime(checkOut.year, checkOut.month, checkOut.day);
          if (checkOutDate.isAtSameMomentAs(today)) {
            todayCheckOuts++;
          }
        }

        if (createdAt != null) {
          final createdDate = DateTime(createdAt.year, createdAt.month, createdAt.day);
          if (createdDate.isAtSameMomentAs(today)) {
            todayBookings++;
          }
        }
      }

      // Calcular habitaciones disponibles y ocupadas
      int availableRooms = 0;
      int occupiedRooms = 0;
      
      for (var doc in roomsSnapshot.docs) {
        try {
          final data = doc.data();
          // Manejar isAvailable de forma segura
          bool isAvailable = true;
          if (data['isAvailable'] != null) {
            if (data['isAvailable'] is bool) {
              isAvailable = data['isAvailable'] as bool;
            } else if (data['isAvailable'] is String) {
              isAvailable = data['isAvailable'].toString().toLowerCase() == 'true';
            }
          }
          
          if (isAvailable) {
            availableRooms++;
          } else {
            occupiedRooms++;
          }
        } catch (e) {
          print('⚠️ Error procesando habitación ${doc.id}: $e');
          // Si hay error, asumir disponible
          availableRooms++;
        }
      }

      print('📊 Estadísticas calculadas:');
      print('  - Total reservas: $totalBookings');
      print('  - Reservas hoy: $todayBookings');
      print('  - Check-ins pendientes: $pendingCheckIns');
      print('  - Habitaciones disponibles: $availableRooms');
      print('  - Habitaciones ocupadas: $occupiedRooms');

      return {
        'totalBookings': totalBookings,
        'pendingBookings': pendingBookings,
        'confirmedBookings': confirmedBookings,
        'checkedInBookings': checkedInBookings,
        'todayCheckIns': todayCheckIns,
        'todayCheckOuts': todayCheckOuts,
        'todayBookings': todayBookings,
        'pendingCheckIns': pendingCheckIns,
        'availableRooms': availableRooms,
        'occupiedRooms': occupiedRooms,
        'totalRooms': roomsSnapshot.docs.length,
        'totalCustomers': customersSnapshot.docs.length,
      };
    } catch (e, stackTrace) {
      print('❌ Error al obtener estadísticas: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Error al obtener estadísticas: ${e.toString()}');
    }
  }

  // ==================== PAÍSES Y DEPARTAMENTOS ====================

  /// Obtener países
  static Future<Map<String, dynamic>> getCountries({String? search}) async {
    try {
      Query query = _firestore.collection('countries').orderBy('name', descending: false);
      final snapshot = await query.get();
      
      var countries = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return <String, dynamic>{
          'id': doc.id,
          '_id': doc.id,
          ...data,
        };
      }).toList();

      if (search != null && search.isNotEmpty) {
        final searchLower = search.toLowerCase();
        countries = countries.where((country) {
          final name = country['name'] as String?;
          final code = country['code'] as String?;
          return (name != null && name.toLowerCase().contains(searchLower)) ||
                 (code != null && code.toLowerCase().contains(searchLower));
        }).toList();
      }

      return {
        'success': true,
        'data': {
          'countries': countries,
          'total': countries.length,
        }
      };
    } catch (e) {
      throw Exception('Error al obtener países: ${e.toString()}');
    }
  }

  /// Obtener departamentos
  static Future<Map<String, dynamic>> getDepartments({String? search}) async {
    try {
      Query query = _firestore.collection('departments').orderBy('name', descending: false);
      final snapshot = await query.get();
      
      var departments = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return <String, dynamic>{
          'id': doc.id,
          '_id': doc.id,
          ...data,
        };
      }).toList();

      if (search != null && search.isNotEmpty) {
        final searchLower = search.toLowerCase();
        departments = departments.where((dept) {
          final name = dept['name'] as String?;
          final code = dept['code'] as String?;
          return (name != null && name.toLowerCase().contains(searchLower)) ||
                 (code != null && code.toLowerCase().contains(searchLower));
        }).toList();
      }

      return {
        'success': true,
        'data': {
          'departments': departments,
          'total': departments.length,
        }
      };
    } catch (e) {
      throw Exception('Error al obtener departamentos: ${e.toString()}');
    }
  }

  /// Obtener nacionalidades
  static Future<Map<String, dynamic>> getNationalities({String? search}) async {
    try {
      Query query = _firestore.collection('nationalities').orderBy('name', descending: false);
      final snapshot = await query.get();
      
      var nationalities = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return <String, dynamic>{
          'id': doc.id,
          '_id': doc.id,
          ...data,
        };
      }).toList();

      if (search != null && search.isNotEmpty) {
        final searchLower = search.toLowerCase();
        nationalities = nationalities.where((nat) {
          final name = nat['name'] as String?;
          final code = nat['code'] as String?;
          return (name != null && name.toLowerCase().contains(searchLower)) ||
                 (code != null && code.toLowerCase().contains(searchLower));
        }).toList();
      }

      return {
        'success': true,
        'data': {
          'nationalities': nationalities,
          'total': nationalities.length,
        }
      };
    } catch (e) {
      throw Exception('Error al obtener nacionalidades: ${e.toString()}');
    }
  }
}

// Alias para compatibilidad con el código existente
class ApiService {
  static Future<Map<String, dynamic>> login(String email, String password) => 
      FirebaseService.login(email, password);
  
  static Future<Map<String, dynamic>> getProfile() => 
      FirebaseService.getProfile();
  
  static Future<void> logout() => 
      FirebaseService.logout();
  
  static Future<List<Room>> getRooms({
    String? type,
    double? minPrice,
    double? maxPrice,
    bool? available,
    int page = 1,
    int limit = 10,
  }) => FirebaseService.getRooms(
    type: type,
    minPrice: minPrice,
    maxPrice: maxPrice,
    available: available,
    page: page,
    limit: limit,
  );
  
  static Future<Room> getRoomById(String id) => 
      FirebaseService.getRoomById(id);
  
  static Future<Room> createRoom(Room room) => 
      FirebaseService.createRoom(room);
  
  static Future<Room> updateRoom(String id, Room room) => 
      FirebaseService.updateRoom(id, room);
  
  static Future<void> deleteRoom(String id) => 
      FirebaseService.deleteRoom(id);
  
  static Future<List<Customer>> getCustomers({
    String? search,
    int page = 1,
    int limit = 10,
  }) => FirebaseService.getCustomers(
    search: search,
    page: page,
    limit: limit,
  );
  
  static Future<Customer> getCustomerById(String id) => 
      FirebaseService.getCustomerById(id);
  
  static Future<Customer> createCustomer(Customer customer) => 
      FirebaseService.createCustomer(customer);
  
  static Future<Customer> updateCustomer(String id, Customer customer) => 
      FirebaseService.updateCustomer(id, customer);
  
  static Future<void> deleteCustomer(String id) => 
      FirebaseService.deleteCustomer(id);
  
  static Future<Customer?> searchCustomerByDocument(String documentNumber) => 
      FirebaseService.searchCustomerByDocument(documentNumber);
  
  static Future<List<Booking>> getBookings({
    String? status,
    DateTime? checkIn,
    DateTime? checkOut,
    String? customer,
    String? room,
    int page = 1,
    int limit = 10,
  }) => FirebaseService.getBookings(
    status: status,
    checkIn: checkIn,
    checkOut: checkOut,
    customer: customer,
    room: room,
    page: page,
    limit: limit,
  );
  
  static Future<Booking> getBookingById(String id) => 
      FirebaseService.getBookingById(id);
  
  static Future<Booking> createBooking(Booking booking) => 
      FirebaseService.createBooking(booking);
  
  static Future<Booking> updateBooking(String id, Booking booking) => 
      FirebaseService.updateBooking(id, booking);
  
  static Future<void> deleteBooking(String id) => 
      FirebaseService.deleteBooking(id);
  
  static Future<Booking> checkIn(String id) => 
      FirebaseService.checkIn(id);
  
  static Future<Booking> checkOut(String id) => 
      FirebaseService.checkOut(id);
  
  static Future<Booking> renewBooking(String bookingId, DateTime newCheckOut) => 
      FirebaseService.renewBooking(bookingId, newCheckOut);
  
  static Future<List<Booking>> getBookingsForCheckIn(String customerName) => 
      FirebaseService.getBookingsForCheckIn(customerName);
  
  static Future<Booking> directCheckIn(Booking booking) => 
      FirebaseService.directCheckIn(booking);
  
  static Future<Map<String, dynamic>> getDashboardStats() => 
      FirebaseService.getDashboardStats();
  
  static Future<Map<String, dynamic>> checkRoomAvailability(
    String roomId,
    DateTime checkIn,
    DateTime checkOut, {
    String? excludeBookingId,
  }) => FirebaseService.checkRoomAvailability(
    roomId,
    checkIn,
    checkOut,
    excludeBookingId: excludeBookingId,
  );
  
  static Future<Map<String, dynamic>> getCountries({String? search}) => 
      FirebaseService.getCountries(search: search);
  
  static Future<Map<String, dynamic>> getDepartments({String? search}) => 
      FirebaseService.getDepartments(search: search);
  
  static Future<Map<String, dynamic>> getNationalities({String? search}) => 
      FirebaseService.getNationalities(search: search);
}

