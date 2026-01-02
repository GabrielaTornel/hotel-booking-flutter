import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/customer_provider.dart';
import '../models/customer.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CustomerProvider>(context, listen: false).loadCustomers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
        children: [
          // Search Section
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar clientes...',
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: 'Agregar Cliente',
                  onPressed: _showAddCustomerDialog,
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ],
            ),
          ),
          
          // Customers List
          Expanded(
            child: Consumer<CustomerProvider>(
              builder: (context, customerProvider, child) {
                if (customerProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (customerProvider.error != null) {
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
                          customerProvider.error!,
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            customerProvider.clearError();
                            customerProvider.loadCustomers();
                          },
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }

                List<Customer> filteredCustomers = customerProvider.customers;
                if (_searchQuery.isNotEmpty) {
                  filteredCustomers = customerProvider.searchCustomers(_searchQuery);
                }

                if (filteredCustomers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchQuery.isNotEmpty ? Icons.search_off : Icons.people_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty ? 'No se encontraron clientes' : 'No hay clientes',
                          style: const TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredCustomers.length,
                  itemBuilder: (context, index) {
                    final customer = filteredCustomers[index];
                    return _CustomerListTile(
                      customer: customer,
                      onTap: () => _showCustomerDetails(context, customer),
                      onEdit: () => _showEditCustomerDialog(customer),
                      onDelete: () => _deleteCustomer(customer),
                    );
                  },
                );
              },
            ),
          ),
        ],
      );
  }

  void _showAddCustomerDialog() {
    showDialog(
      context: context,
      builder: (context) => _CustomerFormDialog(
        onSave: (customer) {
          Provider.of<CustomerProvider>(context, listen: false).createCustomer(customer);
        },
      ),
    );
  }

  void _showEditCustomerDialog(Customer customer) {
    showDialog(
      context: context,
      builder: (context) => _CustomerFormDialog(
        customer: customer,
        onSave: (updatedCustomer) {
          Provider.of<CustomerProvider>(context, listen: false).updateCustomer(customer.id, updatedCustomer);
        },
      ),
    );
  }

  void _showCustomerDetails(BuildContext context, Customer customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(customer.fullName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Email', customer.email),
              _buildDetailRow('Teléfono', customer.phone),
              _buildDetailRow('Documento', '${customer.documentTypeLabel}: ${customer.documentNumber}'),
              _buildDetailRow('Nacionalidad', customer.nationality),
              _buildDetailRow('Fecha de Nacimiento', customer.birthDate.toString().split(' ')[0]),
              if (customer.address != null) ...[
                const SizedBox(height: 8),
                const Text('Dirección:', style: TextStyle(fontWeight: FontWeight.w600)),
                if (customer.address!.street != null)
                  Text('  ${customer.address!.street}'),
                if (customer.address!.city != null)
                  Text('  ${customer.address!.city}'),
                if (customer.address!.country != null)
                  Text('  ${customer.address!.country}'),
                if (customer.address!.postalCode != null)
                  Text('  ${customer.address!.postalCode}'),
              ],
              if (customer.preferences != null) ...[
                const SizedBox(height: 8),
                const Text('Preferencias:', style: TextStyle(fontWeight: FontWeight.w600)),
                Text('  Fumador: ${customer.preferences!.smoking ? 'Sí' : 'No'}'),
                if (customer.preferences!.specialRequests != null)
                  Text('  Solicitudes: ${customer.preferences!.specialRequests}'),
              ],
              const SizedBox(height: 8),
              _buildDetailRow('Puntos de Fidelidad', customer.loyaltyPoints.toString()),
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

  void _deleteCustomer(Customer customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Cliente'),
        content: Text('¿Estás seguro de que quieres eliminar a ${customer.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Provider.of<CustomerProvider>(context, listen: false).deleteCustomer(customer.id);
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
            width: 120,
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
}

class _CustomerListTile extends StatelessWidget {
  final Customer customer;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CustomerListTile({
    required this.customer,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: Colors.blue,
          child: Text(
            customer.firstName[0].toUpperCase(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          customer.fullName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(customer.email),
            Text(customer.phone),
            if (customer.loyaltyPoints > 0)
              Text(
                '${customer.loyaltyPoints} puntos de fidelidad',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
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
      ),
    );
  }
}

class _CustomerFormDialog extends StatefulWidget {
  final Customer? customer;
  final Function(Customer) onSave;

  const _CustomerFormDialog({
    this.customer,
    required this.onSave,
  });

  @override
  State<_CustomerFormDialog> createState() => _CustomerFormDialogState();
}

class _CustomerFormDialogState extends State<_CustomerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _documentNumberController = TextEditingController();
  final _nationalityController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _specialRequestsController = TextEditingController();
  
  String _selectedDocumentType = 'passport';
  DateTime? _selectedBirthDate;
  bool _smoking = false;

  @override
  void initState() {
    super.initState();
    if (widget.customer != null) {
      _firstNameController.text = widget.customer!.firstName;
      _lastNameController.text = widget.customer!.lastName;
      _emailController.text = widget.customer!.email;
      _phoneController.text = widget.customer!.phone;
      _documentNumberController.text = widget.customer!.documentNumber;
      _nationalityController.text = widget.customer!.nationality;
      _birthDateController.text = widget.customer!.birthDate.toString().split(' ')[0];
      _selectedDocumentType = widget.customer!.documentType;
      _selectedBirthDate = widget.customer!.birthDate;
      _smoking = widget.customer!.preferences?.smoking ?? false;
      _specialRequestsController.text = widget.customer!.preferences?.specialRequests ?? '';
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _documentNumberController.dispose();
    _nationalityController.dispose();
    _birthDateController.dispose();
    _specialRequestsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.customer == null ? 'Nuevo Cliente' : 'Editar Cliente'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa el nombre';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(
                        labelText: 'Apellido',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa el apellido';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa el email';
                  }
                  if (!value.contains('@')) {
                    return 'Por favor ingresa un email válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa el teléfono';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedDocumentType,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Documento',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'passport', child: Text('Pasaporte')),
                        DropdownMenuItem(value: 'id', child: Text('Cédula')),
                        DropdownMenuItem(value: 'driver_license', child: Text('Licencia de Conducir')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedDocumentType = value!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _documentNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Número de Documento',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa el número de documento';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _nationalityController,
                      decoration: const InputDecoration(
                        labelText: 'Nacionalidad',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa la nacionalidad';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _birthDateController,
                      decoration: const InputDecoration(
                        labelText: 'Fecha de Nacimiento',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedBirthDate ?? DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() {
                            _selectedBirthDate = date;
                            _birthDateController.text = date.toString().split(' ')[0];
                          });
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor selecciona la fecha de nacimiento';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Fumador'),
                value: _smoking,
                onChanged: (value) {
                  setState(() {
                    _smoking = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _specialRequestsController,
                decoration: const InputDecoration(
                  labelText: 'Solicitudes Especiales',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
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
          onPressed: _saveCustomer,
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  void _saveCustomer() {
    if (_formKey.currentState!.validate()) {
      final customer = Customer(
        id: widget.customer?.id ?? '',
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        documentType: _selectedDocumentType,
        documentNumber: _documentNumberController.text.trim(),
        nationality: _nationalityController.text.trim(),
        birthDate: _selectedBirthDate!,
        address: null, // TODO: Add address fields if needed
        preferences: Preferences(
          smoking: _smoking,
          specialRequests: _specialRequestsController.text.trim().isEmpty 
              ? null 
              : _specialRequestsController.text.trim(),
        ),
        loyaltyPoints: widget.customer?.loyaltyPoints ?? 0,
        createdAt: widget.customer?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      widget.onSave(customer);
      Navigator.of(context).pop();
    }
  }
}
