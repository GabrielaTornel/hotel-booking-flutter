import 'package:flutter/foundation.dart';
import '../models/booking.dart';
import '../services/firebase_service.dart';

class BookingProvider with ChangeNotifier {
  List<Booking> _bookings = [];
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _dashboardStats;

  List<Booking> get bookings => _bookings;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get dashboardStats => _dashboardStats;

  Future<void> loadBookings({
    String? status,
    DateTime? checkIn,
    DateTime? checkOut,
    String? customer,
    String? room,
    int page = 1,
    int limit = 10,
  }) async {
    // Evitar cargar si ya está cargando
    if (_isLoading) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _bookings = await ApiService.getBookings(
        status: status,
        checkIn: checkIn,
        checkOut: checkOut,
        customer: customer,
        room: room,
        page: page,
        limit: limit,
      );
    } catch (e) {
      _error = e.toString();
      print('Error cargando reservas: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadDashboardStats() async {
    try {
      final response = await ApiService.getDashboardStats();
      if (response['success']) {
        _dashboardStats = response['data'];
      }
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  Future<Booking?> getBookingById(String id) async {
    try {
      return await ApiService.getBookingById(id);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<Booking?> createBooking(Booking booking) async {
    try {
      final newBooking = await ApiService.createBooking(booking);
      _bookings.insert(0, newBooking);
      notifyListeners();
      return newBooking;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<Booking?> updateBooking(String id, Booking booking) async {
    try {
      final updatedBooking = await ApiService.updateBooking(id, booking);
      final index = _bookings.indexWhere((b) => b.id == id);
      if (index != -1) {
        _bookings[index] = updatedBooking;
        notifyListeners();
      }
      return updatedBooking;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> deleteBooking(String id) async {
    try {
      await ApiService.deleteBooking(id);
      _bookings.removeWhere((b) => b.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<Booking?> checkIn(String id) async {
    try {
      final updatedBooking = await ApiService.checkIn(id);
      final index = _bookings.indexWhere((b) => b.id == id);
      if (index != -1) {
        _bookings[index] = updatedBooking;
        notifyListeners();
      }
      return updatedBooking;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<Booking?> checkOut(String id) async {
    try {
      final updatedBooking = await ApiService.checkOut(id);
      final index = _bookings.indexWhere((b) => b.id == id);
      if (index != -1) {
        _bookings[index] = updatedBooking;
        notifyListeners();
      }
      return updatedBooking;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> checkRoomAvailability(String roomId, DateTime checkIn, DateTime checkOut, {String? excludeBookingId}) async {
    try {
      final response = await ApiService.checkRoomAvailability(roomId, checkIn, checkOut, excludeBookingId: excludeBookingId);
      return response['available'] ?? false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<Booking?> renewBooking(String bookingId, DateTime newCheckOut) async {
    try {
      final updatedBooking = await ApiService.renewBooking(bookingId, newCheckOut);
      final index = _bookings.indexWhere((b) => b.id == bookingId);
      if (index != -1) {
        _bookings[index] = updatedBooking;
        notifyListeners();
      }
      return updatedBooking;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  List<Booking> getBookingsByStatus(String status) {
    return _bookings.where((booking) => booking.status == status).toList();
  }

  List<Booking> getTodayCheckIns() {
    final today = DateTime.now();
    return _bookings.where((booking) {
      return booking.status == 'confirmed' &&
          booking.checkIn.year == today.year &&
          booking.checkIn.month == today.month &&
          booking.checkIn.day == today.day;
    }).toList();
  }

  List<Booking> getTodayCheckOuts() {
    final today = DateTime.now();
    return _bookings.where((booking) {
      return booking.status == 'checked_in' &&
          booking.checkOut.year == today.year &&
          booking.checkOut.month == today.month &&
          booking.checkOut.day == today.day;
    }).toList();
  }

  Future<List<Booking>> getBookingsForCheckIn(String customerName) async {
    try {
      return await ApiService.getBookingsForCheckIn(customerName);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  Future<Booking?> directCheckIn(Booking booking) async {
    try {
      final newBooking = await ApiService.directCheckIn(booking);
      _bookings.insert(0, newBooking);
      notifyListeners();
      return newBooking;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Método para refrescar los datos
  Future<void> refreshBookings() async {
    await loadBookings();
  }
}
