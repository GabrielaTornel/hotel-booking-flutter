import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/room.dart';
import '../models/customer.dart';
import '../models/booking.dart';
import '../models/country.dart';
import '../models/department.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';
  static const String _tokenKey = 'auth_token';

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> _removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    if (response.statusCode == 401) {
      await _removeToken();
      throw Exception('Sesión expirada. Por favor inicia sesión nuevamente.');
    }

    if (response.statusCode >= 400) {
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Error en la petición');
    }

    return json.decode(response.body);
  }

  // Authentication
  static Future<Map<String, dynamic>> login(String email, String password) async {
    print('🌐 Enviando petición a: $baseUrl/auth/login');
    print('📧 Email: $email');
    
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
      }),
    );

    print('📊 Status code: ${response.statusCode}');
    print('📄 Response body: ${response.body}');

    final data = await _handleResponse(response);
    
    if (data['success'] && data['data']['token'] != null) {
      await _saveToken(data['data']['token']);
    }

    return data;
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/auth/profile'),
      headers: headers,
    );

    return await _handleResponse(response);
  }

  static Future<void> logout() async {
    await _removeToken();
  }

  // Rooms
  static Future<List<Room>> getRooms({
    String? type,
    double? minPrice,
    double? maxPrice,
    bool? available,
    int page = 1,
    int limit = 10,
  }) async {
    final headers = await _getHeaders();
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (type != null) queryParams['type'] = type;
    if (minPrice != null) queryParams['minPrice'] = minPrice.toString();
    if (maxPrice != null) queryParams['maxPrice'] = maxPrice.toString();
    if (available != null) queryParams['available'] = available.toString();

    final uri = Uri.parse('$baseUrl/rooms').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: headers);
    final data = await _handleResponse(response);

    return (data['data']['rooms'] as List)
        .map((room) => Room.fromJson(room))
        .toList();
  }

  static Future<Room> getRoomById(String id) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/rooms/$id'),
      headers: headers,
    );

    final data = await _handleResponse(response);
    return Room.fromJson(data['data']['room']);
  }

  static Future<Room> createRoom(Room room) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/rooms'),
      headers: headers,
      body: json.encode(room.toJson()),
    );

    final data = await _handleResponse(response);
    return Room.fromJson(data['data']['room']);
  }

  static Future<Room> updateRoom(String id, Room room) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/rooms/$id'),
      headers: headers,
      body: json.encode(room.toJson()),
    );

    final data = await _handleResponse(response);
    return Room.fromJson(data['data']['room']);
  }

  static Future<void> deleteRoom(String id) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/rooms/$id'),
      headers: headers,
    );

    await _handleResponse(response);
  }

  // Customers
  static Future<List<Customer>> getCustomers({
    String? search,
    int page = 1,
    int limit = 10,
  }) async {
    final headers = await _getHeaders();
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (search != null) queryParams['search'] = search;

    final uri = Uri.parse('$baseUrl/customers').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: headers);
    final data = await _handleResponse(response);

    return (data['data']['customers'] as List)
        .map((customer) => Customer.fromJson(customer))
        .toList();
  }

  static Future<Customer> getCustomerById(String id) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/customers/$id'),
      headers: headers,
    );

    final data = await _handleResponse(response);
    return Customer.fromJson(data['data']['customer']);
  }

  static Future<Customer> createCustomer(Customer customer) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/customers'),
      headers: headers,
      body: json.encode(customer.toJson()),
    );

    final data = await _handleResponse(response);
    return Customer.fromJson(data['data']['customer']);
  }

  static Future<Customer> updateCustomer(String id, Customer customer) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/customers/$id'),
      headers: headers,
      body: json.encode(customer.toJson()),
    );

    final data = await _handleResponse(response);
    return Customer.fromJson(data['data']['customer']);
  }

  static Future<void> deleteCustomer(String id) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/customers/$id'),
      headers: headers,
    );

    await _handleResponse(response);
  }

  static Future<Customer?> searchCustomerByDocument(String documentNumber) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/customers/search?documentNumber=$documentNumber'),
      headers: headers,
    );

    try {
      final data = await _handleResponse(response);
      return Customer.fromJson(data['data']['customer']);
    } catch (e) {
      if (e.toString().contains('404')) {
        return null;
      }
      rethrow;
    }
  }

  // Bookings
  static Future<List<Booking>> getBookings({
    String? status,
    DateTime? checkIn,
    DateTime? checkOut,
    String? customer,
    String? room,
    int page = 1,
    int limit = 10,
  }) async {
    final headers = await _getHeaders();
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (status != null) queryParams['status'] = status;
    if (checkIn != null) queryParams['checkIn'] = checkIn.toIso8601String();
    if (checkOut != null) queryParams['checkOut'] = checkOut.toIso8601String();
    if (customer != null) queryParams['customer'] = customer;
    if (room != null) queryParams['room'] = room;

    final uri = Uri.parse('$baseUrl/bookings').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: headers);
    final data = await _handleResponse(response);

    return (data['data']['bookings'] as List)
        .map((booking) => Booking.fromJson(booking))
        .toList();
  }

  static Future<Booking> getBookingById(String id) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/bookings/$id'),
      headers: headers,
    );

    final data = await _handleResponse(response);
    return Booking.fromJson(data['data']['booking']);
  }

  static Future<Booking> createBooking(Booking booking) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/bookings'),
      headers: headers,
      body: json.encode(booking.toJson()),
    );

    final data = await _handleResponse(response);
    return Booking.fromJson(data['data']['booking']);
  }

  static Future<Booking> updateBooking(String id, Booking booking) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/bookings/$id'),
      headers: headers,
      body: json.encode(booking.toJson()),
    );

    final data = await _handleResponse(response);
    return Booking.fromJson(data['data']['booking']);
  }

  static Future<void> deleteBooking(String id) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/bookings/$id'),
      headers: headers,
    );

    await _handleResponse(response);
  }

  static Future<Booking> checkIn(String id) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/bookings/$id/checkin'),
      headers: headers,
    );

    final data = await _handleResponse(response);
    return Booking.fromJson(data['data']['booking']);
  }

  static Future<Booking> checkOut(String id) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/bookings/$id/checkout'),
      headers: headers,
    );

    final data = await _handleResponse(response);
    return Booking.fromJson(data['data']['booking']);
  }

  static Future<List<Booking>> getBookingsForCheckIn(String customerName) async {
    final headers = await _getHeaders();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final response = await http.get(
      Uri.parse('$baseUrl/bookings/checkin/available?date=$today&customerName=$customerName'),
      headers: headers,
    );

    final data = await _handleResponse(response);
    return (data['data']['bookings'] as List)
        .map((booking) => Booking.fromJson(booking))
        .toList();
  }

  static Future<Booking> directCheckIn(Booking booking) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/bookings/checkin/direct'),
      headers: headers,
      body: json.encode(booking.toJson()),
    );

    final data = await _handleResponse(response);
    return Booking.fromJson(data['data']['booking']);
  }

  // Dashboard
  static Future<Map<String, dynamic>> getDashboardStats() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/bookings/dashboard'),
      headers: headers,
    );

    return await _handleResponse(response);
  }

  // Room availability check
  static Future<Map<String, dynamic>> checkRoomAvailability(
    String roomId, 
    DateTime checkIn, 
    DateTime checkOut, 
    {String? excludeBookingId}
  ) async {
    final headers = await _getHeaders();
    final params = {
      'roomId': roomId,
      'checkIn': checkIn.toIso8601String(),
      'checkOut': checkOut.toIso8601String(),
      if (excludeBookingId != null) 'excludeBookingId': excludeBookingId,
    };
    
    final response = await http.get(
      Uri.parse('$baseUrl/rooms/availability').replace(queryParameters: params),
      headers: headers,
    );

    return await _handleResponse(response);
  }

  // Renew booking
  static Future<Booking> renewBooking(String bookingId, DateTime newCheckOut) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/bookings/$bookingId/renew'),
      headers: headers,
      body: json.encode({'checkOut': newCheckOut.toIso8601String()}),
    );

    final data = await _handleResponse(response);
    return Booking.fromJson(data['data']);
  }

  // Countries
  static Future<Map<String, dynamic>> getCountries({String? search}) async {
    final headers = await _getHeaders();
    final queryParams = <String, String>{};
    if (search != null) queryParams['search'] = search;

    final uri = Uri.parse('$baseUrl/countries').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: headers);
    return await _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getCountryByCode(String code) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/countries/$code'),
      headers: headers,
    );
    return await _handleResponse(response);
  }

  // Departments
  static Future<Map<String, dynamic>> getDepartments({String? search}) async {
    final headers = await _getHeaders();
    final queryParams = <String, String>{};
    if (search != null) queryParams['search'] = search;

    final uri = Uri.parse('$baseUrl/departments').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: headers);
    return await _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getDepartmentByCode(String code) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/departments/$code'),
      headers: headers,
    );
    return await _handleResponse(response);
  }
}
