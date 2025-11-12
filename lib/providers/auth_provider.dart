import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🔐 Intentando login con: $email');
      final response = await ApiService.login(email, password);
      print('📡 Respuesta del servidor: $response');
      
      if (response['success']) {
        final userData = response['data']['user'];
        print('✅ Login exitoso, datos del usuario: $userData');
        _user = User.fromJson(userData);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Error al iniciar sesión';
        print('❌ Error en login: $_error');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      print('💥 Excepción en login: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadProfile() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.getProfile();
      
      if (response['success']) {
        final userData = response['data']['user'];
        _user = User.fromJson(userData);
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> logout() async {
    await ApiService.logout();
    _user = null;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  bool hasPermission(String permission) {
    return _user?.hasPermission(permission) ?? false;
  }
}
