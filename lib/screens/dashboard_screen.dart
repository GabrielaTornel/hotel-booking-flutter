import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../widgets/stat_card.dart';
import '../widgets/booking_list_tile.dart';
import 'bookings_screen.dart';
import 'rooms_screen.dart';
import 'customers_screen.dart';
import 'checkin_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardHome(),
    const BookingsScreen(),
    const RoomsScreen(),
    const CustomersScreen(),
    const CheckInScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BookingProvider>(context, listen: false).loadDashboardStats();
      Provider.of<BookingProvider>(context, listen: false).loadBookings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_online),
            label: 'Reservas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bed),
            label: 'Habitaciones',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Clientes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.login),
            label: 'Check-in',
          ),
        ],
      ),
    );
  }
}

class DashboardHome extends StatefulWidget {
  const DashboardHome({super.key});

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<BookingProvider>(context, listen: false).loadDashboardStats();
              Provider.of<BookingProvider>(context, listen: false).loadBookings();
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                Provider.of<AuthProvider>(context, listen: false).logout();
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Cerrar Sesión'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer2<BookingProvider, AuthProvider>(
        builder: (context, bookingProvider, authProvider, child) {
          if (bookingProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final stats = bookingProvider.dashboardStats;
          final todayCheckIns = bookingProvider.getTodayCheckIns();
          final todayCheckOuts = bookingProvider.getTodayCheckOuts();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Message
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF1E40AF)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¡Bienvenido, ${authProvider.user?.firstName}!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                          DateFormat('EEEE, d MMMM y', 'es').format(DateTime.now()),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Stats Cards
                if (stats != null) ...[
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: 'Total Reservas',
                          value: stats['totalBookings']?.toString() ?? '0',
                          icon: Icons.book_online,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          title: 'Habitaciones',
                          value: stats['totalRooms']?.toString() ?? '0',
                          icon: Icons.bed,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: 'Ocupación',
                          value: '${stats['checkedInBookings']?.toString() ?? '0'}/${stats['totalRooms']?.toString() ?? '0'}',
                          icon: Icons.hotel,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          title: 'Ingresos Mes',
                          value: '\$${NumberFormat('#,##0').format(stats['monthlyRevenue'] ?? 0)}',
                          icon: Icons.attach_money,
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],

                // Room Status Section
                _buildRoomStatusSection(bookingProvider),
                const SizedBox(height: 24),

                // Check-outs Soon Section
                _buildCheckOutsSoonSection(bookingProvider),
                const SizedBox(height: 24),

                // Today's Activities
                const Text(
                  'Actividades de Hoy',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Check-ins Today
                if (todayCheckIns.isNotEmpty) ...[
                  const Text(
                    'Check-ins Programados',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...todayCheckIns.map((booking) => BookingListTile(
                    booking: booking,
                    showActions: true,
                  )),
                  const SizedBox(height: 16),
                ],

                // Check-outs Today
                if (todayCheckOuts.isNotEmpty) ...[
                  const Text(
                    'Check-outs Programados',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...todayCheckOuts.map((booking) => BookingListTile(
                    booking: booking,
                    showActions: true,
                  )),
                  const SizedBox(height: 16),
                ],

                // Quick Actions
                const Text(
                  'Acciones Rápidas',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _QuickActionCard(
                        title: 'Nueva Reserva',
                        icon: Icons.add_circle,
                        color: Colors.blue,
                        onTap: () {
                          // TODO: Navigate to create booking
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickActionCard(
                        title: 'Check-in',
                        icon: Icons.login,
                        color: Colors.green,
                        onTap: () {
                          // Navigate to check-in screen
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const CheckInScreen()),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _QuickActionCard(
                        title: 'Check-out',
                        icon: Icons.logout,
                        color: Colors.orange,
                        onTap: () {
                          // TODO: Navigate to check-out
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickActionCard(
                        title: 'Reportes',
                        icon: Icons.analytics,
                        color: Colors.purple,
                        onTap: () {
                          // TODO: Navigate to reports
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRoomStatusSection(BookingProvider bookingProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Estado de Habitaciones',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _RoomStatusCard(
                title: 'Disponibles',
                count: _getAvailableRoomsCount(bookingProvider),
                icon: Icons.bed,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _RoomStatusCard(
                title: 'Ocupadas',
                count: _getOccupiedRoomsCount(bookingProvider),
                icon: Icons.person,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCheckOutsSoonSection(BookingProvider bookingProvider) {
    final checkOutsSoon = _getCheckOutsSoon(bookingProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Habitaciones por Salir',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (checkOutsSoon.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'No hay habitaciones programadas para salir pronto',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          )
        else
          ...checkOutsSoon.map((booking) => _CheckOutSoonCard(
            booking: booking,
            onRenew: () => _showRenewalDialog(context, booking),
          )),
      ],
    );
  }

  int _getAvailableRoomsCount(BookingProvider bookingProvider) {
    // Simulación - en la realidad vendría del provider
    return 8;
  }

  int _getOccupiedRoomsCount(BookingProvider bookingProvider) {
    // Simulación - en la realidad vendría del provider
    return 12;
  }

  List<dynamic> _getCheckOutsSoon(BookingProvider bookingProvider) {
    // Simulación - en la realidad vendría del provider
    return bookingProvider.getTodayCheckOuts();
  }

  void _showRenewalDialog(BuildContext context, dynamic booking) {
    DateTime newCheckOutDate = booking.checkOut.add(const Duration(days: 1));
    
    showDialog(
      context: context,
      builder: (dialogContext) => _RenewalDialog(
        booking: booking,
        initialDate: newCheckOutDate,
        onRenew: (newDate) {
          // TODO: Implement renewal logic
          Navigator.pop(dialogContext);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Renovación programada para ${DateFormat('dd/MM/yyyy').format(newDate)}'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomStatusCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color color;

  const _RoomStatusCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckOutSoonCard extends StatelessWidget {
  final dynamic booking;
  final VoidCallback onRenew;

  const _CheckOutSoonCard({
    required this.booking,
    required this.onRenew,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Habitación ${booking.room.number}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${booking.customer.firstName} ${booking.customer.lastName}',
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    'Check-out: ${DateFormat('dd/MM/yyyy HH:mm').format(booking.checkOut)}',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: onRenew,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Renovar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RenewalDialog extends StatefulWidget {
  final dynamic booking;
  final DateTime initialDate;
  final Function(DateTime) onRenew;

  const _RenewalDialog({
    required this.booking,
    required this.initialDate,
    required this.onRenew,
  });

  @override
  State<_RenewalDialog> createState() => _RenewalDialogState();
}

class _RenewalDialogState extends State<_RenewalDialog> {
  late DateTime selectedDate;
  bool _isCheckingAvailability = false;
  bool _isRenewing = false;
  String? _availabilityError;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialDate;
  }

  Future<void> _checkAvailability() async {
    if (selectedDate.isBefore(widget.booking.checkOut)) {
      setState(() {
        _availabilityError = 'La nueva fecha debe ser posterior al check-out actual';
      });
      return;
    }

    setState(() {
      _isCheckingAvailability = true;
      _availabilityError = null;
    });

    try {
      final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
      final isAvailable = await bookingProvider.checkRoomAvailability(
        widget.booking.room.id,
        widget.booking.checkIn,
        selectedDate,
        excludeBookingId: widget.booking.id,
      );

      setState(() {
        _isCheckingAvailability = false;
        if (!isAvailable) {
          _availabilityError = 'La habitación no está disponible para las fechas seleccionadas';
        }
      });
    } catch (e) {
      setState(() {
        _isCheckingAvailability = false;
        _availabilityError = 'Error verificando disponibilidad: $e';
      });
    }
  }

  Future<void> _performRenewal() async {
    setState(() {
      _isRenewing = true;
    });

    try {
      final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
      final updatedBooking = await bookingProvider.renewBooking(widget.booking.id, selectedDate);
      
      if (updatedBooking != null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Renovación exitosa hasta ${DateFormat('dd/MM/yyyy').format(selectedDate)}'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onRenew(selectedDate);
      } else {
        setState(() {
          _availabilityError = 'Error al renovar la reserva';
        });
      }
    } catch (e) {
      setState(() {
        _availabilityError = 'Error al renovar: $e';
      });
    } finally {
      setState(() {
        _isRenewing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Renovar Habitación'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cliente: ${widget.booking.customer.firstName} ${widget.booking.customer.lastName}'),
          Text('Habitación: ${widget.booking.room.number}'),
          const SizedBox(height: 16),
          const Text(
            'Nueva fecha de check-out:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _isRenewing ? null : () async {
              final date = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: widget.booking.checkOut,
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null) {
                setState(() {
                  selectedDate = date;
                  _availabilityError = null;
                });
                await _checkAvailability();
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today),
                  const SizedBox(width: 8),
                  Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                ],
              ),
            ),
          ),
          if (_isCheckingAvailability) ...[
            const SizedBox(height: 8),
            const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('Verificando disponibilidad...'),
              ],
            ),
          ],
          if (_availabilityError != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red.shade200),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red.shade600, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _availabilityError!,
                      style: TextStyle(color: Colors.red.shade600, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isRenewing ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isRenewing || _isCheckingAvailability || _availabilityError != null
              ? null
              : _performRenewal,
          child: _isRenewing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Renovar'),
        ),
      ],
    );
  }
}
