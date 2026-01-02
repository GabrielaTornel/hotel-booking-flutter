import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/booking_provider.dart';
import '../widgets/booking_list_tile.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  String _selectedStatus = 'all';
  final List<String> _statusOptions = [
    'all',
    'pending',
    'confirmed',
    'checked_in',
    'checked_out',
    'cancelled',
    'no_show',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BookingProvider>(context, listen: false).loadBookings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('Filtrar por estado:'),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: _statusOptions.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(_getStatusLabel(status)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedStatus = value!;
                      });
                      _filterBookings();
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Bookings List
          Expanded(
            child: Consumer<BookingProvider>(
              builder: (context, bookingProvider, child) {
                print('📋 BookingsScreen build - isLoading: ${bookingProvider.isLoading}, error: ${bookingProvider.error}');
                print('📋 BookingsScreen build - bookings count: ${bookingProvider.bookings.length}');
                
                if (bookingProvider.isLoading) {
                  print('📋 Mostrando loading...');
                  return const Center(child: CircularProgressIndicator());
                }

                if (bookingProvider.error != null) {
                  print('📋 Mostrando error: ${bookingProvider.error}');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          bookingProvider.error!,
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            bookingProvider.clearError();
                            bookingProvider.loadBookings();
                          },
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }

                print('📋 Filtrando reservas por estado: $_selectedStatus');
                List<dynamic> filteredBookings = bookingProvider.bookings;
                if (_selectedStatus != 'all') {
                  filteredBookings = bookingProvider.getBookingsByStatus(_selectedStatus);
                }
                print('📋 Reservas filtradas: ${filteredBookings.length}');

                if (filteredBookings.isEmpty) {
                  print('📋 No hay reservas, mostrando mensaje vacío');
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.book_online_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No hay reservas',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                print('📋 Construyendo ListView con ${filteredBookings.length} reservas');
                return ListView.builder(
                  itemCount: filteredBookings.length,
                  itemBuilder: (context, index) {
                    try {
                      print('📋 Construyendo item $index de ${filteredBookings.length}');
                      final booking = filteredBookings[index];
                      print('📋 Booking ${index}: ${booking.bookingNumber}, room: ${booking.room?.number ?? 'null'}, room.isAvailable: ${booking.room?.isAvailable}');
                      
                      return BookingListTile(
                        booking: booking,
                        showActions: true,
                        onTap: () {
                          _showBookingDetails(context, booking);
                        },
                      );
                    } catch (e, stackTrace) {
                      print('❌ Error construyendo item $index: $e');
                      print('Stack trace: $stackTrace');
                      return Card(
                        child: ListTile(
                          title: Text('Error en reserva $index'),
                          subtitle: Text('$e'),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      );
  }

  void _filterBookings() {
    // The filtering is handled in the build method
    setState(() {});
  }

  void _showBookingDetails(BuildContext context, dynamic booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reserva ${booking.bookingNumber}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Cliente', '${booking.customer.firstName} ${booking.customer.lastName}'),
              _buildDetailRow('Email', booking.customer.email),
              _buildDetailRow('Teléfono', booking.customer.phone),
              _buildDetailRow('Habitación', '${booking.room.number} - ${booking.room.typeLabel}'),
              _buildDetailRow('Check-in', booking.checkIn.toString().split(' ')[0]),
              _buildDetailRow('Check-out', booking.checkOut.toString().split(' ')[0]),
              _buildDetailRow('Huéspedes', '${booking.guests.adults} adultos, ${booking.guests.children} niños'),
              _buildDetailRow('Estado', booking.statusLabel),
              _buildDetailRow('Total', '\$${booking.totalAmount.toStringAsFixed(2)}'),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'all':
        return 'Todas';
      case 'pending':
        return 'Pendientes';
      case 'confirmed':
        return 'Confirmadas';
      case 'checked_in':
        return 'Check-in';
      case 'checked_out':
        return 'Check-out';
      case 'cancelled':
        return 'Canceladas';
      case 'no_show':
        return 'No Show';
      default:
        return status;
    }
  }
}
