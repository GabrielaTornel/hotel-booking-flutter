import 'package:flutter/foundation.dart';
import '../models/customer.dart';
import '../services/api_service.dart';

class CustomerProvider with ChangeNotifier {
  List<Customer> _customers = [];
  bool _isLoading = false;
  String? _error;

  List<Customer> get customers => _customers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadCustomers({
    String? search,
    int page = 1,
    int limit = 10,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _customers = await ApiService.getCustomers(
        search: search,
        page: page,
        limit: limit,
      );
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Customer?> getCustomerById(String id) async {
    try {
      return await ApiService.getCustomerById(id);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<Customer?> createCustomer(Customer customer) async {
    try {
      final newCustomer = await ApiService.createCustomer(customer);
      _customers.add(newCustomer);
      notifyListeners();
      return newCustomer;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<Customer?> updateCustomer(String id, Customer customer) async {
    try {
      final updatedCustomer = await ApiService.updateCustomer(id, customer);
      final index = _customers.indexWhere((c) => c.id == id);
      if (index != -1) {
        _customers[index] = updatedCustomer;
        notifyListeners();
      }
      return updatedCustomer;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> deleteCustomer(String id) async {
    try {
      await ApiService.deleteCustomer(id);
      _customers.removeWhere((c) => c.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  List<Customer> searchCustomers(String query) {
    if (query.isEmpty) return _customers;
    
    return _customers.where((customer) {
      return customer.firstName.toLowerCase().contains(query.toLowerCase()) ||
             customer.lastName.toLowerCase().contains(query.toLowerCase()) ||
             customer.email.toLowerCase().contains(query.toLowerCase()) ||
             customer.phone.contains(query) ||
             customer.documentNumber.contains(query);
    }).toList();
  }

  List<Customer> getCustomersByNationality(String nationality) {
    return _customers.where((customer) => customer.nationality == nationality).toList();
  }

  List<Customer> getLoyaltyCustomers() {
    return _customers.where((customer) => customer.loyaltyPoints > 0).toList();
  }

  Future<Customer?> searchCustomerByDocument(String documentNumber) async {
    try {
      return await ApiService.searchCustomerByDocument(documentNumber);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<List<Customer>> searchCustomersByName(String name) async {
    try {
      // Cargar todos los clientes si no están cargados
      if (_customers.isEmpty) {
        await loadCustomers();
      }
      
      // Buscar por nombre o apellido
      return _customers.where((customer) {
        final fullName = '${customer.firstName} ${customer.lastName}'.toLowerCase();
        final searchName = name.toLowerCase();
        return fullName.contains(searchName) || 
               customer.firstName.toLowerCase().contains(searchName) ||
               customer.lastName.toLowerCase().contains(searchName);
      }).toList();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Método para refrescar los datos
  Future<void> refreshCustomers() async {
    await loadCustomers();
  }
}
