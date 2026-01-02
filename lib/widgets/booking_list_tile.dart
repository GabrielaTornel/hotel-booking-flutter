import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/booking.dart';

class BookingListTile extends StatelessWidget {
  final Booking booking;
  final bool showActions;
  final VoidCallback? onTap;

  const BookingListTile({
    super.key,
    required this.booking,
    this.showActions = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    print('🎫 BookingListTile build - bookingNumber: ${booking.bookingNumber}');
    print('🎫 BookingListTile build - room: ${booking.room.number}');
    print('🎫 BookingListTile build - room.isAvailable: ${booking.room.isAvailable} (type: ${booking.room.isAvailable.runtimeType})');
    print('🎫 BookingListTile build - showActions: $showActions (type: ${showActions.runtimeType})');
    
    // Verificar que showActions sea bool válido (aunque ya es bool no-nullable)
    final bool shouldShowActions = showActions;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(booking.status),
          child: Icon(
            _getStatusIcon(booking.status),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          'Reserva ${booking.bookingNumber}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${booking.customer.firstName} ${booking.customer.lastName}'),
            Text('Habitación ${booking.room.number} - ${booking.room.typeLabel}'),
            Text(
              '${DateFormat('dd/MM/yyyy').format(booking.checkIn)} - ${DateFormat('dd/MM/yyyy').format(booking.checkOut)}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: shouldShowActions ? _buildActionButtons(context) : null,
      ),
    );
  }

  Widget? _buildActionButtons(BuildContext context) {
    switch (booking.status) {
      case 'confirmed':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.login, color: Colors.green),
              onPressed: () {
                // TODO: Implement check-in
              },
              tooltip: 'Check-in',
            ),
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red),
              onPressed: () {
                // TODO: Implement cancel
              },
              tooltip: 'Cancelar',
            ),
          ],
        );
      case 'checked_in':
        return IconButton(
          icon: const Icon(Icons.logout, color: Colors.orange),
          onPressed: () {
            // TODO: Implement check-out
          },
          tooltip: 'Check-out',
        );
      default:
        return null;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'checked_in':
        return Colors.green;
      case 'checked_out':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      case 'no_show':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.schedule;
      case 'confirmed':
        return Icons.check_circle;
      case 'checked_in':
        return Icons.login;
      case 'checked_out':
        return Icons.logout;
      case 'cancelled':
        return Icons.cancel;
      case 'no_show':
        return Icons.person_off;
      default:
        return Icons.help;
    }
  }
}
