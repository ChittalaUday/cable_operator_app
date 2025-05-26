import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/customer_model.dart';
import '../../services/customer_service.dart';
import '../../services/config_service.dart';

class AddEditCustomerScreen extends StatefulWidget {
  final Customer? customer;

  const AddEditCustomerScreen({Key? key, this.customer}) : super(key: key);

  @override
  _AddEditCustomerScreenState createState() => _AddEditCustomerScreenState();
}

class _AddEditCustomerScreenState extends State<AddEditCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = Uuid();
  final CustomerService _customerService = CustomerService();
  final ConfigService _configService = ConfigService();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _setupBoxSerialController;
  late TextEditingController _vcNumberController;

  DateTime? _connectionDate;
  DateTime? _activationDate;
  DateTime? _deactivationDate;
  bool _isActive = true;
  bool _isLoading = false;
  bool _isInitialized = false;

  String? _selectedCategory;
  String? _selectedBoxType;
  String? _selectedPackage;
  double _packageAmount = 0.0;

  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _boxTypes = [];
  List<Map<String, dynamic>> _packages = [];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeData();
  }

  void _initializeControllers() {
    final customer = widget.customer;
    _nameController = TextEditingController(text: customer?.name ?? '');
    _phoneController = TextEditingController(text: customer?.phone ?? '');
    _addressController = TextEditingController(text: customer?.address ?? '');
    _setupBoxSerialController = TextEditingController(
      text: customer?.setupBoxSerial ?? '',
    );
    _vcNumberController = TextEditingController(text: customer?.vcNumber ?? '');

    _connectionDate = customer?.connectionDate ?? DateTime.now();
    _activationDate = customer?.activationDate;
    _deactivationDate = customer?.deactivationDate;
    _isActive = customer?.isActive ?? true;

    if (customer != null) {
      _selectedCategory = customer.category;
      _selectedBoxType = customer.boxType;
      _selectedPackage = customer.monthlyPlan;
      _packageAmount = customer.packageAmount;
    }
  }

  Future<void> _initializeData() async {
    try {
      setState(() => _isLoading = true);

      // Load all configurations in parallel
      final futures = await Future.wait([
        _configService.getCategories().first,
        _configService.getBoxTypes().first,
        _configService.getPackages().first,
      ]);

      if (mounted) {
        setState(() {
          _categories = futures[0];
          _boxTypes = futures[1];
          _packages = futures[2];

          // Set initial values if not already set
          if (_selectedCategory == null && _categories.isNotEmpty) {
            _selectedCategory = _categories.first['name'];
          }
          if (_selectedBoxType == null && _boxTypes.isNotEmpty) {
            _selectedBoxType = _boxTypes.first['name'];
          }
          if (_selectedPackage == null && _packages.isNotEmpty) {
            _selectedPackage = _packages.first['name'];
            _packageAmount =
                (_packages.first['amount'] as num?)?.toDouble() ?? 0.0;
          }
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _setupBoxSerialController.dispose();
    _vcNumberController.dispose();
    super.dispose();
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final customer = Customer(
        id: widget.customer?.id ?? _uuid.v4(),
        name: _nameController.text,
        phone: _phoneController.text,
        address: _addressController.text,
        connectionDate: _connectionDate!,
        activationDate: _activationDate,
        deactivationDate: _deactivationDate,
        monthlyPlan: _selectedPackage!,
        setupBoxSerial: _setupBoxSerialController.text,
        vcNumber: _vcNumberController.text,
        category: _selectedCategory!,
        isActive: _isActive,
        packageAmount: _packageAmount,
        boxType: _selectedBoxType!,
      );

      if (widget.customer != null) {
        await _customerService.updateCustomer(customer);
      } else {
        await _customerService.addCustomer(customer);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.customer != null
                  ? 'Customer updated successfully'
                  : 'Customer added successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectDate(BuildContext context, String type) async {
    DateTime? initialDate;
    DateTime? firstDate;
    DateTime? lastDate;

    switch (type) {
      case 'connection':
        initialDate = _connectionDate ?? DateTime.now();
        firstDate = DateTime(2020);
        lastDate = DateTime(2100);
        break;
      case 'activation':
        if (_connectionDate == null) {
          _showSnackBar('Please select connection date first', Colors.orange);
          return;
        }
        initialDate = _activationDate ?? _connectionDate;
        firstDate = _connectionDate;
        lastDate = DateTime(2100);
        break;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate!,
      firstDate: firstDate!,
      lastDate: lastDate!,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).primaryColor,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        switch (type) {
          case 'connection':
            _connectionDate = picked;
            if (_isActive) {
              _activationDate = picked;
              _deactivationDate = _calculateDeactivationDate(_activationDate!);
            } else {
              _activationDate = null;
              _deactivationDate = null;
            }
            break;
          case 'activation':
            _activationDate = picked;
            if (_selectedPackage != null) {
              _deactivationDate = _calculateDeactivationDate(picked);
              _showSnackBar(
                'Deactivation date set to ${_formatDate(_deactivationDate)} based on package duration',
                Colors.green,
              );
            }
            break;
        }
      });
    }
  }

  void _handleActiveStatusChange(bool value) {
    final oldStatus = _isActive;
    final oldActivationDate = _activationDate;
    final oldDeactivationDate = _deactivationDate;

    final newActivationDate = value ? DateTime.now() : null;
    final newDeactivationDate =
        value ? _calculateDeactivationDate(newActivationDate!) : null;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(value ? 'Activate Customer' : 'Deactivate Customer'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value
                      ? 'Are you sure you want to activate this customer?'
                      : 'Are you sure you want to deactivate this customer?',
                ),
                const SizedBox(height: 16),
                Text(
                  'Changes to be made:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                _buildChangeRow(
                  'Status',
                  oldStatus ? 'Active' : 'Inactive',
                  value ? 'Active' : 'Inactive',
                ),
                _buildChangeRow(
                  'Activation Date',
                  oldActivationDate != null
                      ? _formatDate(oldActivationDate)
                      : 'Not set',
                  newActivationDate != null
                      ? _formatDate(newActivationDate)
                      : 'Not set',
                ),
                _buildChangeRow(
                  'Deactivation Date',
                  oldDeactivationDate != null
                      ? _formatDate(oldDeactivationDate)
                      : 'Not set',
                  newDeactivationDate != null
                      ? _formatDate(newDeactivationDate)
                      : 'Not set',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  _updateStatus(value);
                },
                child: const Text('Confirm'),
              ),
            ],
          ),
    );
  }

  Widget _buildChangeRow(String label, String oldValue, String newValue) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Text(
                  oldValue,
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const Icon(Icons.arrow_forward, size: 16),
                Text(
                  newValue,
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  DateTime _calculateDeactivationDate(DateTime fromDate) {
    if (_selectedPackage == null || _packages.isEmpty) {
      return fromDate.add(const Duration(days: 30)); // Default to 30 days
    }

    final package = _packages.firstWhere(
      (p) => p['name'] == _selectedPackage,
      orElse: () => {'days': 30},
    );

    final days = (package['days'] as num?)?.toInt() ?? 30;
    return fromDate.add(Duration(days: days));
  }

  void _updateStatus(bool value) {
    setState(() {
      _isActive = value;
      if (value) {
        _activationDate = DateTime.now();
        _deactivationDate = _calculateDeactivationDate(_activationDate!);
      } else {
        _activationDate = null;
        _deactivationDate = null;
      }
    });
  }

  void _updateDatesBasedOnPackage() {
    if (_connectionDate == null ||
        _selectedPackage == null ||
        _packages.isEmpty)
      return;

    final package = _packages.firstWhere(
      (p) => p['name'] == _selectedPackage,
      orElse: () => {'days': 30},
    );

    final days = (package['days'] as num?)?.toInt() ?? 30;

    setState(() {
      if (_isActive) {
        if (_activationDate == null) {
          _activationDate = _connectionDate;
        }
        // Always calculate deactivation date when active
        _deactivationDate = _activationDate!.add(Duration(days: days));
      }
    });
  }

  void _onPackageChanged(String? value) {
    if (value != null) {
      final package = _packages.firstWhere(
        (p) => p['name'] == value,
        orElse: () => {'amount': 0.0, 'days': 30},
      );

      setState(() {
        _selectedPackage = value;
        _packageAmount = (package['amount'] as num?)?.toDouble() ?? 0.0;

        // Recalculate deactivation date if activation date exists
        if (_activationDate != null) {
          final oldDeactivationDate = _deactivationDate;
          _deactivationDate = _calculateDeactivationDate(_activationDate!);

          // Show a snackbar if the deactivation date changed
          if (oldDeactivationDate != _deactivationDate) {
            _showSnackBar(
              'Deactivation date updated to ${_formatDate(_deactivationDate)} based on new package',
              Colors.blue,
            );
          }
        }
      });
    }
  }

  Widget _buildPackageDropdown() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'Monthly Plan',
        prefixIcon: Icon(Icons.payments_outlined, color: colorScheme.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      value: _selectedPackage,
      isExpanded: true,
      items:
          _packages.map((package) {
            return DropdownMenuItem<String>(
              value: package['name'] as String,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      package['name'] as String,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '₹${package['amount']}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${package['days']}d',
                    style: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
      onChanged: _onPackageChanged,
      validator:
          (value) => value == null ? 'Please select a monthly plan' : null,
    );
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select Date';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading && !_isInitialized) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                strokeWidth: 3,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Loading...',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          widget.customer != null ? 'Edit Customer' : 'Add Customer',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        toolbarHeight: 72,
        actions: [
          if (widget.customer != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text('Delete Customer'),
                        content: const Text(
                          'Are you sure you want to delete this customer? This action cannot be undone.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () async {
                              try {
                                await _customerService.deleteCustomer(
                                  widget.customer!.id,
                                );
                                if (mounted) {
                                  Navigator.pop(context); // Close dialog
                                  Navigator.pop(
                                    context,
                                  ); // Return to previous screen
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Customer deleted successfully',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  Navigator.pop(context); // Close dialog
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Error deleting customer: $e',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                );
              },
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.person_outline_rounded,
                            color: colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Basic Information',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildModernTextField(
                      controller: _nameController,
                      labelText: 'Full Name',
                      prefixIcon: Icons.person_outline_rounded,
                      validator:
                          (value) =>
                              value?.isEmpty == true
                                  ? 'Name is required'
                                  : null,
                    ),
                    const SizedBox(height: 16),
                    _buildModernTextField(
                      controller: _phoneController,
                      labelText: 'Phone Number',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator:
                          (value) =>
                              value?.isEmpty == true
                                  ? 'Phone number is required'
                                  : null,
                    ),
                    const SizedBox(height: 16),
                    _buildModernTextField(
                      controller: _addressController,
                      labelText: 'Address',
                      prefixIcon: Icons.location_on_outlined,
                      maxLines: 2,
                      validator:
                          (value) =>
                              value?.isEmpty == true
                                  ? 'Address is required'
                                  : null,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.calendar_today_outlined,
                            color: colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Package & Dates',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildPackageDropdown(),
                    const SizedBox(height: 16),
                    _buildDateFields(),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.settings_outlined,
                            color: colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Technical Details',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildDropdownField(
                      label: 'Box Type',
                      value: _selectedBoxType,
                      items: _boxTypes,
                      onChanged:
                          (value) => setState(() => _selectedBoxType = value),
                      prefixIcon: Icons.tv_outlined,
                      validator:
                          (value) =>
                              value == null ? 'Box type is required' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildModernTextField(
                      controller: _setupBoxSerialController,
                      labelText: 'Setup Box Serial',
                      prefixIcon: Icons.qr_code_outlined,
                      validator:
                          (value) =>
                              value?.isEmpty == true
                                  ? 'Serial number is required'
                                  : null,
                    ),
                    const SizedBox(height: 16),
                    _buildModernTextField(
                      controller: _vcNumberController,
                      labelText: 'VC Number',
                      prefixIcon: Icons.confirmation_number_outlined,
                    ),
                    const SizedBox(height: 16),
                    _buildDropdownField(
                      label: 'Category',
                      value: _selectedCategory,
                      items: _categories,
                      onChanged:
                          (value) => setState(() => _selectedCategory = value),
                      prefixIcon: Icons.category_outlined,
                      validator:
                          (value) =>
                              value == null ? 'Category is required' : null,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (_isActive ? Colors.green : Colors.orange)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _isActive
                                ? Icons.check_circle_outline
                                : Icons.pause_circle_outline,
                            color: _isActive ? Colors.green : Colors.orange,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Customer Status',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        _isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          color: _isActive ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        _isActive
                            ? 'Customer is currently active'
                            : 'Customer is pending activation',
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      value: _isActive,
                      onChanged: _handleActiveStatusChange,
                      activeColor: Colors.green,
                      inactiveTrackColor: Colors.orange.withOpacity(0.3),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            _buildSaveButton(),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildModernCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: colorScheme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(prefixIcon, color: colorScheme.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
    );
  }

  Widget _buildDateFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDateField(
          label: 'Connection Date',
          date: _connectionDate,
          onTap: () => _selectDate(context, 'connection'),
          icon: Icons.cable_outlined,
        ),
        const SizedBox(height: 16),
        _buildDateField(
          label: 'Activation Date',
          date: _activationDate,
          onTap: () => _selectDate(context, 'activation'),
          icon: Icons.play_circle_outline,
        ),
        const SizedBox(height: 16),
        // Always show deactivation date if status is active
        if (_isActive) _buildDeactivationDateField(),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
          color: colorScheme.surface,
        ),
        child: Row(
          children: [
            Icon(icon, color: colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(date),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color:
                          date != null
                              ? colorScheme.onSurface
                              : colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                  if (label == 'Activation Date' && date != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Deactivation will be set based on package duration',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.calendar_today_outlined,
              color: colorScheme.onSurface.withOpacity(0.4),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeactivationDateField() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
        color: colorScheme.surfaceContainerHigh.withOpacity(0.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_busy_outlined, color: colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Deactivation Date (Auto-calculated)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _deactivationDate != null
                          ? _formatDate(_deactivationDate)
                          : 'Calculating...',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Tooltip(
                message:
                    'Deactivation date is automatically calculated based on the package duration',
                child: Icon(
                  Icons.info_outline,
                  size: 20,
                  color: colorScheme.primary.withOpacity(0.7),
                ),
              ),
            ],
          ),
          if (_activationDate != null && _deactivationDate != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Duration: ${_deactivationDate!.difference(_activationDate!).inDays} days',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<Map<String, dynamic>> items,
    required void Function(String?) onChanged,
    required IconData prefixIcon,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(prefixIcon, color: colorScheme.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      value: value,
      isExpanded: true,
      items:
          items.map((item) {
            return DropdownMenuItem<String>(
              value: item['name'] as String,
              child: Text(
                item['name'] as String,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }

  Widget _buildSaveButton() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        onPressed: _isLoading ? null : _saveCustomer,
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
        ),
        child:
            _isLoading
                ? SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      colorScheme.onPrimary,
                    ),
                  ),
                )
                : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      widget.customer != null
                          ? Icons.update_rounded
                          : Icons.add_rounded,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.customer != null
                          ? 'Update Customer'
                          : 'Add Customer',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}
