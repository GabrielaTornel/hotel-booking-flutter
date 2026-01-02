import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../widgets/room_rack_view.dart';
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
  
  late final DashboardHome _dashboardHome;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _dashboardHome = DashboardHome(onNavigate: _onItemTapped);
    _screens = [
      _dashboardHome,
      const BookingsScreen(),
      const RoomsScreen(),
      const CustomersScreen(),
      const CheckInScreen(),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BookingProvider>(context, listen: false).loadDashboardStats();
      Provider.of<BookingProvider>(context, listen: false).loadBookings();
    });
  }

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.dashboard,
      label: 'Dashboard',
      route: '/dashboard',
    ),
    NavigationItem(
      icon: Icons.book_online,
      label: 'Reservas',
      route: '/bookings',
    ),
    NavigationItem(
      icon: Icons.bed,
      label: 'Habitaciones',
      route: '/rooms',
    ),
    NavigationItem(
      icon: Icons.people,
      label: 'Clientes',
      route: '/customers',
    ),
    NavigationItem(
      icon: Icons.login,
      label: 'Check-in',
      route: '/checkin',
    ),
  ];

  void _onItemTapped(int index) {
    print('🔄 Cambiando a índice: $index');
    setState(() {
      _selectedIndex = index;
    });
    // Cerrar el drawer solo si está abierto (sin lanzar error si no lo está)
    try {
      if (Scaffold.of(context).isDrawerOpen) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // El drawer no está disponible, no hacer nada
    }
  }

  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Reservas';
      case 2:
        return 'Habitaciones';
      case 3:
        return 'Clientes';
      case 4:
        return 'Check-in';
      default:
        return 'Dashboard';
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🏗️ Construyendo DashboardScreen con índice: $_selectedIndex');
    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: () {
              Provider.of<BookingProvider>(context, listen: false).loadDashboardStats();
              Provider.of<BookingProvider>(context, listen: false).loadBookings();
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      drawer: _buildDrawer(),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      width: 280,
      child: Column(
        children: [
          // Header del Drawer
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return DrawerHeader(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF802020), Color(0xFFA03030)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Icon(
                      Icons.hotel,
                      color: Colors.white,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Hotel Anthony\'s',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      authProvider.user?.email ?? 'Usuario',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          // Items de navegación
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ..._navigationItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isSelected = _selectedIndex == index;
                  
                  return ListTile(
                    leading: Icon(
                      item.icon,
                      color: isSelected
                          ? const Color(0xFF802020)
                          : Colors.grey[700],
                    ),
                    title: Text(
                      item.label,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? const Color(0xFF802020)
                            : Colors.black87,
                      ),
                    ),
                    selected: isSelected,
                    selectedTileColor: const Color(0xFF802020).withOpacity(0.1),
                    onTap: () => _onItemTapped(index),
                  );
                }),
                const Divider(),
                // Cerrar sesión
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    'Cerrar Sesión',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Provider.of<AuthProvider>(context, listen: false).logout();
                    Navigator.of(context).pushReplacementNamed('/login');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final String label;
  final String route;

  NavigationItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}

class DashboardHome extends StatefulWidget {
  final Function(int) onNavigate;
  
  const DashboardHome({super.key, required this.onNavigate});

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, BookingProvider>(
        builder: (context, authProvider, bookingProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF802020), Color(0xFFA03030)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¡Bienvenido, ${authProvider.user?.firstName ?? 'Usuario'}!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        DateFormat('EEEE, d MMMM y', 'es').format(DateTime.now()),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Estadísticas rápidas
                if (bookingProvider.dashboardStats != null) ...[
                  const Text(
                    'Estadísticas',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildStatsGrid(bookingProvider.dashboardStats!),
                  const SizedBox(height: 32),
                ],
                
                // Accesos Rápidos
                const Text(
                  'Accesos Rápidos',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                _buildQuickAccessGrid(context, widget.onNavigate),
                const SizedBox(height: 32),
                
                // Vista de Habitaciones
                const Text(
                  'Estado de Habitaciones',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 500,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                    child: RoomRackView(),
                  ),
                ),
              ],
            ),
          );
        },
      );
  }

  Widget _buildStatsGrid(Map<String, dynamic> stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 800 ? 4 : 2;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 2.0, // Aumentado para dar más espacio vertical
          children: [
            _StatCard(
              title: 'Reservas Hoy',
              value: '${stats['todayBookings'] ?? 0}',
              icon: Icons.book_online,
              color: const Color(0xFF3B82F6),
            ),
            _StatCard(
              title: 'Check-ins Pendientes',
              value: '${stats['pendingCheckIns'] ?? 0}',
              icon: Icons.login,
              color: const Color(0xFF10B981),
            ),
            _StatCard(
              title: 'Habitaciones Ocupadas',
              value: '${stats['occupiedRooms'] ?? 0}',
              icon: Icons.bed,
              color: const Color(0xFFEF4444),
            ),
            _StatCard(
              title: 'Habitaciones Disponibles',
              value: '${stats['availableRooms'] ?? 0}',
              icon: Icons.bed_outlined,
              color: const Color(0xFF10B981),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickAccessGrid(BuildContext context, Function(int) onNavigate) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1000 ? 4 : constraints.maxWidth > 600 ? 3 : 2;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 2.2,
          children: [
            _QuickAccessCard(
              title: 'Nueva Reserva',
              icon: Icons.add_circle_outline,
              color: const Color(0xFF3B82F6),
              onTap: () {
                // Navegar a Reservas (índice 1)
                onNavigate(1);
              },
            ),
            _QuickAccessCard(
              title: 'Check-in',
              icon: Icons.login,
              color: const Color(0xFF10B981),
              onTap: () {
                // Navegar a Check-in (índice 4)
                onNavigate(4);
              },
            ),
            _QuickAccessCard(
              title: 'Habitaciones',
              icon: Icons.bed,
              color: const Color(0xFF802020),
              onTap: () {
                // Navegar a Habitaciones (índice 2)
                onNavigate(2);
              },
            ),
            _QuickAccessCard(
              title: 'Clientes',
              icon: Icons.people,
              color: const Color(0xFFD4AF37),
              onTap: () {
                // Navegar a Clientes (índice 3)
                onNavigate(3);
              },
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16), // Reducido de 20 a 16
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10), // Reducido de 12 a 10
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24), // Reducido de 28 a 24
            ),
            const SizedBox(width: 12), // Reducido de 16 a 12
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min, // Agregado para evitar overflow
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 24, // Reducido de 28 a 24
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Flexible( // Cambiado de Text a Flexible para evitar overflow
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 13, // Reducido de 14 a 13
                        color: Colors.grey[600],
                      ),
                      maxLines: 2, // Permitir máximo 2 líneas
                      overflow: TextOverflow.ellipsis, // Mostrar ... si es muy largo
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickAccessCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                color,
                color.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  size: 32,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
