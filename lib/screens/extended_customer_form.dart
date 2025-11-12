import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../models/country.dart';
import '../models/department.dart';
import '../services/api_service.dart';

class ExtendedCustomerForm extends StatefulWidget {
  final Customer? customer;
  final Function(Customer) onSave;

  const ExtendedCustomerForm({
    this.customer,
    required this.onSave,
    super.key,
  });

  @override
  State<ExtendedCustomerForm> createState() => _ExtendedCustomerFormState();
}

class _ExtendedCustomerFormState extends State<ExtendedCustomerForm> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 4;

  // Controllers básicos
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _documentNumberController = TextEditingController();
  final _nationalityController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _specialRequestsController = TextEditingController();

  // Controllers nuevos
  final _travelPurposeController = TextEditingController();
  final _rucController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _licensePlateController = TextEditingController();

  // Variables de estado
  String _selectedDocumentType = 'passport';
  DateTime? _selectedBirthDate;
  bool _smoking = false;
  String _gender = 'prefer_not_to_say';
  
  // Información de facturación
  bool _requiresInvoice = false;
  bool _requiresReceipt = false;
  bool _requiresRuc = false;
  
  // Información de estacionamiento
  bool _requiresParking = false;
  
  // Información de origen
  String? _selectedCountry;
  String? _selectedDepartment;
  
  // Listas de datos
  List<Country> _countries = [];
  List<Department> _departments = [];
  List<Companion> _companions = [];
  
  // bool _isLoadingCountries = false;
  // bool _isLoadingDepartments = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    if (widget.customer != null) {
      _loadCustomerData();
    }
  }

  void _loadInitialData() {
    _loadCountries();
  }

  void _loadCustomerData() {
    final customer = widget.customer!;
    _firstNameController.text = customer.firstName;
    _lastNameController.text = customer.lastName;
    _emailController.text = customer.email;
    _phoneController.text = customer.phone;
    _documentNumberController.text = customer.documentNumber;
    _nationalityController.text = customer.nationality;
    _birthDateController.text = customer.birthDate.toString().split(' ')[0];
    _selectedDocumentType = customer.documentType;
    _selectedBirthDate = customer.birthDate;
    _smoking = customer.preferences?.smoking ?? false;
    _specialRequestsController.text = customer.preferences?.specialRequests ?? '';
    _gender = customer.gender;
    _travelPurposeController.text = customer.travelPurpose ?? '';
    
    // Información de facturación
    _requiresInvoice = customer.billingInfo?.requiresInvoice ?? false;
    _requiresReceipt = customer.billingInfo?.requiresReceipt ?? false;
    _requiresRuc = customer.billingInfo?.ruc != null;
    _rucController.text = customer.billingInfo?.ruc ?? '';
    _businessNameController.text = customer.billingInfo?.businessName ?? '';
    
    // Información de estacionamiento
    _requiresParking = customer.parkingInfo?.requiresParking ?? false;
    _licensePlateController.text = customer.parkingInfo?.licensePlate ?? '';
    
    // Información de origen
    _selectedCountry = customer.originInfo?.country;
    _selectedDepartment = customer.originInfo?.department;
    
    // Acompañantes
    _companions = List.from(customer.companions);
    
    if (_selectedCountry == 'Peru') {
      _loadDepartments();
    }
  }

  Future<void> _loadCountries() async {
    try {
      final response = await ApiService.getCountries();
      if (response['success']) {
        setState(() {
          _countries = (response['data']['countries'] as List)
              .map((c) => Country.fromJson(c))
              .toList();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando países: $e')),
      );
    }
  }

  Future<void> _loadDepartments() async {
    try {
      final response = await ApiService.getDepartments();
      if (response['success']) {
        setState(() {
          _departments = (response['data']['departments'] as List)
              .map((d) => Department.fromJson(d))
              .toList();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando departamentos: $e')),
      );
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
    _travelPurposeController.dispose();
    _rucController.dispose();
    _businessNameController.dispose();
    _licensePlateController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customer == null ? 'Nuevo Cliente' : 'Editar Cliente'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: LinearProgressIndicator(
            value: (_currentPage + 1) / _totalPages,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: PageView(
          controller: _pageController,
          onPageChanged: (page) {
            setState(() {
              _currentPage = page;
            });
          },
          children: [
            _buildBasicInfoPage(),
            _buildBillingInfoPage(),
            _buildAdditionalInfoPage(),
            _buildCompanionsPage(),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_currentPage > 0)
              ElevatedButton(
                onPressed: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: const Text('Anterior'),
              )
            else
              const SizedBox(),
            if (_currentPage < _totalPages - 1)
              ElevatedButton(
                onPressed: () {
                  if (_validateCurrentPage()) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                child: const Text('Siguiente'),
              )
            else
              ElevatedButton(
                onPressed: _saveCustomer,
                child: const Text('Guardar'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información Básica',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          
          // Nombre y Apellido
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre *',
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
                    labelText: 'Apellido *',
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
          
          // Email y Teléfono
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email *',
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
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono *',
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
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Tipo de documento y número
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedDocumentType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de Documento *',
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
                    labelText: 'Número de Documento *',
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
          
          // Nacionalidad y Fecha de nacimiento
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _nationalityController,
                  decoration: const InputDecoration(
                    labelText: 'Nacionalidad *',
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
                    labelText: 'Fecha de Nacimiento *',
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
          
          // Género
          DropdownButtonFormField<String>(
            value: _gender,
            decoration: const InputDecoration(
              labelText: 'Género',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'M', child: Text('Masculino')),
              DropdownMenuItem(value: 'F', child: Text('Femenino')),
              DropdownMenuItem(value: 'prefer_not_to_say', child: Text('Prefiero no contestar')),
            ],
            onChanged: (value) {
              setState(() {
                _gender = value!;
              });
            },
          ),
          const SizedBox(height: 16),
          
          // Fumador
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
          
          // Solicitudes especiales
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
    );
  }

  Widget _buildBillingInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información de Facturación',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          
          // Requiere boleta
          SwitchListTile(
            title: const Text('Requiere Boleta'),
            value: _requiresReceipt,
            onChanged: (value) {
              setState(() {
                _requiresReceipt = value;
              });
            },
          ),
          
          // Requiere factura
          SwitchListTile(
            title: const Text('Requiere Factura'),
            value: _requiresInvoice,
            onChanged: (value) {
              setState(() {
                _requiresInvoice = value;
                if (!value) {
                  _requiresRuc = false;
                  _rucController.clear();
                  _businessNameController.clear();
                }
              });
            },
          ),
          
          // Si requiere factura, mostrar campos RUC
          if (_requiresInvoice) ...[
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Requiere RUC'),
              value: _requiresRuc,
              onChanged: (value) {
                setState(() {
                  _requiresRuc = value;
                  if (!value) {
                    _rucController.clear();
                    _businessNameController.clear();
                  }
                });
              },
            ),
            
            if (_requiresRuc) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _rucController,
                decoration: const InputDecoration(
                  labelText: 'RUC *',
                  border: OutlineInputBorder(),
                ),
                validator: _requiresRuc ? (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa el RUC';
                  }
                  return null;
                } : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _businessNameController,
                decoration: const InputDecoration(
                  labelText: 'Razón Social *',
                  border: OutlineInputBorder(),
                ),
                validator: _requiresRuc ? (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa la razón social';
                  }
                  return null;
                } : null,
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información Adicional',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          
          // Motivo de viaje
          TextFormField(
            controller: _travelPurposeController,
            decoration: const InputDecoration(
              labelText: 'Motivo de Viaje',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 20),
          
          // Estacionamiento
          const Text(
            'Estacionamiento',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          SwitchListTile(
            title: const Text('Requiere Cochera'),
            value: _requiresParking,
            onChanged: (value) {
              setState(() {
                _requiresParking = value;
                if (!value) {
                  _licensePlateController.clear();
                }
              });
            },
          ),
          
          if (_requiresParking) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _licensePlateController,
              decoration: const InputDecoration(
                labelText: 'Placa del Vehículo (Opcional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
          
          const SizedBox(height: 20),
          
          // Lugar de procedencia
          const Text(
            'Lugar de Procedencia',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          
          // País
          DropdownButtonFormField<String>(
            value: _selectedCountry,
            decoration: const InputDecoration(
              labelText: 'País',
              border: OutlineInputBorder(),
            ),
            items: _countries.map((country) {
              return DropdownMenuItem(
                value: country.name,
                child: Text(country.name),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCountry = value;
                _selectedDepartment = null;
                if (value == 'Peru') {
                  _loadDepartments();
                } else {
                  _departments.clear();
                }
              });
            },
          ),
          
          // Departamento (solo si es Perú)
          if (_selectedCountry == 'Peru') ...[
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedDepartment,
              decoration: const InputDecoration(
                labelText: 'Departamento',
                border: OutlineInputBorder(),
              ),
              items: _departments.map((department) {
                return DropdownMenuItem(
                  value: department.name,
                  child: Text(department.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDepartment = value;
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompanionsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Acompañantes',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: _addCompanion,
                icon: const Icon(Icons.add),
                label: const Text('Agregar'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          if (_companions.isEmpty)
            const Center(
              child: Text(
                'No hay acompañantes agregados',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ..._companions.asMap().entries.map((entry) {
              final index = entry.key;
              final companion = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Acompañante ${index + 1}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            onPressed: () => _removeCompanion(index),
                            icon: const Icon(Icons.delete, color: Colors.red),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Tipo: ${companion.documentType}'),
                      Text('Número: ${companion.documentNumber}'),
                      Text('Nacionalidad: ${companion.nationality}'),
                      Text('Género: ${companion.gender}'),
                      Text('Fecha Nacimiento: ${companion.birthDate.toString().split(' ')[0]}'),
                    ],
                  ),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  void _addCompanion() {
    showDialog(
      context: context,
      builder: (context) => _CompanionDialog(
        onSave: (companion) {
          setState(() {
            _companions.add(companion);
          });
        },
      ),
    );
  }

  void _removeCompanion(int index) {
    setState(() {
      _companions.removeAt(index);
    });
  }

  bool _validateCurrentPage() {
    switch (_currentPage) {
      case 0:
        return _formKey.currentState!.validate();
      case 1:
        return true; // Billing info is optional
      case 2:
        return true; // Additional info is optional
      case 3:
        return true; // Companions are optional
      default:
        return true;
    }
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
        address: null,
        preferences: Preferences(
          smoking: _smoking,
          specialRequests: _specialRequestsController.text.trim().isEmpty 
              ? null 
              : _specialRequestsController.text.trim(),
        ),
        billingInfo: (_requiresInvoice || _requiresReceipt) ? BillingInfo(
          requiresInvoice: _requiresInvoice,
          requiresReceipt: _requiresReceipt,
          ruc: _requiresRuc ? _rucController.text.trim() : null,
          businessName: _requiresRuc ? _businessNameController.text.trim() : null,
        ) : null,
        parkingInfo: _requiresParking ? ParkingInfo(
          requiresParking: _requiresParking,
          licensePlate: _licensePlateController.text.trim().isEmpty 
              ? null 
              : _licensePlateController.text.trim(),
        ) : null,
        travelPurpose: _travelPurposeController.text.trim().isEmpty 
            ? null 
            : _travelPurposeController.text.trim(),
        gender: _gender,
        originInfo: _selectedCountry != null ? OriginInfo(
          country: _selectedCountry,
          department: _selectedCountry == 'Peru' ? _selectedDepartment : null,
        ) : null,
        companions: _companions,
        loyaltyPoints: widget.customer?.loyaltyPoints ?? 0,
        createdAt: widget.customer?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      widget.onSave(customer);
      Navigator.of(context).pop();
    }
  }
}

class _CompanionDialog extends StatefulWidget {
  final Function(Companion) onSave;

  const _CompanionDialog({required this.onSave});

  @override
  State<_CompanionDialog> createState() => _CompanionDialogState();
}

class _CompanionDialogState extends State<_CompanionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _documentNumberController = TextEditingController();
  final _nationalityController = TextEditingController();
  final _birthDateController = TextEditingController();
  
  String _selectedDocumentType = 'passport';
  String _gender = 'prefer_not_to_say';
  DateTime? _selectedBirthDate;

  @override
  void dispose() {
    _documentNumberController.dispose();
    _nationalityController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agregar Acompañante'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedDocumentType,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Documento *',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'passport', child: Text('Pasaporte')),
                  DropdownMenuItem(value: 'dni', child: Text('DNI')),
                  DropdownMenuItem(value: 'ce', child: Text('CE')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedDocumentType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _documentNumberController,
                decoration: const InputDecoration(
                  labelText: 'Número de Documento *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa el número de documento';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nationalityController,
                decoration: const InputDecoration(
                  labelText: 'Nacionalidad *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa la nacionalidad';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _birthDateController,
                decoration: const InputDecoration(
                  labelText: 'Fecha de Nacimiento *',
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
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _gender,
                decoration: const InputDecoration(
                  labelText: 'Género',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'M', child: Text('Masculino')),
                  DropdownMenuItem(value: 'F', child: Text('Femenino')),
                  DropdownMenuItem(value: 'prefer_not_to_say', child: Text('Prefiero no contestar')),
                ],
                onChanged: (value) {
                  setState(() {
                    _gender = value!;
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
          onPressed: _saveCompanion,
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  void _saveCompanion() {
    if (_formKey.currentState!.validate()) {
      final companion = Companion(
        documentType: _selectedDocumentType,
        documentNumber: _documentNumberController.text.trim(),
        birthDate: _selectedBirthDate!,
        gender: _gender,
        nationality: _nationalityController.text.trim(),
      );

      widget.onSave(companion);
      Navigator.of(context).pop();
    }
  }
}
