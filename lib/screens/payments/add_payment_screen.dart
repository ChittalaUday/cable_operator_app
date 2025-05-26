import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../../models/payment_model.dart';
import '../../services/payment_service.dart';
import '../../models/customer_model.dart';
import '../../services/customer_service.dart';

class AddPaymentScreen extends StatefulWidget {
  const AddPaymentScreen({super.key});

  @override
  State<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends State<AddPaymentScreen> {
  final _formKey = GlobalKey<FormState>();

  Customer? selectedCustomer;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _paidAmountController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  bool isDue = false;
  bool isPartialPayment = false;
  String paymentMode = 'Cash';
  final TextEditingController _noteController = TextEditingController();
  bool _isCustomAmount = false;
  List<Map<String, dynamic>> packages = [];
  bool _isNewPlanActivation = false;
  String? _selectedPackageName;
  double _currentBalance = 0.0;
  List<Payment> _previousDuePayments = [];
  double _totalPreviousDue = 0.0;
  bool _isLoadingPreviousPayments = false;

  final List<String> paymentModes = [
    'Cash',
    'UPI',
    'Card',
    'Bank Transfer',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadPackages();
    _loadCurrentBalance();
  }

  Future<void> _loadPackages() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('packages')
              .where('isActive', isEqualTo: true)
              .get();

      setState(() {
        packages =
            snapshot.docs
                .map(
                  (doc) => {
                    'id': doc.id,
                    'name': doc['name'] as String,
                    'amount': doc['amount'] as double,
                  },
                )
                .toList();
      });
    } catch (e) {
      debugPrint('Error loading packages: $e');
    }
  }

  Future<void> _loadCurrentBalance() async {
    if (selectedCustomer != null) {
      try {
        // Get the latest payment record for this customer
        final QuerySnapshot paymentSnapshot =
            await FirebaseFirestore.instance
                .collection('payments')
                .where('customerId', isEqualTo: selectedCustomer!.id)
                .where('status', isEqualTo: 'Due')
                .orderBy('date', descending: true)
                .limit(1)
                .get();

        if (paymentSnapshot.docs.isNotEmpty) {
          final latestPayment =
              paymentSnapshot.docs.first.data() as Map<String, dynamic>;
          // Try to get totalDue, fallback to amount if totalDue doesn't exist
          final dueAmount =
              (latestPayment['totalDue'] ?? latestPayment['amount'])
                  ?.toDouble() ??
              0.0;
          setState(() {
            _currentBalance = dueAmount;
          });
        } else {
          setState(() {
            _currentBalance = 0.0;
          });
        }
      } catch (e) {
        debugPrint('Error loading due amount: $e');
        setState(() {
          _currentBalance = 0.0;
        });
      }
    }
  }

  Future<void> _loadPreviousPayments() async {
    if (selectedCustomer == null) return;

    setState(() => _isLoadingPreviousPayments = true);

    try {
      final QuerySnapshot paymentSnapshot =
          await FirebaseFirestore.instance
              .collection('payments')
              .where('customerId', isEqualTo: selectedCustomer!.id)
              .where('status', whereIn: ['Due', 'Partial'])
              .orderBy('date', descending: true)
              .get();

      setState(() {
        _previousDuePayments =
            paymentSnapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return Payment(
                id: doc.id,
                customerId: data['customerId'] as String,
                packageAmount: (data['packageAmount'] as num).toDouble(),
                amountPaid: (data['amountPaid'] as num).toDouble(),
                amountDue: (data['amountDue'] as num).toDouble(),
                date: (data['date'] as Timestamp).toDate(),
                mode: data['mode'] as String,
                note: data['note'] as String? ?? '',
                status: data['status'] as String,
                customerBalanceAfterThis:
                    (data['customerBalanceAfterThis'] as num?)?.toDouble() ??
                    0.0,
              );
            }).toList();

        _totalPreviousDue = _previousDuePayments.fold(
          0.0,
          (sum, payment) => sum + payment.amountDue,
        );
      });

      // If there are previous dues, show the summary dialog
      if (_previousDuePayments.isNotEmpty) {
        _showPreviousDuesDialog();
      }
    } catch (e) {
      debugPrint('Error loading previous payments: $e');
    } finally {
      setState(() => _isLoadingPreviousPayments = false);
    }
  }

  Future<void> _showPreviousDuesDialog() async {
    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange.shade700,
                ),
                const SizedBox(width: 8),
                const Text('Previous Dues Found'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This customer has ${_previousDuePayments.length} previous ${_previousDuePayments.length == 1 ? 'payment' : 'payments'} with pending dues:',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade100),
                    ),
                    child: Column(
                      children: [
                        ..._previousDuePayments
                            .map(
                              (payment) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          DateFormat(
                                            'dd MMM yyyy',
                                          ).format(payment.date),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                payment.status.toLowerCase() ==
                                                        'due'
                                                    ? Colors.red.shade100
                                                    : Colors.orange.shade100,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            payment.status,
                                            style: TextStyle(
                                              color:
                                                  payment.status
                                                              .toLowerCase() ==
                                                          'due'
                                                      ? Colors.red.shade700
                                                      : Colors.orange.shade700,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Total: ₹${payment.packageAmount}',
                                              style: const TextStyle(
                                                fontSize: 13,
                                              ),
                                            ),
                                            if (payment.amountPaid > 0)
                                              Text(
                                                'Paid: ₹${payment.amountPaid}',
                                                style: TextStyle(
                                                  color: Colors.green.shade700,
                                                  fontSize: 13,
                                                ),
                                              ),
                                          ],
                                        ),
                                        Text(
                                          'Due: ₹${payment.amountDue}',
                                          style: TextStyle(
                                            color: Colors.red.shade700,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (payment.note.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        payment.note,
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Previous Due',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '₹${_totalPreviousDue.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              FilledButton.icon(
                icon: const Icon(Icons.payment),
                label: const Text('Add New Payment'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
    );
  }

  void _updateAmount(String? value) {
    if (value == null || value.isEmpty) {
      setState(() {
        _amountController.text =
            selectedCustomer?.packageAmount.toString() ?? '';
        _isCustomAmount = false;
      });
    } else {
      setState(() {
        _isCustomAmount = true;
      });
    }
  }

  Future<void> _updateCustomerPlan(String packageName, double amount) async {
    try {
      final now = DateTime.now();
      final customerRef = FirebaseFirestore.instance
          .collection('customers')
          .doc(selectedCustomer!.id);

      await customerRef.update({
        'monthlyPlan': packageName,
        'packageAmount': amount,
        'activationDate': now,
        'deactivationDate': null,
        'lastPaymentDate': now,
      });

      setState(() {
        selectedCustomer = Customer(
          id: selectedCustomer!.id,
          name: selectedCustomer!.name,
          phone: selectedCustomer!.phone,
          address: selectedCustomer!.address,
          vcNumber: selectedCustomer!.vcNumber,
          setupBoxSerial: selectedCustomer!.setupBoxSerial,
          category: selectedCustomer!.category,
          monthlyPlan: packageName,
          packageAmount: amount,
          activationDate: now,
          deactivationDate: null,
          connectionDate: selectedCustomer!.connectionDate,
          boxType: selectedCustomer!.boxType,
          isActive: selectedCustomer!.isActive,
        );
      });
    } catch (e) {
      debugPrint('Error updating customer plan: $e');
      rethrow;
    }
  }

  void _onCustomerSelected(Customer customer) {
    setState(() {
      selectedCustomer = customer;
      _amountController.text = customer.packageAmount.toString();
      _isCustomAmount = false;
    });
    _loadPreviousPayments();
  }

  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final totalAmount = double.parse(_amountController.text);

      // Update customer status if needed
      await _updateCustomerStatus(totalAmount);

      // Create the payment
      final paymentId = const Uuid().v4();
      final paidAmount =
          isPartialPayment
              ? double.parse(_paidAmountController.text)
              : (isDue ? 0.0 : totalAmount);
      final dueAmount = totalAmount - paidAmount;

      // Create initial payment
      final payment = Payment(
        id: paymentId,
        customerId: selectedCustomer!.id,
        packageAmount: totalAmount,
        amountPaid: paidAmount,
        amountDue: dueAmount,
        date: selectedDate,
        mode: paymentMode,
        note: _noteController.text.trim(),
        status: _determinePaymentStatus(paidAmount, dueAmount),
        customerBalanceAfterThis: 0.0, // Will be calculated by service
      );

      await PaymentService.addPayment(payment);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isPartialPayment
                  ? 'Partial payment recorded'
                  : (isDue
                      ? 'Due payment recorded'
                      : 'Payment added successfully'),
            ),
            backgroundColor:
                isPartialPayment
                    ? Colors.blue
                    : (isDue ? Colors.orange : Colors.green),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error submitting payment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to submit payment. Please try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  String _determinePaymentStatus(double paidAmount, double dueAmount) {
    if (dueAmount <= 0) return 'Paid';
    if (paidAmount > 0) return 'Partial';
    return 'Due';
  }

  Future<void> _updateCustomerStatus(double totalAmount) async {
    if (!selectedCustomer!.isActive || _isNewPlanActivation) {
      final now = DateTime.now();
      final customerRef = FirebaseFirestore.instance
          .collection('customers')
          .doc(selectedCustomer!.id);

      final packageName = _selectedPackageName ?? selectedCustomer!.monthlyPlan;
      Map<String, dynamic> selectedPackage = {
        'days': 30,
        'amount': selectedCustomer!.packageAmount,
      };
      if (packages.any((p) => p['name'] == packageName)) {
        selectedPackage = packages.firstWhere((p) => p['name'] == packageName);
      }
      final packageDays = (selectedPackage['days'] as num?)?.toInt() ?? 30;
      final deactivationDate = now.add(Duration(days: packageDays));

      final updates = {
        if (!selectedCustomer!.isActive) 'isActive': true,
        'activationDate': now,
        'deactivationDate': deactivationDate,
        'lastPaymentDate': now,
        if (_isNewPlanActivation) ...{
          'monthlyPlan': _selectedPackageName,
          'packageAmount': totalAmount,
        },
      };

      await customerRef.update(updates);

      setState(() {
        selectedCustomer = Customer(
          id: selectedCustomer!.id,
          name: selectedCustomer!.name,
          phone: selectedCustomer!.phone,
          address: selectedCustomer!.address,
          vcNumber: selectedCustomer!.vcNumber,
          setupBoxSerial: selectedCustomer!.setupBoxSerial,
          category: selectedCustomer!.category,
          monthlyPlan:
              _isNewPlanActivation
                  ? _selectedPackageName!
                  : selectedCustomer!.monthlyPlan,
          packageAmount:
              _isNewPlanActivation
                  ? totalAmount
                  : selectedCustomer!.packageAmount,
          activationDate: now,
          deactivationDate: deactivationDate,
          connectionDate: selectedCustomer!.connectionDate,
          boxType: selectedCustomer!.boxType,
          isActive: true,
        );
      });
    }
  }

  Future<void> _showPaymentSummary() async {
    if (!_formKey.currentState!.validate()) return;

    final totalAmount = double.parse(_amountController.text);
    final paidAmount =
        isPartialPayment
            ? double.parse(_paidAmountController.text)
            : (isDue ? 0.0 : totalAmount);
    final dueAmount = totalAmount - paidAmount;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Payment Summary'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_previousDuePayments.isNotEmpty) ...[
                    Text(
                      'Previous Due Payments',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade100),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ..._previousDuePayments
                              .map(
                                (payment) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        DateFormat(
                                          'dd MMM yyyy',
                                        ).format(payment.date),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        '₹${payment.amountDue}',
                                        style: TextStyle(
                                          color: Colors.red.shade700,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Previous Due',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '₹$_totalPreviousDue',
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    'New Payment Details',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        _buildSummaryRow('Total Amount', totalAmount),
                        _buildSummaryRow('Amount Paid', paidAmount),
                        _buildSummaryRow('Due Amount', dueAmount),
                        const Divider(),
                        _buildSummaryRow(
                          'Final Balance',
                          dueAmount + _totalPreviousDue,
                          isTotal: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirm Payment'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await _submitPayment();
    }
  }

  Widget _buildSummaryRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: amount > 0 ? Colors.red.shade700 : Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _paidAmountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          "Add Payment",
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        toolbarHeight: 72,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (selectedCustomer == null)
                _buildCustomerSearch()
              else ...[
                _buildCustomerCard(),
                const SizedBox(height: 16),
                if (_isNewPlanActivation)
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: colorScheme.primary.withOpacity(0.2),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.sync_rounded,
                            color: colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Package Change',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Changing from "${selectedCustomer!.monthlyPlan}" to "$_selectedPackageName"',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurface.withOpacity(
                                      0.7,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '₹${_amountController.text}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: Icon(
                              Icons.close_rounded,
                              color: colorScheme.error,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _selectedPackageName =
                                    selectedCustomer!.monthlyPlan;
                                _amountController.text =
                                    selectedCustomer!.packageAmount.toString();
                                _isNewPlanActivation = false;
                              });
                            },
                            tooltip: 'Revert to original package',
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                _buildPaymentDetails(),
                const SizedBox(height: 160),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar:
          selectedCustomer != null
              ? Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.save_rounded),
                      label: const Text("Review & Save"),
                      onPressed: _showPaymentSummary,
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                ),
              )
              : null,
    );
  }

  Widget _buildCustomerSearch() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.1)),
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
                  child: Icon(
                    Icons.person_search_rounded,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    "Select Customer",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            FutureBuilder<List<Customer>>(
              future: CustomerService().getAllCustomers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text('Error loading customers: ${snapshot.error}');
                }
                final customers = snapshot.data ?? [];
                if (customers.isEmpty) {
                  return const Text('No customers found');
                }
                return SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.search_rounded),
                    label: const Text("Search Customer"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.surface,
                      foregroundColor: colorScheme.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: colorScheme.outline.withOpacity(0.3),
                        ),
                      ),
                    ),
                    onPressed: () async {
                      final result = await showSearch<Customer?>(
                        context: context,
                        delegate: CustomerSearchDelegate(customers),
                      );
                      if (result != null) {
                        setState(() {
                          selectedCustomer = result;
                          _amountController.text =
                              result.packageAmount.toString();
                          _isCustomAmount = false;
                        });
                      }
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerCard() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.1)),
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
                  child: Icon(
                    Icons.person_outline_rounded,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    "Customer Details",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person, color: colorScheme.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedCustomer!.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        selectedCustomer!.phone,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () {
                    setState(() {
                      selectedCustomer = null;
                      _amountController.clear();
                      _isNewPlanActivation = false;
                      _selectedPackageName = null;
                    });
                  },
                ),
              ],
            ),
            const Divider(height: 32),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildInfoItem(
                    'Package',
                    selectedCustomer!.monthlyPlan,
                    Icons.category_outlined,
                  ),
                  const SizedBox(width: 16),
                  _buildInfoItem(
                    'Amount',
                    '₹${selectedCustomer!.packageAmount}',
                    Icons.payments_outlined,
                  ),
                  const SizedBox(width: 16),
                  TextButton.icon(
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('Change'),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: const Text('Change Package'),
                              content: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Current Package: ${selectedCustomer!.monthlyPlan}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Current Amount: ₹${selectedCustomer!.packageAmount}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 300,
                                      ),
                                      child: DropdownButtonFormField<String>(
                                        decoration: InputDecoration(
                                          labelText: 'Select Package',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 8,
                                              ),
                                          prefixIcon: Icon(
                                            Icons.inventory_2_rounded,
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                          ),
                                        ),
                                        isExpanded: true,
                                        value:
                                            packages.isNotEmpty
                                                ? (packages.any(
                                                      (p) =>
                                                          p['name'] ==
                                                          selectedCustomer!
                                                              .monthlyPlan,
                                                    )
                                                    ? packages.firstWhere(
                                                          (p) =>
                                                              p['name'] ==
                                                              selectedCustomer!
                                                                  .monthlyPlan,
                                                        )['id']
                                                        as String
                                                    : packages[0]['id']
                                                        as String)
                                                : null,
                                        items:
                                            packages.map((package) {
                                              final isCurrentPackage =
                                                  package['name'] ==
                                                  selectedCustomer!.monthlyPlan;
                                              return DropdownMenuItem(
                                                value: package['id'] as String,
                                                child: Row(
                                                  children: [
                                                    if (isCurrentPackage)
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets.only(
                                                              right: 8,
                                                            ),
                                                        child: Icon(
                                                          Icons
                                                              .check_circle_outline,
                                                          size: 16,
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .primary,
                                                        ),
                                                      ),
                                                    Expanded(
                                                      child: Text(
                                                        package['name']
                                                            as String,
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                        style: TextStyle(
                                                          fontWeight:
                                                              isCurrentPackage
                                                                  ? FontWeight
                                                                      .bold
                                                                  : FontWeight
                                                                      .normal,
                                                          color:
                                                              isCurrentPackage
                                                                  ? Theme.of(
                                                                        context,
                                                                      )
                                                                      .colorScheme
                                                                      .primary
                                                                  : null,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 4,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            isCurrentPackage
                                                                ? Theme.of(
                                                                      context,
                                                                    )
                                                                    .colorScheme
                                                                    .primary
                                                                    .withOpacity(
                                                                      0.1,
                                                                    )
                                                                : Theme.of(
                                                                      context,
                                                                    )
                                                                    .colorScheme
                                                                    .surfaceVariant,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              6,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        '₹${package['amount']}',
                                                        style: TextStyle(
                                                          color:
                                                              isCurrentPackage
                                                                  ? Theme.of(
                                                                        context,
                                                                      )
                                                                      .colorScheme
                                                                      .primary
                                                                  : null,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                        onChanged: (value) {
                                          if (value != null &&
                                              packages.isNotEmpty) {
                                            final selectedPackage =
                                                packages.any(
                                                      (p) => p['id'] == value,
                                                    )
                                                    ? packages.firstWhere(
                                                      (p) => p['id'] == value,
                                                    )
                                                    : packages[0];
                                            setState(() {
                                              _amountController.text =
                                                  selectedPackage['amount']
                                                      .toString();
                                              _isCustomAmount = false;
                                              _selectedPackageName =
                                                  selectedPackage['name']
                                                      as String;
                                              _isNewPlanActivation =
                                                  selectedPackage['name'] !=
                                                  selectedCustomer!.monthlyPlan;
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _isNewPlanActivation = false;
                                      _selectedPackageName = null;
                                    });
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Update'),
                                ),
                              ],
                            ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: colorScheme.onSurface.withOpacity(0.7)),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 120),
          child: Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentDetails() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.1)),
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
                  child: Icon(
                    Icons.payments_outlined,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    "Payment Details",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_currentBalance > 0) ...[
              Text(
                'Current Balance: ₹${_currentBalance.toStringAsFixed(2)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Amount Field
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: _isCustomAmount ? "Total Amount" : "Package Amount",
                hintText: "Enter total amount",
                prefixText: "₹",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
                filled: true,
                fillColor: colorScheme.surface,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter amount';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Please enter a valid amount';
                }
                return null;
              },
              onChanged: _updateAmount,
            ),

            const SizedBox(height: 20),

            // Payment Type Card
            Card(
              elevation: 0,
              color: colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  SwitchListTile.adaptive(
                    title: Text(
                      'Split Payment',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isPartialPayment ? Colors.blue : null,
                      ),
                    ),
                    subtitle: Text(
                      isPartialPayment
                          ? 'Divide total amount into paid and due'
                          : 'Full payment amount',
                    ),
                    value: isPartialPayment,
                    onChanged: (val) {
                      setState(() {
                        isPartialPayment = val;
                        if (isPartialPayment) {
                          isDue = false;
                        } else {
                          _paidAmountController.clear();
                        }
                      });
                    },
                    activeColor: Colors.blue,
                  ),
                  if (!isPartialPayment) const Divider(height: 1),
                  if (!isPartialPayment)
                    SwitchListTile.adaptive(
                      title: Text(
                        'Mark as Due',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDue ? Colors.orange : null,
                        ),
                      ),
                      subtitle: Text(
                        isDue
                            ? 'Payment will be pending'
                            : 'Payment will be completed',
                      ),
                      value: isDue,
                      onChanged: (val) => setState(() => isDue = val),
                      activeColor: Colors.orange,
                    ),
                ],
              ),
            ),

            if (isPartialPayment) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _paidAmountController,
                decoration: InputDecoration(
                  labelText: "Paid Amount",
                  hintText: "Enter amount being paid now",
                  prefixText: "₹",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: colorScheme.outline.withOpacity(0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: colorScheme.surface,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (!isPartialPayment) return null;
                  if (value == null || value.isEmpty) {
                    return 'Please enter paid amount';
                  }
                  final paidAmount = double.tryParse(value);
                  if (paidAmount == null || paidAmount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  final totalAmount =
                      double.tryParse(_amountController.text) ?? 0;
                  if (paidAmount > totalAmount) {
                    return 'Paid amount cannot exceed total amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Remaining amount will be marked as due',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.orange,
                ),
              ),
            ],

            const SizedBox(height: 20),
            Text(
              'Payment Mode',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
                filled: true,
                fillColor: colorScheme.surface,
              ),
              value: paymentMode,
              items:
                  paymentModes
                      .map(
                        (mode) =>
                            DropdownMenuItem(value: mode, child: Text(mode)),
                      )
                      .toList(),
              onChanged: (val) => setState(() => paymentMode = val ?? 'Cash'),
            ),
            const SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment Date',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        readOnly: true,
                        controller: TextEditingController(
                          text: DateFormat.yMMMd().format(selectedDate),
                        ),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.outline.withOpacity(0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.primary,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: colorScheme.surface,
                          prefixIcon: Icon(
                            Icons.calendar_today_rounded,
                            color: colorScheme.primary,
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.edit_calendar_rounded),
                            onPressed: () async {
                              final pickedDate = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: colorScheme.copyWith(
                                        primary: colorScheme.primary,
                                        onPrimary: colorScheme.onPrimary,
                                        surface: colorScheme.surface,
                                        onSurface: colorScheme.onSurface,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (pickedDate != null) {
                                setState(() => selectedDate = pickedDate);
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: "Note (optional)",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
                filled: true,
                fillColor: colorScheme.surface,
              ),
              maxLines: 2,
            ),

            if (_isLoadingPreviousPayments)
              const Center(child: CircularProgressIndicator())
            else if (_previousDuePayments.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange.shade700,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Previous Due Balance',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${_totalPreviousDue.toStringAsFixed(2)} pending from ${_previousDuePayments.length} ${_previousDuePayments.length == 1 ? 'payment' : 'payments'}',
                            style: TextStyle(color: Colors.orange.shade800),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: _showPreviousDuesDialog,
                      child: const Text('View Details'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class CustomerSearchDelegate extends SearchDelegate<Customer?> {
  final List<Customer> customers;

  CustomerSearchDelegate(this.customers);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results =
        customers.where((c) {
          final q = query.toLowerCase();
          return c.name.toLowerCase().contains(q) ||
              c.phone.toLowerCase().contains(q) ||
              c.address.toLowerCase().contains(q) ||
              c.vcNumber.toLowerCase().contains(q) ||
              c.category.toLowerCase().contains(q) ||
              c.monthlyPlan.toLowerCase().contains(q) ||
              c.setupBoxSerial.toLowerCase().contains(q);
        }).toList();

    if (results.isEmpty) {
      return const Center(child: Text("No matching customers"));
    }

    return _buildCustomerList(results);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions =
        customers.where((c) {
          final q = query.toLowerCase();
          return c.name.toLowerCase().contains(q) ||
              c.phone.toLowerCase().contains(q) ||
              c.address.toLowerCase().contains(q) ||
              c.vcNumber.toLowerCase().contains(q) ||
              c.category.toLowerCase().contains(q) ||
              c.monthlyPlan.toLowerCase().contains(q) ||
              c.setupBoxSerial.toLowerCase().contains(q);
        }).toList();

    if (suggestions.isEmpty) {
      return const Center(child: Text("No matching customers"));
    }

    return _buildCustomerList(suggestions);
  }

  Widget _buildCustomerList(List<Customer> customers) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: customers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final customer = customers[index];
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => close(context, customer),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color:
                          customer.isActive
                              ? Theme.of(context).primaryColor.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person,
                      color:
                          customer.isActive
                              ? Theme.of(context).primaryColor
                              : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          customer.phone,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    customer.isActive
                                        ? Colors.green.withOpacity(0.1)
                                        : Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                customer.isActive ? 'Active' : 'Inactive',
                                style: TextStyle(
                                  color:
                                      customer.isActive
                                          ? Colors.green
                                          : Colors.orange,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                customer.monthlyPlan,
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
