import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/room.dart';
import '../models/booking.dart';
import '../providers/room_provider.dart';
import '../providers/booking_provider.dart';

class RoomRackView extends StatefulWidget {
  const RoomRackView({super.key});

  @override
  State<RoomRackView> createState() => _RoomRackViewState();
}

class _RoomRackViewState extends State<RoomRackView> {
  String _selectedType = 'all';
  final List<String> _typeOptions = ['all', 'single', 'double', 'suite', 'family'];
  bool _hasLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasLoaded) {
        _hasLoaded = true;
        final roomProvider = Provider.of<RoomProvider>(context, listen: false);
        final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
        
        // Siempre recargar para obtener las últimas reservas
        roomProvider.loadRooms();
        bookingProvider.loadBookings();
      }
    });
  }

  RoomStatus _getRoomStatus(Room room, List<Booking> bookings) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Buscar reservas activas para esta habitación
    final activeBookings = bookings.where((booking) {
      if (booking.room.id != room.id) return false;
      
      final checkIn = DateTime(
        booking.checkIn.year,
        booking.checkIn.month,
        booking.checkIn.day,
      );
      final checkOut = DateTime(
        booking.checkOut.year,
        booking.checkOut.month,
        booking.checkOut.day,
      );
      
      // Verificar si hoy está dentro del rango de la reserva (incluyendo check-in y check-out)
      final isWithinDateRange = (today.isAtSameMomentAs(checkIn) || today.isAfter(checkIn)) &&
                                 (today.isBefore(checkOut) || today.isAtSameMomentAs(checkOut));
      
      // Incluir reservas con estado pending, confirmed o checked_in
      final isValidStatus = booking.status == 'pending' || 
                           booking.status == 'confirmed' || 
                           booking.status == 'checked_in';
      
      return isWithinDateRange && isValidStatus;
    }).toList();

    if (activeBookings.isEmpty) {
      return RoomStatus.available;
    }

    final booking = activeBookings.first;
    
    if (booking.status == 'checked_in') {
      // Verificar si tiene deuda (paymentStatus != 'paid')
      if (booking.paymentStatus != 'paid') {
        return RoomStatus.withDebt;
      }
      return RoomStatus.occupied;
    } else if (booking.status == 'confirmed' || booking.status == 'pending') {
      return RoomStatus.reserved;
    }

    return RoomStatus.available;
  }

  Booking? _getActiveBooking(Room room, List<Booking> bookings) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    try {
      return bookings.firstWhere(
        (booking) {
          if (booking.room.id != room.id) return false;
          
          final checkIn = DateTime(
            booking.checkIn.year,
            booking.checkIn.month,
            booking.checkIn.day,
          );
          final checkOut = DateTime(
            booking.checkOut.year,
            booking.checkOut.month,
            booking.checkOut.day,
          );
          
          // Verificar si hoy está dentro del rango de la reserva (incluyendo check-in y check-out)
          final isWithinDateRange = (today.isAtSameMomentAs(checkIn) || today.isAfter(checkIn)) &&
                                     (today.isBefore(checkOut) || today.isAtSameMomentAs(checkOut));
          
          // Incluir reservas con estado pending, confirmed o checked_in
          final isValidStatus = booking.status == 'pending' || 
                               booking.status == 'confirmed' || 
                               booking.status == 'checked_in';
          
          return isWithinDateRange && isValidStatus;
        },
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<RoomProvider, BookingProvider>(
      builder: (context, roomProvider, bookingProvider, child) {
        // Solo mostrar loading si no hay habitaciones cargadas aún y está cargando
        if (roomProvider.isLoading && roomProvider.rooms.isEmpty && !_hasLoaded) {
          return const Center(child: CircularProgressIndicator());
        }

        // Si hay error y no hay habitaciones, mostrar error
        if (roomProvider.error != null && roomProvider.rooms.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error: ${roomProvider.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    roomProvider.clearError();
                    roomProvider.loadRooms();
                  },
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        final rooms = _selectedType == 'all'
            ? roomProvider.rooms
            : roomProvider.getRoomsByType(_selectedType);

        // Calcular estadísticas
        final stats = _calculateStats(rooms, bookingProvider.bookings);

        return Column(
          children: [
            // Filtros y estadísticas
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[100],
              child: Column(
                children: [
                  // Filtro por tipo
                  Row(
                    children: [
                      const Text('Tipo de Habitación:'),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedType,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: _typeOptions.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(_getTypeLabel(type)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedType = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Estadísticas
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _StatBadge(
                        label: 'Disponibles',
                        count: stats['available'] ?? 0,
                        color: Colors.green,
                        icon: Icons.bed,
                      ),
                      _StatBadge(
                        label: 'Ocupadas',
                        count: stats['occupied'] ?? 0,
                        color: Colors.red,
                        icon: Icons.person,
                      ),
                      _StatBadge(
                        label: 'Reservadas',
                        count: stats['reserved'] ?? 0,
                        color: Colors.orange,
                        icon: Icons.event,
                      ),
                      _StatBadge(
                        label: 'Con deuda',
                        count: stats['withDebt'] ?? 0,
                        color: Colors.red[700]!,
                        icon: Icons.attach_money,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Grid de habitaciones
            Expanded(
              child: roomProvider.isLoading && rooms.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : rooms.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.bed_outlined, size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              const Text(
                                'No hay habitaciones',
                                style: TextStyle(color: Colors.grey, fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () {
                                  roomProvider.loadRooms();
                                },
                                child: const Text('Recargar'),
                              ),
                            ],
                          ),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            // Calcular el número de columnas para tarjetas pequeñas (máximo 120px por tarjeta)
                            final maxCardWidth = 120.0;
                            final spacing = 6.0;
                            final padding = 8.0 * 2; // padding izquierdo y derecho
                            final availableWidth = constraints.maxWidth - padding;
                            final crossAxisCount = (availableWidth / (maxCardWidth + spacing)).floor().clamp(1, 20);
                            
                            return GridView.builder(
                              padding: const EdgeInsets.all(6),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                childAspectRatio: 0.9,
                                crossAxisSpacing: spacing,
                                mainAxisSpacing: spacing,
                              ),
                              itemCount: rooms.length,
                              itemBuilder: (context, index) {
                                final room = rooms[index];
                                final status = _getRoomStatus(room, bookingProvider.bookings);
                                final booking = _getActiveBooking(room, bookingProvider.bookings);
                                
                                return _RoomRackCard(
                                  room: room,
                                  status: status,
                                  booking: booking,
                                  onTap: () => _showRoomDetails(context, room, booking, status),
                                );
                              },
                            );
                          },
                        ),
            ),
          ],
        );
      },
    );
  }

  Map<String, int> _calculateStats(List<Room> rooms, List<Booking> bookings) {
    int available = 0;
    int occupied = 0;
    int reserved = 0;
    int withDebt = 0;

    for (final room in rooms) {
      final status = _getRoomStatus(room, bookings);
      switch (status) {
        case RoomStatus.available:
          available++;
          break;
        case RoomStatus.occupied:
          occupied++;
          break;
        case RoomStatus.reserved:
          reserved++;
          break;
        case RoomStatus.withDebt:
          withDebt++;
          occupied++;
          break;
        default:
          available++;
      }
    }

    return {
      'available': available,
      'occupied': occupied,
      'reserved': reserved,
      'withDebt': withDebt,
    };
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'all':
        return 'Todas';
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

  void _showRoomDetails(BuildContext context, Room room, Booking? booking, RoomStatus status) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Habitación ${room.number}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusChip(status),
              const SizedBox(height: 16),
              Text('Tipo: ${room.typeLabel}'),
              Text('Piso: ${room.floor}'),
              Text('Capacidad: ${room.capacity} personas'),
              Text('Precio: ${room.formattedPrice}/noche'),
              if (booking != null) ...[
                const Divider(),
                const Text('Huésped:', style: TextStyle(fontWeight: FontWeight.bold)),
                if (booking.customer.firstName.isNotEmpty && booking.customer.lastName.isNotEmpty)
                  Text('${booking.customer.firstName} ${booking.customer.lastName}'),
                Text('Check-in: ${DateFormat('dd/MM/yyyy').format(booking.checkIn)}'),
                Text('Check-out: ${DateFormat('dd/MM/yyyy').format(booking.checkOut)}'),
                Text('Estado pago: ${booking.paymentStatus}'),
                Text('Estado: ${booking.status}'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(RoomStatus status) {
    final (color, label) = _getStatusInfo(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  (Color, String) _getStatusInfo(RoomStatus status) {
    switch (status) {
      case RoomStatus.available:
        return (Colors.green, 'Disponible');
      case RoomStatus.occupied:
        return (Colors.red, 'Ocupada');
      case RoomStatus.reserved:
        return (Colors.orange, 'Reservada');
      case RoomStatus.withDebt:
        return (Colors.red[700]!, 'Con deuda');
      default:
        return (Colors.grey, 'Desconocido');
    }
  }
}

enum RoomStatus {
  available,
  occupied,
  reserved,
  withDebt,
}

class _RoomRackCard extends StatelessWidget {
  final Room room;
  final RoomStatus status;
  final Booking? booking;
  final VoidCallback onTap;

  const _RoomRackCard({
    required this.room,
    required this.status,
    this.booking,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (color, label) = _getStatusInfo(status);
    
    return Card(
      elevation: 0.5,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icono de estado
                Icon(
                  _getStatusIcon(status),
                  size: 20,
                  color: color,
                ),
                const SizedBox(height: 2),
                // Número de habitación
                Text(
                  room.number,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 1),
                // Estado
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 8,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // Nombre del huésped si está ocupada
                if (booking != null) ...[
                  const SizedBox(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Text(
                      (booking!.customer.firstName.isNotEmpty && booking!.customer.lastName.isNotEmpty)
                          ? '${booking!.customer.firstName} ${booking!.customer.lastName}'
                          : 'Ocupada',
                      style: const TextStyle(
                        fontSize: 7,
                        color: Colors.grey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getStatusIcon(RoomStatus status) {
    switch (status) {
      case RoomStatus.available:
        return Icons.bed;
      case RoomStatus.occupied:
        return Icons.person;
      case RoomStatus.reserved:
        return Icons.event;
      case RoomStatus.withDebt:
        return Icons.attach_money;
      default:
        return Icons.bed;
    }
  }

  (Color, String) _getStatusInfo(RoomStatus status) {
    switch (status) {
      case RoomStatus.available:
        return (Colors.green, 'Disponible');
      case RoomStatus.occupied:
        return (Colors.red, 'Ocupada');
      case RoomStatus.reserved:
        return (Colors.orange, 'Reservada');
      case RoomStatus.withDebt:
        return (Colors.red[700]!, 'Con deuda');
      default:
        return (Colors.grey, 'Desconocido');
    }
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _StatBadge({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            '$label: ',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          Text(
            count.toString(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

