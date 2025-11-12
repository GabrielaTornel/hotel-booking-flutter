import 'package:flutter/foundation.dart';
import '../models/room.dart';
import '../services/api_service.dart';

class RoomProvider with ChangeNotifier {
  List<Room> _rooms = [];
  bool _isLoading = false;
  String? _error;

  List<Room> get rooms => _rooms;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadRooms({
    String? type,
    double? minPrice,
    double? maxPrice,
    bool? available,
    int page = 1,
    int limit = 10,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _rooms = await ApiService.getRooms(
        type: type,
        minPrice: minPrice,
        maxPrice: maxPrice,
        available: available,
        page: page,
        limit: limit,
      );
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Room?> getRoomById(String id) async {
    try {
      return await ApiService.getRoomById(id);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<Room?> createRoom(Room room) async {
    try {
      final newRoom = await ApiService.createRoom(room);
      _rooms.add(newRoom);
      notifyListeners();
      return newRoom;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<Room?> updateRoom(String id, Room room) async {
    try {
      final updatedRoom = await ApiService.updateRoom(id, room);
      final index = _rooms.indexWhere((r) => r.id == id);
      if (index != -1) {
        _rooms[index] = updatedRoom;
        notifyListeners();
      }
      return updatedRoom;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> deleteRoom(String id) async {
    try {
      await ApiService.deleteRoom(id);
      _rooms.removeWhere((r) => r.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  List<Room> getAvailableRooms() {
    return _rooms.where((room) => room.isAvailable).toList();
  }

  List<Room> getRoomsByType(String type) {
    return _rooms.where((room) => room.type == type).toList();
  }

  List<Room> getRoomsByFloor(int floor) {
    return _rooms.where((room) => room.floor == floor).toList();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
