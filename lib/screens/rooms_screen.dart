import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/room_provider.dart';
import '../models/room.dart';

class RoomsScreen extends StatefulWidget {
  const RoomsScreen({super.key});

  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  String _selectedType = 'all';
  final List<String> _typeOptions = [
    'all',
    'single',
    'double',
    'suite',
    'family',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RoomProvider>(context, listen: false).loadRooms();
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
                const Text('Filtrar por tipo:'),
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
          ),
          
          // Rooms Grid
          Expanded(
            child: Consumer<RoomProvider>(
              builder: (context, roomProvider, child) {
                if (roomProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (roomProvider.error != null) {
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
                          roomProvider.error!,
                          style: const TextStyle(fontSize: 16),
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

                List<Room> filteredRooms = roomProvider.rooms;
                if (_selectedType != 'all') {
                  filteredRooms = roomProvider.getRoomsByType(_selectedType);
                }

                if (filteredRooms.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.bed_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No hay habitaciones',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            _showAddRoomDialog();
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Agregar Primera Habitación'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: filteredRooms.length,
                  itemBuilder: (context, index) {
                    final room = filteredRooms[index];
                    return _RoomCard(
                      room: room,
                      onTap: () => _showRoomDetails(context, room),
                      onEdit: () => _showEditRoomDialog(room),
                      onDelete: () => _deleteRoom(room),
                    );
                  },
                );
              },
            ),
          ),
        ],
      );
  }

  void _showAddRoomDialog() {
    showDialog(
      context: context,
      builder: (context) => _RoomFormDialog(
        onSave: (room) async {
          final roomProvider = Provider.of<RoomProvider>(context, listen: false);
          final newRoom = await roomProvider.createRoom(room);
          if (newRoom != null) {
            // Recargar la lista de habitaciones para asegurar que se actualice
            await roomProvider.loadRooms();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Habitación agregada exitosamente'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } else {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error al agregar habitación: ${roomProvider.error ?? "Error desconocido"}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _showEditRoomDialog(Room room) {
    showDialog(
      context: context,
      builder: (context) => _RoomFormDialog(
        room: room,
        onSave: (updatedRoom) {
          Provider.of<RoomProvider>(context, listen: false).updateRoom(room.id, updatedRoom);
        },
      ),
    );
  }

  void _showRoomDetails(BuildContext context, Room room) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Habitación ${room.number}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Tipo', room.typeLabel),
              _buildDetailRow('Precio', '${room.formattedPrice} por noche'),
              _buildDetailRow('Capacidad', '${room.capacity} personas'),
              _buildDetailRow('Piso', 'Piso ${room.floor}'),
              _buildDetailRow('Disponible', room.isAvailable ? 'Sí' : 'No'),
              if (room.description != null)
                _buildDetailRow('Descripción', room.description!),
              if (room.amenities.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('Amenidades:', style: TextStyle(fontWeight: FontWeight.w600)),
                ...room.amenities.map((amenity) => Padding(
                  padding: const EdgeInsets.only(left: 16, top: 4),
                  child: Text('• $amenity'),
                )),
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

  void _deleteRoom(Room room) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Habitación'),
        content: Text('¿Estás seguro de que quieres eliminar la habitación ${room.number}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Provider.of<RoomProvider>(context, listen: false).deleteRoom(room.id);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
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
}

class _RoomCard extends StatelessWidget {
  final Room room;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RoomCard({
    required this.room,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Habitación ${room.number}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') onEdit();
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 16),
                            SizedBox(width: 8),
                            Text('Editar'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 16, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Eliminar', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                room.typeLabel,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                '${room.formattedPrice}/noche',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Icon(
                    Icons.people,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${room.capacity}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: room.isAvailable ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      room.isAvailable ? 'Disponible' : 'Ocupada',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomFormDialog extends StatefulWidget {
  final Room? room;
  final Function(Room) onSave;

  const _RoomFormDialog({
    this.room,
    required this.onSave,
  });

  @override
  State<_RoomFormDialog> createState() => _RoomFormDialogState();
}

class _RoomFormDialogState extends State<_RoomFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _numberController = TextEditingController();
  final _priceController = TextEditingController();
  final _capacityController = TextEditingController();
  final _floorController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedType = 'single';
  String _selectedCurrency = 'USD';
  bool _isAvailable = true;
  final List<String> _amenities = [];

  @override
  void initState() {
    super.initState();
    if (widget.room != null) {
      _numberController.text = widget.room!.number;
      _priceController.text = widget.room!.price.toString();
      _capacityController.text = widget.room!.capacity.toString();
      _floorController.text = widget.room!.floor.toString();
      _descriptionController.text = widget.room!.description ?? '';
      _selectedType = widget.room!.type;
      _selectedCurrency = widget.room!.currency;
      _isAvailable = widget.room!.isAvailable;
      _amenities.addAll(widget.room!.amenities);
    }
  }

  @override
  void dispose() {
    _numberController.dispose();
    _priceController.dispose();
    _capacityController.dispose();
    _floorController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.room == null ? 'Nueva Habitación' : 'Editar Habitación'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _numberController,
                decoration: const InputDecoration(
                  labelText: 'Número de Habitación',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa el número de habitación';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Habitación',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'single', child: Text('Individual')),
                  DropdownMenuItem(value: 'double', child: Text('Doble')),
                  DropdownMenuItem(value: 'suite', child: Text('Suite')),
                  DropdownMenuItem(value: 'family', child: Text('Familiar')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _priceController,
                      decoration: InputDecoration(
                        labelText: 'Precio',
                        border: const OutlineInputBorder(),
                        prefixText: _selectedCurrency == 'USD' ? '\$' : 'S/',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa el precio';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Por favor ingresa un precio válido';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCurrency,
                      decoration: const InputDecoration(
                        labelText: 'Moneda',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'USD', child: Text('USD')),
                        DropdownMenuItem(value: 'SOL', child: Text('SOL')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCurrency = value!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _capacityController,
                      decoration: const InputDecoration(
                        labelText: 'Capacidad',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa la capacidad';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Por favor ingresa una capacidad válida';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _floorController,
                decoration: const InputDecoration(
                  labelText: 'Piso',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa el piso';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Por favor ingresa un piso válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Disponible'),
                value: _isAvailable,
                onChanged: (value) {
                  setState(() {
                    _isAvailable = value;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _saveRoom,
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  void _saveRoom() {
    if (_formKey.currentState!.validate()) {
      final room = Room(
        id: widget.room?.id ?? '',
        number: _numberController.text.trim(),
        type: _selectedType,
        price: double.parse(_priceController.text),
        currency: _selectedCurrency,
        capacity: int.parse(_capacityController.text),
        amenities: _amenities,
        images: widget.room?.images ?? [],
        isAvailable: _isAvailable,
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        floor: int.parse(_floorController.text),
        createdAt: widget.room?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      widget.onSave(room);
      Navigator.of(context).pop();
    }
  }
}
