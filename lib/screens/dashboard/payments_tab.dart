import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/payment_model.dart';
import '../../services/payment_service.dart';
import '../../services/customer_service.dart';
import '../../utils/payment_list_widget.dart';

class PaymentFilters {
  String? mode;
  String? status;
  String? category;
  DateTimeRange? dateRange;

  PaymentFilters({this.mode, this.status, this.category, this.dateRange});

  bool get hasFilters =>
      mode != null || status != null || category != null || dateRange != null;

  void reset() {
    mode = null;
    status = null;
    category = null;
    dateRange = null;
  }
}

class PaymentsTab extends StatefulWidget {
  const PaymentsTab({Key? key}) : super(key: key);

  @override
  State<PaymentsTab> createState() => _PaymentsTabState();
}

class _PaymentsTabState extends State<PaymentsTab> {
  Map<String, String> _customerNames = {};
  Map<String, String> _customerCategories = {};
  Set<String> _fetchedCustomerIds = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isFilterLoading = false;
  bool _isSearchVisible = false;
  final PaymentFilters _filters = PaymentFilters();
  final CustomerService _customerService = CustomerService();

  // Available filter options
  final List<String> paymentModes = [
    'Cash',
    'UPI',
    'Card',
    'Bank Transfer',
    'Other',
  ];
  final List<String> paymentStatuses = ['Paid', 'Due'];
  Set<String> _availableCategories = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCustomerNames(List<Payment> payments) async {
    final idsToFetch =
        payments
            .map((p) => p.customerId)
            .where((id) => !_fetchedCustomerIds.contains(id))
            .toSet()
            .toList();

    if (idsToFetch.isEmpty) return;

    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('customers')
              .where(FieldPath.documentId, whereIn: idsToFetch)
              .get();

      final newNames = <String, String>{};
      final newCategories = <String, String>{};
      for (var doc in snapshot.docs) {
        final category = doc['category'] as String?;
        newNames[doc.id] = doc['name'] ?? 'Unknown';
        if (category != null) {
          newCategories[doc.id] = category;
          _availableCategories.add(category);
        }
      }

      if (mounted) {
        setState(() {
          _customerNames.addAll(newNames);
          _customerCategories.addAll(newCategories);
          _fetchedCustomerIds.addAll(newNames.keys);
        });
      }
    } catch (e) {
      debugPrint('Error fetching customer names: $e');
    }
  }

  List<Payment> _filterPayments(List<Payment> payments) {
    return payments.where((payment) {
      // Search filter
      final customerName =
          _customerNames[payment.customerId]?.toLowerCase() ?? '';
      if (!customerName.contains(_searchQuery.toLowerCase())) {
        return false;
      }

      // Mode filter
      if (_filters.mode != null && payment.mode != _filters.mode) {
        return false;
      }

      // Status filter
      if (_filters.status != null && payment.status != _filters.status) {
        return false;
      }

      // Date range filter
      if (_filters.dateRange != null) {
        final paymentDate = DateTime(
          payment.date.year,
          payment.date.month,
          payment.date.day,
        );
        final startDate = DateTime(
          _filters.dateRange!.start.year,
          _filters.dateRange!.start.month,
          _filters.dateRange!.start.day,
        );
        final endDate = DateTime(
          _filters.dateRange!.end.year,
          _filters.dateRange!.end.month,
          _filters.dateRange!.end.day,
        );
        if (paymentDate.isBefore(startDate) || paymentDate.isAfter(endDate)) {
          return false;
        }
      }

      // Category filter
      if (_filters.category != null) {
        final customerCategory = _customerCategories[payment.customerId];
        return customerCategory == _filters.category;
      }

      return true;
    }).toList();
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      barrierDismissible: !_isFilterLoading,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AbsorbPointer(
                  absorbing: _isFilterLoading,
                  child: AlertDialog(
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Filter Payments'),
                        if (_filters.hasFilters && !_isFilterLoading)
                          TextButton(
                            onPressed: () {
                              setState(() => _filters.reset());
                              Navigator.pop(context);
                              this.setState(() {});
                            },
                            child: const Text('Clear All'),
                          ),
                      ],
                    ),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Payment Mode',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children:
                                paymentModes.map((mode) {
                                  final isSelected = _filters.mode == mode;
                                  return FilterChip(
                                    label: Text(mode),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      setState(() {
                                        _filters.mode = selected ? mode : null;
                                      });
                                    },
                                    avatar: Icon(_getModeIcon(mode), size: 18),
                                  );
                                }).toList(),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Status',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children:
                                paymentStatuses.map((status) {
                                  final isSelected = _filters.status == status;
                                  return FilterChip(
                                    label: Text(status),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      setState(() {
                                        _filters.status =
                                            selected ? status : null;
                                      });
                                    },
                                    avatar: Icon(
                                      _getStatusIcon(status),
                                      size: 18,
                                    ),
                                  );
                                }).toList(),
                          ),
                          if (_availableCategories.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const Text(
                              'Category',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children:
                                  _availableCategories.map((category) {
                                    final isSelected =
                                        _filters.category == category;
                                    return FilterChip(
                                      label: Text(category),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        setState(() {
                                          _filters.category =
                                              selected ? category : null;
                                        });
                                      },
                                    );
                                  }).toList(),
                            ),
                          ],
                          const SizedBox(height: 16),
                          const Text(
                            'Date Range',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              _filters.dateRange != null
                                  ? '${DateFormat.yMMMd().format(_filters.dateRange!.start)} - ${DateFormat.yMMMd().format(_filters.dateRange!.end)}'
                                  : 'Select date range',
                            ),
                            trailing:
                                _filters.dateRange != null
                                    ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        setState(
                                          () => _filters.dateRange = null,
                                        );
                                      },
                                    )
                                    : const Icon(Icons.calendar_today),
                            onTap: () async {
                              final picked = await showDateRangePicker(
                                context: context,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                                initialDateRange: _filters.dateRange,
                              );
                              if (picked != null) {
                                setState(() => _filters.dateRange = picked);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed:
                            _isFilterLoading
                                ? null
                                : () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed:
                            _isFilterLoading
                                ? null
                                : () {
                                  Navigator.pop(context);
                                  this.setState(() {});
                                },
                        child:
                            _isFilterLoading
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                                : const Text('Apply'),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  IconData _getModeIcon(String mode) {
    switch (mode.toLowerCase()) {
      case 'cash':
        return Icons.money;
      case 'upi':
        return Icons.phone_android;
      case 'card':
        return Icons.credit_card;
      case 'bank transfer':
        return Icons.account_balance;
      default:
        return Icons.payment;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Icons.check_circle_outline;
      case 'due':
        return Icons.warning_outlined;
      default:
        return Icons.help_outline;
    }
  }

  // Add this method to calculate payment stats
  Map<String, dynamic> _calculatePaymentStats(List<Payment> payments) {
    double totalAmount = 0;
    int totalCount = 0;
    Map<String, int> statusCount = {'Paid': 0, 'Due': 0, 'Partial': 0};
    Map<String, double> statusAmount = {'Paid': 0, 'Due': 0, 'Partial': 0};

    for (var payment in payments) {
      totalAmount += payment.packageAmount;
      totalCount++;

      // Count status
      statusCount[payment.status] = (statusCount[payment.status] ?? 0) + 1;

      // Calculate amounts based on status
      if (payment.status == 'Paid') {
        statusAmount['Paid'] =
            (statusAmount['Paid'] ?? 0) + payment.packageAmount;
      } else if (payment.status == 'Due') {
        statusAmount['Due'] = (statusAmount['Due'] ?? 0) + payment.amountDue;
        // Count due payments
        statusCount['Due'] = (statusCount['Due'] ?? 0);
      } else if (payment.status == 'Partial') {
        statusAmount['Paid'] = (statusAmount['Paid'] ?? 0) + payment.amountPaid;
        statusAmount['Due'] = (statusAmount['Due'] ?? 0) + payment.amountDue;
        // If there's a due amount in partial payment, increment due count
        if (payment.amountDue > 0) {
          statusCount['Due'] = (statusCount['Due'] ?? 0) + 1;
        }
      }
    }

    return {
      'totalAmount': totalAmount,
      'totalCount': totalCount,
      'statusCount': statusCount,
      'statusAmount': statusAmount,
    };
  }

  Widget _buildStatsCard(List<Payment> payments) {
    final stats = _calculatePaymentStats(payments);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics_outlined, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Payment Statistics',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Amount',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      '₹${stats['totalAmount'].toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Total Payments',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      '${stats['totalCount']}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatusStats(
                    'Paid',
                    stats['statusCount']['Paid'] ?? 0,
                    stats['statusAmount']['Paid'] ?? 0,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatusStats(
                    'Due',
                    stats['statusCount']['Due'] ?? 0,
                    stats['statusAmount']['Due'] ?? 0,
                    Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusStats(
    String status,
    int count,
    double amount,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            status,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Text('$count payments', style: const TextStyle(fontSize: 12)),
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(),
          if (_isSearchVisible) _buildSearchBar(),
          if (_filters.hasFilters) _buildFilterChips(),
          Expanded(
            child: StreamBuilder<List<Payment>>(
              stream: PaymentService.getAllPayments(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final payments = snapshot.data!;
                _fetchCustomerNames(payments);
                final filteredPayments = _filterPayments(payments);

                if (filteredPayments.isEmpty) {
                  return const Center(child: Text('No payments found'));
                }

                return Column(
                  children: [
                    _buildStatsCard(filteredPayments),
                    Expanded(
                      child: PaymentListWidget(
                        payments: filteredPayments,
                        customerNames: _customerNames,
                        selectedPeriod: '',
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Payments',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              StreamBuilder<List<Payment>>(
                stream: PaymentService.getAllPayments(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox();
                  final payments = snapshot.data!;
                  final filteredPayments = _filterPayments(payments);
                  return Text(
                    '${filteredPayments.length} of ${payments.length} payments',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  );
                },
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  _isSearchVisible ? Icons.search_off : Icons.search,
                  color:
                      _isSearchVisible
                          ? Theme.of(context).colorScheme.primary
                          : null,
                ),
                onPressed: () {
                  setState(() {
                    _isSearchVisible = !_isSearchVisible;
                    if (!_isSearchVisible) {
                      _searchQuery = '';
                      _searchController.clear();
                    }
                  });
                },
                tooltip: 'Search Payments',
              ),
              IconButton(
                icon: Stack(
                  children: [
                    const Icon(Icons.filter_list),
                    if (_filters.hasFilters)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 8,
                            minHeight: 8,
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: _showFilterDialog,
                tooltip: 'Filter Payments',
              ),
              if (_filters.hasFilters)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _filters.reset();
                    });
                  },
                  tooltip: 'Clear Filters',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          hintText: 'Search by customer name...',
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          suffixIcon:
              _searchQuery.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                        _searchController.clear();
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
    );
  }

  Widget _buildFilterChips() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Row(
            children: [
              const Icon(Icons.filter_list, size: 18),
              const SizedBox(width: 8),
              Text(
                'Active Filters',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              if (_filters.mode != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Chip(
                    label: Text(
                      'Mode: ${_filters.mode!}',
                      style: const TextStyle(fontSize: 13),
                    ),
                    avatar: Icon(_getModeIcon(_filters.mode!), size: 18),
                    onDeleted: () {
                      setState(() {
                        _filters.mode = null;
                      });
                    },
                  ),
                ),
              if (_filters.status != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Chip(
                    label: Text(
                      'Status: ${_filters.status!}',
                      style: const TextStyle(fontSize: 13),
                    ),
                    avatar: Icon(_getStatusIcon(_filters.status!), size: 18),
                    onDeleted: () {
                      setState(() {
                        _filters.status = null;
                      });
                    },
                  ),
                ),
              if (_filters.category != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Chip(
                    label: Text(
                      'Category: ${_filters.category!}',
                      style: const TextStyle(fontSize: 13),
                    ),
                    onDeleted: () {
                      setState(() {
                        _filters.category = null;
                      });
                    },
                  ),
                ),
              if (_filters.dateRange != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Chip(
                    label: Text(
                      'Date: ${DateFormat('MMM d').format(_filters.dateRange!.start)} - ${DateFormat('MMM d').format(_filters.dateRange!.end)}',
                      style: const TextStyle(fontSize: 13),
                    ),
                    onDeleted: () {
                      setState(() {
                        _filters.dateRange = null;
                      });
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
