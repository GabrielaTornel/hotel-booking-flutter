import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/booking_provider.dart';
import '../providers/customer_provider.dart';
import '../providers/room_provider.dart';
import '../models/customer.dart';
import '../models/room.dart';
import '../models/booking.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  
  // Estados para búsqueda de reservas existentes
  final TextEditingController _bookingSearchController = TextEditingController();
  bool _isSearching = false;
  
  // Estados para check-in directo
  Customer? _selectedCustomer;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nationalityController = TextEditingController();
  final TextEditingController _documentNumberController = TextEditingController();
  String _documentType = 'dni';
  
  Room? _selectedRoom;
  DateTime _checkInDate = DateTime.now();
  DateTime _checkOutDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _checkInTime = const TimeOfDay(hour: 15, minute: 0); // 3:00 PM por defecto
  TimeOfDay _checkOutTime = const TimeOfDay(hour: 11, minute: 0); // 11:00 AM por defecto
  bool _flexibleCheckIn = false;
  bool _flexibleCheckOut = false;
  int _adults = 1;
  int _children = 0;
  String _paymentMethod = 'cash';
  double _discountPercentage = 0.0;
  String _discountReason = '';
  final TextEditingController _specialRequestsController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  bool _isCreatingCustomer = false;
  bool _isProcessingCheckIn = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRooms();
    _loadAllBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bookingSearchController.dispose();
    _searchController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _nationalityController.dispose();
    _documentNumberController.dispose();
    _specialRequestsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _loadRooms() {
    Provider.of<RoomProvider>(context, listen: false).loadRooms();
  }

  void _loadAllBookings() {
    Provider.of<BookingProvider>(context, listen: false).loadBookings();
  }

  Future<void> _searchCustomer() async {
    if (_searchController.text.trim().isEmpty) return;
    
    setState(() {
      _isCreatingCustomer = true;
    });
    
    try {
      final searchTerm = _searchController.text.trim();
      Customer? customer;
      
      // Primero intentar buscar por documento si parece ser un número
      if (RegExp(r'^\d+$').hasMatch(searchTerm)) {
        customer = await Provider.of<CustomerProvider>(context, listen: false)
            .searchCustomerByDocument(searchTerm);
      }
      
      // Si no se encontró por documento, buscar por nombre
      if (customer == null) {
        final customers = await Provider.of<CustomerProvider>(context, listen: false)
            .searchCustomersByName(searchTerm);
        if (customers.isNotEmpty) {
          // Si hay múltiples resultados, mostrar diálogo de selección
          if (customers.length == 1) {
            customer = customers.first;
          } else {
            customer = await _showCustomerSelectionDialog(customers);
          }
        }
      }
      
      if (customer != null) {
        setState(() {
          _selectedCustomer = customer!;
          _firstNameController.text = customer!.firstName;
          _lastNameController.text = customer!.lastName;
          _emailController.text = customer!.email;
          _phoneController.text = customer!.phone;
          _nationalityController.text = customer!.nationality;
        });
        _showMessage('Cliente encontrado', isError: false);
      } else {
        _showMessage('Cliente no encontrado. Puede crear uno nuevo.', isError: true);
      }
    } catch (e) {
      _showMessage('Error buscando cliente: $e', isError: true);
    } finally {
      setState(() {
        _isCreatingCustomer = false;
      });
    }
  }

  Future<void> _createCustomer() async {
    if (_firstNameController.text.trim().isEmpty || 
        _lastNameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _documentNumberController.text.trim().isEmpty) {
      _showMessage('Por favor complete todos los campos requeridos', isError: true);
      return;
    }
    
    setState(() {
      _isCreatingCustomer = true;
    });
    
    try {
      final customer = Customer(
        id: '', // Will be set by the server
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        documentType: _documentType,
        documentNumber: _documentNumberController.text.trim(),
        nationality: _nationalityController.text.trim(),
        birthDate: DateTime.now().subtract(const Duration(days: 365 * 25)), // Default age
        loyaltyPoints: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      final createdCustomer = await Provider.of<CustomerProvider>(context, listen: false)
          .createCustomer(customer);
      
      setState(() {
        _selectedCustomer = createdCustomer;
      });
      
      _showMessage('Cliente creado exitosamente', isError: false);
    } catch (e) {
      _showMessage('Error creando cliente: $e', isError: true);
    } finally {
      setState(() {
        _isCreatingCustomer = false;
      });
    }
  }

  Future<void> _searchBookings() async {
    // El filtrado ahora se hace automáticamente en el Consumer
    // Este método se mantiene para compatibilidad con el botón
    setState(() {
      // Solo actualizar el estado para que se reconstruya la lista
    });
  }

  Future<void> _checkInExisting(Booking booking) async {
    setState(() {
      _isProcessingCheckIn = true;
    });
    
    try {
      await Provider.of<BookingProvider>(context, listen: false)
          .checkIn(booking.id!);
      
      _showMessage('Check-in realizado exitosamente', isError: false);
      
      // Actualizar la lista de resultados
      _searchBookings();
    } catch (e) {
      _showMessage('Error realizando check-in: $e', isError: true);
    } finally {
      setState(() {
        _isProcessingCheckIn = false;
      });
    }
  }

  Future<void> _directCheckIn() async {
    if (_selectedCustomer == null || _selectedRoom == null) {
      _showMessage('Por favor seleccione un cliente y una habitación', isError: true);
      return;
    }
    
    setState(() {
      _isProcessingCheckIn = true;
    });
    
    try {
      final booking = Booking(
        id: '', // Will be set by the server
        bookingNumber: '', // Will be set by the server
        customer: _selectedCustomer!,
        room: _selectedRoom!,
        checkIn: _checkInDate,
        checkOut: _checkOutDate,
        guests: Guests(adults: _adults, children: _children),
        status: 'checked_in',
        totalAmount: _calculateTotalWithDiscount(),
        paymentStatus: 'paid',
        paymentMethod: _paymentMethod,
        specialRequests: _specialRequestsController.text.trim(),
        notes: _buildNotesWithDiscount(),
        source: 'walk_in',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await Provider.of<BookingProvider>(context, listen: false)
          .directCheckIn(booking);
      
      _showMessage('Check-in directo realizado exitosamente', isError: false);
      
      // Limpiar formulario
      _resetForm();
    } catch (e) {
      _showMessage('Error realizando check-in directo: $e', isError: true);
    } finally {
      setState(() {
        _isProcessingCheckIn = false;
      });
    }
  }

  void _resetForm() {
    setState(() {
      _selectedCustomer = null;
      _selectedRoom = null;
      _searchController.clear();
      _firstNameController.clear();
      _lastNameController.clear();
      _emailController.clear();
      _phoneController.clear();
      _nationalityController.clear();
      _specialRequestsController.clear();
      _notesController.clear();
      _checkInDate = DateTime.now();
      _checkOutDate = DateTime.now().add(const Duration(days: 1));
      _checkInTime = const TimeOfDay(hour: 15, minute: 0);
      _checkOutTime = const TimeOfDay(hour: 11, minute: 0);
      _flexibleCheckIn = false;
      _flexibleCheckOut = false;
      _adults = 1;
      _children = 0;
      _paymentMethod = 'cash';
      _documentType = 'dni';
      _discountPercentage = 0.0;
      _discountReason = '';
    });
  }

  Future<Customer?> _showCustomerSelectionDialog(List<Customer> customers) async {
    return await showDialog<Customer>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar Cliente'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: customers.length,
            itemBuilder: (context, index) {
              final customer = customers[index];
              return ListTile(
                title: Text(customer.fullName),
                subtitle: Text('${customer.email} • ${customer.documentTypeLabel}: ${customer.documentNumber}'),
                onTap: () => Navigator.of(context).pop(customer),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  double _calculateTotal() {
    if (_selectedRoom == null) return 0.0;
    
    final nights = _checkOutDate.difference(_checkInDate).inDays;
    return _selectedRoom!.price * nights;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Check-in'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Custom Tab Bar
          Container(
            color: Colors.blue[50],
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _tabController.index = 0;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                      decoration: BoxDecoration(
                        color: _tabController.index == 0 ? Colors.blue[600] : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search,
                            color: _tabController.index == 0 ? Colors.white : Colors.blue[600],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Reservas',
                            style: TextStyle(
                              color: _tabController.index == 0 ? Colors.white : Colors.blue[600],
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _tabController.index = 1;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                      decoration: BoxDecoration(
                        color: _tabController.index == 1 ? Colors.blue[600] : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add,
                            color: _tabController.index == 1 ? Colors.white : Colors.blue[600],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Directo',
                            style: TextStyle(
                              color: _tabController.index == 1 ? Colors.white : Colors.blue[600],
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildExistingBookingsTab(),
                _buildDirectCheckInTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExistingBookingsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Búsqueda
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Buscar Reservas para Check-in',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _bookingSearchController,
                            decoration: const InputDecoration(
                              labelText: 'Nombre del cliente',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _isSearching ? null : _searchBookings,
                          child: _isSearching 
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Buscar'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Resultados
          Expanded(
            child: Consumer<BookingProvider>(
              builder: (context, bookingProvider, child) {
                // Obtener todas las reservas
                final allBookings = bookingProvider.bookings;
                
                // Filtrar reservas si hay texto de búsqueda
                final filteredBookings = _bookingSearchController.text.trim().isEmpty
                    ? allBookings
                    : allBookings.where((booking) {
                        final searchText = _bookingSearchController.text.toLowerCase();
                        return booking.customer.firstName.toLowerCase().contains(searchText) ||
                               booking.customer.lastName.toLowerCase().contains(searchText) ||
                               booking.customer.email.toLowerCase().contains(searchText) ||
                               booking.room.number.toLowerCase().contains(searchText);
                      }).toList();
                
                if (filteredBookings.isEmpty) {
                  return Center(
                    child: Text(
                      _bookingSearchController.text.trim().isEmpty
                          ? 'No hay reservas disponibles.'
                          : 'No se encontraron reservas con ese criterio.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  );
                }
                
                return ListView.builder(
                  itemCount: filteredBookings.length,
                  itemBuilder: (context, index) {
                    final booking = filteredBookings[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text('${booking.customer.firstName} ${booking.customer.lastName}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Habitación: ${booking.room.number} - ${booking.room.type}'),
                            Text('Check-in: ${_formatDate(booking.checkIn)}'),
                            Text('Check-out: ${_formatDate(booking.checkOut)}'),
                            Text('Huéspedes: ${booking.guests.adults} adultos, ${booking.guests.children} niños'),
                          ],
                        ),
                        trailing: Chip(
                          label: Text(booking.status == 'confirmed' ? 'Confirmada' : 'Pendiente'),
                          backgroundColor: booking.status == 'confirmed' ? Colors.green : Colors.orange,
                        ),
                        onTap: () => _showBookingDetails(booking),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectCheckInTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Información del Cliente
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Información del Cliente',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  // Búsqueda por nombre o DNI
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            labelText: 'Buscar por nombre o DNI',
                            hintText: 'Ej: Juan Pérez o 12345678',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.search),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _isCreatingCustomer ? null : _searchCustomer,
                        child: _isCreatingCustomer
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Buscar'),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Información del cliente encontrado o formulario
                  if (_selectedCustomer != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        border: Border.all(color: Colors.green.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.person, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_selectedCustomer!.firstName} ${_selectedCustomer!.lastName}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text('${_selectedCustomer!.email} • ${_selectedCustomer!.phone}'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    _buildCustomerForm(),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Información de la Reserva
          if (_selectedCustomer != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Información de la Reserva',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    
                    // Fechas y Horarios
                    // Check-in
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Check-in',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                decoration: const InputDecoration(
                                  labelText: 'Fecha',
                                  border: OutlineInputBorder(),
                                ),
                                controller: TextEditingController(
                                  text: _formatDate(_checkInDate),
                                ),
                                readOnly: true,
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: _checkInDate,
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 365)),
                                  );
                                  if (date != null) {
                                    setState(() {
                                      _checkInDate = date;
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                decoration: const InputDecoration(
                                  labelText: 'Hora',
                                  border: OutlineInputBorder(),
                                ),
                                controller: TextEditingController(
                                  text: _formatTime(_checkInTime),
                                ),
                                readOnly: true,
                                onTap: _flexibleCheckIn ? null : () async {
                                  final time = await showTimePicker(
                                    context: context,
                                    initialTime: _checkInTime,
                                  );
                                  if (time != null) {
                                    setState(() {
                                      _checkInTime = time;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Checkbox(
                              value: _flexibleCheckIn,
                              onChanged: (value) {
                                setState(() {
                                  _flexibleCheckIn = value ?? false;
                                });
                              },
                            ),
                            const Text('Horario libre'),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Check-out
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Check-out',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                decoration: const InputDecoration(
                                  labelText: 'Fecha',
                                  border: OutlineInputBorder(),
                                ),
                                controller: TextEditingController(
                                  text: _formatDate(_checkOutDate),
                                ),
                                readOnly: true,
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: _checkOutDate,
                                    firstDate: _checkInDate.add(const Duration(days: 1)),
                                    lastDate: DateTime.now().add(const Duration(days: 365)),
                                  );
                                  if (date != null) {
                                    setState(() {
                                      _checkOutDate = date;
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                decoration: const InputDecoration(
                                  labelText: 'Hora',
                                  border: OutlineInputBorder(),
                                ),
                                controller: TextEditingController(
                                  text: _formatTime(_checkOutTime),
                                ),
                                readOnly: true,
                                onTap: _flexibleCheckOut ? null : () async {
                                  final time = await showTimePicker(
                                    context: context,
                                    initialTime: _checkOutTime,
                                  );
                                  if (time != null) {
                                    setState(() {
                                      _checkOutTime = time;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Checkbox(
                              value: _flexibleCheckOut,
                              onChanged: (value) {
                                setState(() {
                                  _flexibleCheckOut = value ?? false;
                                });
                              },
                            ),
                            const Text('Horario libre'),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Huéspedes
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: _adults.toString(),
                            decoration: const InputDecoration(
                              labelText: 'Adultos',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              setState(() {
                                _adults = int.tryParse(value) ?? 1;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            initialValue: _children.toString(),
                            decoration: const InputDecoration(
                              labelText: 'Niños',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              setState(() {
                                _children = int.tryParse(value) ?? 0;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Selección de habitación
                    Consumer<RoomProvider>(
                      builder: (context, roomProvider, child) {
                        // Filtrar habitaciones disponibles según las fechas
                        final availableRooms = _getAvailableRooms(roomProvider.rooms);
                        
                        return DropdownButtonFormField<Room>(
                          value: _selectedRoom,
                          decoration: const InputDecoration(
                            labelText: 'Habitación',
                            border: OutlineInputBorder(),
                          ),
                          items: availableRooms.map((room) {
                            return DropdownMenuItem<Room>(
                              value: room,
                              child: Text(
                                '${room.number} - ${room.type} - \$${room.price}/noche',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (room) {
                            setState(() {
                              _selectedRoom = room;
                            });
                            
                            // Mostrar alerta si hay conflicto
                            if (room != null && _checkRoomConflict(room)) {
                              _showRoomConflictAlert(room);
                            }
                          },
                        );
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Método de pago
                    DropdownButtonFormField<String>(
                      value: _paymentMethod,
                      decoration: const InputDecoration(
                        labelText: 'Método de Pago',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'cash', child: Text('Efectivo')),
                        DropdownMenuItem(value: 'card', child: Text('Tarjeta')),
                        DropdownMenuItem(value: 'transfer', child: Text('Transferencia')),
                        DropdownMenuItem(value: 'online', child: Text('Online')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _paymentMethod = value!;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Solicitudes especiales
                    TextField(
                      controller: _specialRequestsController,
                      decoration: const InputDecoration(
                        labelText: 'Solicitudes Especiales',
                        border: OutlineInputBorder(),
                        hintText: 'Cama extra, vista al mar, etc.',
                      ),
                      maxLines: 2,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Notas
                    TextField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notas',
                        border: OutlineInputBorder(),
                        hintText: 'Notas adicionales...',
                      ),
                      maxLines: 2,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Sección de descuentos
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'Descuento (%)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              setState(() {
                                _discountPercentage = double.tryParse(value) ?? 0.0;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'Motivo del descuento',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _discountReason = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Resumen de precio
                    if (_selectedRoom != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          border: Border.all(color: Colors.blue.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Precio original:'),
                                Text('\$${_calculateOriginalTotal().toStringAsFixed(2)}'),
                              ],
                            ),
                            if (_discountPercentage > 0) ...[
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Descuento (${_discountPercentage.toStringAsFixed(1)}%):'),
                                  Text(
                                    '-\$${(_calculateOriginalTotal() * _discountPercentage / 100).toStringAsFixed(2)}',
                                    style: const TextStyle(color: Colors.green),
                                  ),
                                ],
                              ),
                              if (_discountReason.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Motivo: $_discountReason',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ],
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total a pagar:',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '\$${_calculateTotalWithDiscount().toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    
                    const SizedBox(height: 24),
                    
                    // Botón de check-in
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isProcessingCheckIn ? null : _directCheckIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isProcessingCheckIn
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Realizar Check-in Directo',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomerForm() {
    return Column(
      children: [
        const Text(
          'Crear Nuevo Cliente',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        
        TextField(
          controller: _firstNameController,
          decoration: const InputDecoration(
            labelText: 'Nombre',
            border: OutlineInputBorder(),
          ),
        ),
        
        const SizedBox(height: 16),
        
        TextField(
          controller: _lastNameController,
          decoration: const InputDecoration(
            labelText: 'Apellido',
            border: OutlineInputBorder(),
          ),
        ),
        
        const SizedBox(height: 16),
        
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        
        const SizedBox(height: 16),
        
        TextField(
          controller: _phoneController,
          decoration: const InputDecoration(
            labelText: 'Teléfono',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
        ),
        
        const SizedBox(height: 16),
        
        DropdownButtonFormField<String>(
          value: _documentType,
          decoration: const InputDecoration(
            labelText: 'Tipo de Documento',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'passport', child: Text('Pasaporte')),
            DropdownMenuItem(value: 'dni', child: Text('DNI')),
            DropdownMenuItem(value: 'ce', child: Text('CE')),
            DropdownMenuItem(value: 'ruc', child: Text('RUC')),
          ],
          onChanged: (value) {
            setState(() {
              _documentType = value!;
            });
          },
        ),
        
        const SizedBox(height: 16),
        
        TextField(
          controller: _documentNumberController,
          decoration: const InputDecoration(
            labelText: 'Número de Documento',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.text,
        ),
        
        const SizedBox(height: 16),
        
        TextField(
          controller: _nationalityController,
          decoration: const InputDecoration(
            labelText: 'Nacionalidad',
            border: OutlineInputBorder(),
          ),
        ),
        
        const SizedBox(height: 16),
        
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isCreatingCustomer ? null : _createCustomer,
            child: _isCreatingCustomer
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Crear Cliente'),
          ),
        ),
      ],
    );
  }

  void _showBookingDetails(Booking booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${booking.customer.firstName} ${booking.customer.lastName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Habitación: ${booking.room.number} - ${booking.room.type}'),
            Text('Check-in: ${_formatDate(booking.checkIn)}'),
            Text('Check-out: ${_formatDate(booking.checkOut)}'),
            Text('Huéspedes: ${booking.guests.adults} adultos, ${booking.guests.children} niños'),
            Text('Estado: ${booking.status}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _checkInExisting(booking);
            },
            child: const Text('Check-in'),
          ),
        ],
      ),
    );
  }

  List<Room> _getAvailableRooms(List<Room> allRooms) {
    // Por ahora retornamos todas las habitaciones
    // En una implementación real, aquí se verificaría la disponibilidad
    return allRooms;
  }

  String? _getRoomAvailability(Room room) {
    final now = DateTime.now();
    final checkInTime = _checkInDate;
    final hoursUntilCheckIn = checkInTime.difference(now).inHours;
    final daysUntilCheckIn = checkInTime.difference(now).inDays;
    
    // Verificar si hay conflictos de reserva
    final hasConflict = _checkRoomConflict(room);
    if (hasConflict) {
      return '⚠️ CONFLICTO: Habitación con reservas';
    }
    
    if (hoursUntilCheckIn <= 0) {
      return '✅ Disponible ahora';
    } else if (hoursUntilCheckIn < 24) {
      return '⏰ Disponible en $hoursUntilCheckIn horas';
    } else {
      return '📅 Disponible en $daysUntilCheckIn días';
    }
  }

  bool _checkRoomConflict(Room room) {
    // Simulación de verificación de conflictos
    // En una implementación real, aquí se consultaría la base de datos
    // para verificar si la habitación tiene reservas en el rango de fechas
    
    // Simulación: algunas habitaciones tienen conflictos
    // En la realidad, esto vendría de una consulta a la base de datos
    final roomNumber = int.tryParse(room.number) ?? 0;
    return roomNumber % 3 == 0; // Simular que cada tercera habitación tiene conflicto
  }

  double _calculateTotalWithDiscount() {
    if (_selectedRoom == null) return 0.0;
    
    final nights = _checkOutDate.difference(_checkInDate).inDays;
    final basePrice = _selectedRoom!.price * nights;
    final discountAmount = basePrice * (_discountPercentage / 100);
    return basePrice - discountAmount;
  }

  double _calculateOriginalTotal() {
    if (_selectedRoom == null) return 0.0;
    
    final nights = _checkOutDate.difference(_checkInDate).inDays;
    return _selectedRoom!.price * nights;
  }

  String _buildNotesWithDiscount() {
    final notes = _notesController.text.trim();
    final discountInfo = <String>[];
    
    if (_discountPercentage > 0) {
      discountInfo.add('Descuento aplicado: ${_discountPercentage.toStringAsFixed(1)}%');
      if (_discountReason.isNotEmpty) {
        discountInfo.add('Motivo: $_discountReason');
      }
      discountInfo.add('Precio original: \$${_calculateOriginalTotal().toStringAsFixed(2)}');
      discountInfo.add('Total con descuento: \$${_calculateTotalWithDiscount().toStringAsFixed(2)}');
    }
    
    if (notes.isNotEmpty && discountInfo.isNotEmpty) {
      return '$notes\n\n${discountInfo.join('\n')}';
    } else if (discountInfo.isNotEmpty) {
      return discountInfo.join('\n');
    } else {
      return notes;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    if (_flexibleCheckIn && time == _checkInTime) {
      return 'Horario libre';
    } else if (_flexibleCheckOut && time == _checkOutTime) {
      return 'Horario libre';
    }
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _showRoomConflictAlert(Room room) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            const SizedBox(width: 8),
            const Text('Conflicto de Reserva'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('La habitación ${room.number} tiene reservas conflictivas:'),
            const SizedBox(height: 8),
            Text('• Check-in: ${_formatDate(_checkInDate)} ${_flexibleCheckIn ? '(Horario libre)' : _formatTime(_checkInTime)}'),
            Text('• Check-out: ${_formatDate(_checkOutDate)} ${_flexibleCheckOut ? '(Horario libre)' : _formatTime(_checkOutTime)}'),
            const SizedBox(height: 8),
            const Text(
              '¿Desea continuar con esta habitación?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _selectedRoom = null;
              });
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showMessage('Habitación seleccionada con conflicto', isError: false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }
}
