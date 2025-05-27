import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/customer_model.dart';
import '../customers/customer_details_screen.dart';
import '../../services/customer_service.dart';
import '../customers/add_edit_customer_screen.dart';
import '../../utils/customer_card.dart';
import '../../services/payment_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/search_text_field.dart';

enum LoadingState { loading, success, error }

class CustomerFilters {
  bool? isActive;
  String? category;
  String? monthlyPlan;
  String? area;
  String? subscriptionStatus;
  bool? isExpiringSoon;
  String? boxType;
  RangeValues? packageAmount;
  DateTimeRange? connectionDateRange;
  DateTimeRange? activationDateRange;
  DateTimeRange? deactivationDateRange;

  CustomerFilters({
    this.isActive,
    this.category,
    this.monthlyPlan,
    this.area,
    this.subscriptionStatus,
    this.isExpiringSoon,
    this.boxType,
    this.packageAmount,
    this.connectionDateRange,
    this.activationDateRange,
    this.deactivationDateRange,
  });

  bool get hasFilters =>
      isActive != null ||
      category != null ||
      monthlyPlan != null ||
      area != null ||
      subscriptionStatus != null ||
      isExpiringSoon != null ||
      boxType != null ||
      packageAmount != null ||
      connectionDateRange != null ||
      activationDateRange != null ||
      deactivationDateRange != null;

  void reset() {
    isActive = null;
    category = null;
    monthlyPlan = null;
    area = null;
    subscriptionStatus = null;
    isExpiringSoon = null;
    boxType = null;
    packageAmount = null;
    connectionDateRange = null;
    activationDateRange = null;
    deactivationDateRange = null;
  }
}

class CustomersTab extends StatefulWidget {
  const CustomersTab({super.key});

  @override
  State<CustomersTab> createState() => _CustomersTabState();
}

class _CustomersTabState extends State<CustomersTab> {
  final CustomerService _customerService = CustomerService();
  final TextEditingController _searchController = TextEditingController();
  StreamSubscription<QuerySnapshot>? _customerSubscription;
  Timer? _debounceTimer;

  List<Customer> _customers = [];
  List<Customer> _filteredCustomers = [];
  LoadingState _loadingState = LoadingState.loading;
  bool _isFilterLoading = false;
  String _errorMessage = '';
  CustomerFilters _filters = CustomerFilters();

  // Available filter options
  Set<String> _availableCategories = {};
  Set<String> _availableMonthlyPlans = {};
  Set<String> _availableAreas = {};

  @override
  void initState() {
    super.initState();
    _setupCustomerStream();
    _setupSearchListener();
  }

  void _setupSearchListener() {
    _searchController.addListener(() {
      if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 300), () {
        if (mounted) _applyFilters();
      });
    });
  }

  void _setupCustomerStream() {
    try {
      _customerSubscription?.cancel();
      _customerSubscription =
          FirebaseFirestore.instance.collection('customers').snapshots().listen(
        (snapshot) => _handleCustomerSnapshot(snapshot),
        onError: (error) {
          debugPrint('Error in customer stream: $error');
          _handleError(error);
        },
        cancelOnError: false,
      );
    } catch (e) {
      debugPrint('Error setting up customer stream: $e');
      _handleError(e);
    }
  }

  void _handleCustomerSnapshot(QuerySnapshot snapshot) {
    if (!mounted) return;

    // Process the data in a microtask to avoid blocking the main thread
    Future.microtask(() {
      if (!mounted) return;

      try {
        final customers = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return Customer.fromMap(data, doc.id);
        }).toList();

        if (!mounted) return;

        setState(() {
          _customers = customers;
          _loadingState = LoadingState.success;
        });

        // Update filters and apply them in separate microtasks
        Future.microtask(() => _updateAvailableFilters());
        Future.microtask(() => _applyFilters());
      } catch (e) {
        debugPrint('Error processing customer snapshot: $e');
        if (mounted) {
          _handleError(e);
        }
      }
    });
  }

  Future<void> _updateAvailableFilters() async {
    if (!mounted) return;

    setState(() => _isFilterLoading = true);

    try {
      // Process filters in a compute function to avoid blocking the main thread
      await Future.microtask(() {
        if (!mounted) return;

        final categories = _customers.map((c) => c.category).toSet();
        final monthlyPlans = _customers.map((c) => c.monthlyPlan).toSet();
        final areas = _customers
            .map((c) {
              final address = c.address.toLowerCase();
              final blockMatch = RegExp(
                r'([a-z]?\d+)(?:\s*(?:block|sector|gf|ff|sf|tf|\d+(?:st|nd|rd|th)\s*floor|room|\#))?',
                caseSensitive: false,
              ).firstMatch(address);
              return blockMatch?.group(1)?.toUpperCase() ??
                  address.split(',').last.trim().toUpperCase();
            })
            .where((area) => area.isNotEmpty)
            .toSet();

        if (!mounted) return;

        setState(() {
          _availableCategories = categories;
          _availableMonthlyPlans = monthlyPlans;
          _availableAreas = areas;
          _isFilterLoading = false;
        });
      });
    } catch (e) {
      debugPrint('Error updating filters: $e');
      if (mounted) {
        setState(() => _isFilterLoading = false);
      }
    }
  }

  Future<void> _applyFilters() async {
    if (!mounted) return;

    setState(() => _isFilterLoading = true);

    try {
      await Future.microtask(() {
        if (!mounted) return;

        final searchQuery = _searchController.text.toLowerCase();
        final filtered = _customers.where((customer) {
          // Existing search filter
          if (searchQuery.isNotEmpty) {
            final searchTarget =
                '${customer.name} ${customer.phone} ${customer.address} '
                        '${customer.category} ${customer.monthlyPlan} ${customer.setupBoxSerial} '
                        '${customer.vcNumber} ${customer.isActive ? 'active' : 'inactive'}'
                    .toLowerCase();
            if (!searchTarget.contains(searchQuery)) return false;
          }

          // Active status filter
          if (_filters.isActive != null &&
              customer.isActive != _filters.isActive) {
            return false;
          }

          // Subscription status filter
          if (_filters.subscriptionStatus != null &&
              customer.subscriptionStatus.toLowerCase() !=
                  _filters.subscriptionStatus) {
            return false;
          }

          // Box type filter
          if (_filters.boxType != null &&
              customer.boxType != _filters.boxType) {
            return false;
          }

          // Category filter
          if (_filters.category != null &&
              customer.category != _filters.category) {
            return false;
          }

          // Monthly Plan filter
          if (_filters.monthlyPlan != null &&
              customer.monthlyPlan != _filters.monthlyPlan) {
            return false;
          }

          // Package amount range filter
          if (_filters.packageAmount != null) {
            if (customer.packageAmount < _filters.packageAmount!.start ||
                customer.packageAmount > _filters.packageAmount!.end) {
              return false;
            }
          }

          // Expiring soon filter
          if (_filters.isExpiringSoon == true && !customer.isExpiringSoon) {
            return false;
          }

          // Connection date range filter
          if (_filters.connectionDateRange != null) {
            if (customer.connectionDate.isBefore(
                  _filters.connectionDateRange!.start,
                ) ||
                customer.connectionDate.isAfter(
                  _filters.connectionDateRange!.end,
                )) {
              return false;
            }
          }

          // Activation date range filter
          if (_filters.activationDateRange != null &&
              customer.activationDate != null) {
            if (customer.activationDate!.isBefore(
                  _filters.activationDateRange!.start,
                ) ||
                customer.activationDate!.isAfter(
                  _filters.activationDateRange!.end,
                )) {
              return false;
            }
          }

          // Deactivation date range filter
          if (_filters.deactivationDateRange != null &&
              customer.deactivationDate != null) {
            if (customer.deactivationDate!.isBefore(
                  _filters.deactivationDateRange!.start,
                ) ||
                customer.deactivationDate!.isAfter(
                  _filters.deactivationDateRange!.end,
                )) {
              return false;
            }
          }

          return true;
        }).toList();

        if (!mounted) return;

        setState(() {
          _filteredCustomers = filtered;
          _isFilterLoading = false;
        });
      });
    } catch (e) {
      debugPrint('Error applying filters: $e');
      if (mounted) {
        setState(() {
          _isFilterLoading = false;
          _errorMessage = 'Error applying filters: ${e.toString()}';
        });
      }
    }
  }

  void _handleError(dynamic error) {
    if (!mounted) return;

    setState(() {
      _loadingState = LoadingState.error;
      _errorMessage = 'Failed to load customers. Please try again.';
      debugPrint('Error in CustomersTab: $error');
    });
  }

  Future<void> _refreshCustomers() async {
    setState(() => _loadingState = LoadingState.loading);
    _setupCustomerStream();
  }

  void _showFilterDialog() {
    final List<String> subscriptionStatuses = [
      'Active',
      'Inactive',
      'Pending',
      'Expired',
      'Scheduled',
    ];

    final List<String> boxTypes = ['ACT', 'GTPL', 'Other'];

    // Find min and max package amounts
    double minAmount = 0;
    double maxAmount = 5000; // Default max
    if (_customers.isNotEmpty) {
      minAmount = _customers
          .map((c) => c.packageAmount)
          .reduce((a, b) => a < b ? a : b);
      maxAmount = _customers
          .map((c) => c.packageAmount)
          .reduce((a, b) => a > b ? a : b);
    }

    showDialog(
      context: context,
      barrierDismissible: !_isFilterLoading,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AbsorbPointer(
          absorbing: _isFilterLoading,
          child: AlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Filter Customers'),
                if (_filters.hasFilters && !_isFilterLoading)
                  TextButton(
                    onPressed: () {
                      setState(() => _filters.reset());
                    },
                    child: const Text('Clear All'),
                  ),
              ],
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isFilterLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else ...[
                      // Status Filter
                      const Text(
                        'Active Status',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<bool?>(
                        selected: {_filters.isActive},
                        onSelectionChanged: (value) {
                          setState(() {
                            _filters.isActive = value.first == _filters.isActive
                                ? null
                                : value.first;
                          });
                        },
                        segments: const [
                          ButtonSegment<bool?>(
                            value: true,
                            label: Text('Active'),
                          ),
                          ButtonSegment<bool?>(
                            value: false,
                            label: Text('Inactive'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Subscription Status Filter
                      const Text(
                        'Subscription Status',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String?>(
                        value: _filters.subscriptionStatus,
                        decoration: const InputDecoration(
                          hintText: 'Select Status',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('All Statuses'),
                          ),
                          ...subscriptionStatuses.map((status) {
                            return DropdownMenuItem<String?>(
                              value: status.toLowerCase(),
                              child: Text(status),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(
                            () => _filters.subscriptionStatus = value,
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Box Type Filter
                      const Text(
                        'Box Type',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String?>(
                        value: _filters.boxType,
                        decoration: const InputDecoration(
                          hintText: 'Select Box Type',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('All Box Types'),
                          ),
                          ...boxTypes.map((type) {
                            return DropdownMenuItem<String?>(
                              value: type,
                              child: Text(type),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() => _filters.boxType = value);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Category Filter
                      const Text(
                        'Category',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String?>(
                        value: _filters.category,
                        decoration: const InputDecoration(
                          hintText: 'Select Category',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('All Categories'),
                          ),
                          ..._availableCategories.map((category) {
                            return DropdownMenuItem<String?>(
                              value: category,
                              child: Text(category),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() => _filters.category = value);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Monthly Plan Filter
                      const Text(
                        'Monthly Plan',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.8,
                        ),
                        child: DropdownButtonFormField<String?>(
                          value: _filters.monthlyPlan,
                          decoration: const InputDecoration(
                            hintText: 'Select Plan',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('All Plans'),
                            ),
                            ..._availableMonthlyPlans.map((plan) {
                              return DropdownMenuItem<String?>(
                                value: plan,
                                child: Text(
                                  plan,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setState(
                              () => _filters.monthlyPlan = value,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Package Amount Range Filter
                      const Text(
                        'Package Amount Range',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      RangeSlider(
                        values: _filters.packageAmount ??
                            RangeValues(minAmount, maxAmount),
                        min: minAmount,
                        max: maxAmount,
                        divisions: 100,
                        labels: RangeLabels(
                          '₹${(_filters.packageAmount?.start ?? minAmount).round()}',
                          '₹${(_filters.packageAmount?.end ?? maxAmount).round()}',
                        ),
                        onChanged: (RangeValues values) {
                          setState(
                            () => _filters.packageAmount = values,
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Expiring Soon Filter
                      SwitchListTile(
                        title: const Text(
                          'Show Expiring Soon Only',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        value: _filters.isExpiringSoon ?? false,
                        onChanged: (bool value) {
                          setState(
                            () => _filters.isExpiringSoon = value,
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Date Range Filters
                      const Text(
                        'Connection Date Range',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      _buildDateRangeField(
                        context,
                        _filters.connectionDateRange,
                        (range) {
                          setState(
                            () => _filters.connectionDateRange = range,
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'Activation Date Range',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      _buildDateRangeField(
                        context,
                        _filters.activationDateRange,
                        (range) {
                          setState(
                            () => _filters.activationDateRange = range,
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'Deactivation Date Range',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      _buildDateRangeField(
                        context,
                        _filters.deactivationDateRange,
                        (range) {
                          setState(
                            () => _filters.deactivationDateRange = range,
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed:
                    _isFilterLoading ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: _isFilterLoading
                    ? null
                    : () async {
                        Navigator.pop(context);
                        await _applyFilters();
                      },
                child: _isFilterLoading
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

  Widget _buildDateRangeField(
    BuildContext context,
    DateTimeRange? currentRange,
    Function(DateTimeRange?) onChanged,
  ) {
    final String displayText = currentRange != null
        ? '${DateFormat('dd MMM yyyy').format(currentRange.start)} - ${DateFormat('dd MMM yyyy').format(currentRange.end)}'
        : 'Select Date Range';

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () async {
              final DateTimeRange? picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
                initialDateRange: currentRange,
              );
              if (picked != null) {
                onChanged(picked);
              }
            },
            child: Text(displayText),
          ),
        ),
        if (currentRange != null)
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => onChanged(null),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(),
          _buildSearchBar(),
          _buildCustomerStats(),
          Expanded(child: _buildCustomerList()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: colorScheme.outline.withOpacity(0.1),
                width: 0.5,
              ),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          Icons.people_alt_rounded,
                          size: 20,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Customers',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                  letterSpacing: -0.5,
                                ),
                          ),
                          Text(
                            '${_filteredCustomers.length} of ${_customers.length} customers',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceVariant.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: colorScheme.outline.withOpacity(0.1),
                            width: 0.5,
                          ),
                        ),
                        child: _isFilterLoading
                            ? Padding(
                                padding: const EdgeInsets.all(8),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              )
                            : IconButton(
                                onPressed: _showFilterDialog,
                                icon: Stack(
                                  children: [
                                    Icon(
                                      Icons.filter_list_rounded,
                                      color: colorScheme.onSurfaceVariant,
                                      size: 20,
                                    ),
                                    if (_filters.hasFilters)
                                      Positioned(
                                        right: 0,
                                        top: 0,
                                        child: Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: colorScheme.primary,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: colorScheme.surface,
                                              width: 1.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.all(8),
                              ),
                      ),
                      if (_filters.hasFilters && !_isFilterLoading) ...[
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceVariant.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: colorScheme.outline.withOpacity(0.1),
                              width: 0.5,
                            ),
                          ),
                          child: IconButton(
                            onPressed: () async {
                              _filters.reset();
                              await _applyFilters();
                            },
                            icon: Icon(
                              Icons.clear_rounded,
                              color: colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.all(8),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_filters.hasFilters) ...[
          Container(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.filter_list_rounded,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Active Filters',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 32,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      if (_filters.isActive != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: colorScheme.primary.withOpacity(0.2),
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Status: ${_filters.isActive! ? 'Active' : 'Inactive'}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                                const SizedBox(width: 4),
                                InkWell(
                                  onTap: () async {
                                    setState(() => _filters.isActive = null);
                                    await _applyFilters();
                                  },
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 16,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (_filters.category != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: colorScheme.primary.withOpacity(0.2),
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Category: ${_filters.category!}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                                const SizedBox(width: 4),
                                InkWell(
                                  onTap: () async {
                                    setState(() => _filters.category = null);
                                    await _applyFilters();
                                  },
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 16,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (_filters.monthlyPlan != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: colorScheme.primary.withOpacity(0.2),
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Plan: ${_filters.monthlyPlan!}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                                const SizedBox(width: 4),
                                InkWell(
                                  onTap: () async {
                                    setState(() => _filters.monthlyPlan = null);
                                    await _applyFilters();
                                  },
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 16,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (_filters.area != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: colorScheme.primary.withOpacity(0.2),
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Area: ${_filters.area!}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                                const SizedBox(width: 4),
                                InkWell(
                                  onTap: () async {
                                    setState(() => _filters.area = null);
                                    await _applyFilters();
                                  },
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 16,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSearchBar() {
    return SearchTextField(
      controller: _searchController,
      hintText: 'Search customers...',
      showClearButton: _searchController.text.isNotEmpty,
      onClear: () {
        setState(() {
          _searchController.clear();
        });
      },
      onChanged: (value) {
        if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
        _debounceTimer = Timer(const Duration(milliseconds: 300), () {
          if (mounted) _applyFilters();
        });
      },
    );
  }

  Widget _buildCustomerList() {
    switch (_loadingState) {
      case LoadingState.loading:
        return const Center(child: CircularProgressIndicator());

      case LoadingState.error:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _errorMessage,
                style: AppTheme.bodyLarge.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _refreshCustomers,
                child: const Text('Try Again'),
              ),
            ],
          ),
        );

      case LoadingState.success:
        if (_filteredCustomers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline_rounded,
                  size: 64,
                  color: AppTheme.textMuted,
                ),
                const SizedBox(height: 16),
                Text(
                  'No customers found',
                  style: AppTheme.headingMedium.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                if (_filters.hasFilters) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Try adjusting your filters',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _refreshCustomers,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _filteredCustomers.length,
            itemBuilder: (context, index) {
              final customer = _filteredCustomers[index];
              return CustomerCard(
                customer: customer,
                onCall: _makePhoneCall,
                onMenuPressed: () => _showCustomerOptions(customer),
              );
            },
          ),
        );
    }
  }

  void _showCustomerOptions(Customer customer) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      builder: (context) => CustomerOptionsSheet(
        customer: customer,
        onView: () => _viewCustomerDetails(customer),
        onEdit: () => _editCustomer(customer),
        onCopy: () => _copyCustomerDetails(customer),
        onDelete: () => _deleteCustomer(customer),
      ),
    );
  }

  void _viewCustomerDetails(Customer customer) async {
    Navigator.pop(context); // Close the bottom sheet

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading customer details...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Fetch payments data
      final payments =
          await PaymentService.getPaymentsByCustomer(customer.id).first;

      if (!mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      // Navigate to details screen with pre-fetched data
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              CustomerDetailsScreen(customer: customer, payments: payments),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text('Failed to load customer details: ${e.toString()}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
            TextButton(
              onPressed: () => _viewCustomerDetails(customer),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
  }

  void _editCustomer(Customer customer) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditCustomerScreen(customer: customer),
      ),
    );
  }

  void _copyCustomerDetails(Customer customer) {
    final text = '''
  Customer Details:
  Name: ${customer.name}
  Phone: ${customer.phone}
  Address: ${customer.address}
  Connection Date: ${DateFormat('dd MMM yyyy').format(customer.connectionDate)}
  ${customer.activationDate != null ? 'Activation Date: ${DateFormat('dd MMM yyyy').format(customer.activationDate!)}\n' : ''}${customer.deactivationDate != null ? 'Deactivation Date: ${DateFormat('dd MMM yyyy').format(customer.deactivationDate!)}\n' : ''}Monthly Plan: ${customer.monthlyPlan}
  Package Amount: ₹${customer.packageAmount}
  Box Type: ${customer.boxType}
  Setup Box Serial: ${customer.setupBoxSerial}
  VC Number: ${customer.vcNumber}
  Category: ${customer.category}
  Status: ${customer.subscriptionStatus}
  ${customer.isExpiringSoon ? 'Days Remaining: ${customer.remainingDays}\n' : ''}''';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Customer details copied to clipboard')),
    );
  }

  Future<void> _deleteCustomer(Customer customer) async {
    try {
      await _customerService.deleteCustomer(customer.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Customer deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete customer: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _customerSubscription?.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Widget _buildCustomerStats() {
    // Calculate statistics based on filtered customers instead of all customers
    final totalCustomers = _filteredCustomers.length;
    final activeCustomers = _filteredCustomers.where((c) => c.isActive).length;
    final inactiveCustomers = totalCustomers - activeCustomers;
    final expiringSoon =
        _filteredCustomers.where((c) => c.isExpiringSoon).length;

    // Group filtered customers by category
    final categoryCount = <String, int>{};
    for (var customer in _filteredCustomers) {
      categoryCount[customer.category] =
          (categoryCount[customer.category] ?? 0) + 1;
    }

    return Container(
      height: 60,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildStatChip(
              icon: Icons.people_outline,
              label: 'Total',
              value:
                  '$totalCustomers${_filters.hasFilters ? ' / ${_customers.length}' : ''}',
              color: Colors.blue,
            ),
            const SizedBox(width: 8),
            _buildStatChip(
              icon: Icons.check_circle_outline,
              label: 'Active',
              value:
                  '$activeCustomers${_filters.hasFilters ? ' / ${_customers.where((c) => c.isActive).length}' : ''}',
              color: Colors.green,
            ),
            const SizedBox(width: 8),
            _buildStatChip(
              icon: Icons.cancel_outlined,
              label: 'Inactive',
              value:
                  '$inactiveCustomers${_filters.hasFilters ? ' / ${_customers.length - _customers.where((c) => c.isActive).length}' : ''}',
              color: Colors.red,
            ),
            const SizedBox(width: 8),
            _buildStatChip(
              icon: Icons.timer_outlined,
              label: 'Expiring',
              value:
                  '$expiringSoon${_filters.hasFilters ? ' / ${_customers.where((c) => c.isExpiringSoon).length}' : ''}',
              color: Colors.orange,
            ),
            const SizedBox(width: 8),
            FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance.collection('customers').get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return _buildStatChip(
                    icon: Icons.currency_rupee,
                    label: 'Due',
                    value: '...',
                    color: Colors.purple,
                  );
                }

                double totalDue = 0;
                double filteredDue = 0;
                for (var doc in snapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  if (data.containsKey('totalDue')) {
                    final due = (data['totalDue'] as num).toDouble();
                    totalDue += due;
                    // Add to filtered due if customer is in filtered list
                    if (_filteredCustomers.any((c) => c.id == doc.id)) {
                      filteredDue += due;
                    }
                  }
                }

                return _buildStatChip(
                  icon: Icons.currency_rupee,
                  label: 'Due',
                  value: _filters.hasFilters
                      ? '₹${filteredDue.toStringAsFixed(0)} / ${totalDue.toStringAsFixed(0)}'
                      : '₹${totalDue.toStringAsFixed(0)}',
                  color: Colors.purple,
                );
              },
            ),
            ...categoryCount.entries.map((entry) {
              // Get total count for this category from all customers
              final totalForCategory =
                  _customers.where((c) => c.category == entry.key).length;
              return Padding(
                padding: const EdgeInsets.only(left: 8),
                child: _buildStatChip(
                  icon: Icons.category_outlined,
                  label: entry.key,
                  value:
                      '${entry.value}${_filters.hasFilters ? ' / $totalForCategory' : ''}',
                  color: Colors.teal,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTheme.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: AppTheme.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      await launchUrl(launchUri);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch dialer: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

class CustomerOptionsSheet extends StatelessWidget {
  final Customer customer;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onCopy;
  final VoidCallback onDelete;

  const CustomerOptionsSheet({
    super.key,
    required this.customer,
    required this.onView,
    required this.onEdit,
    required this.onCopy,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(Icons.visibility_outlined),
          title: const Text('View Details'),
          onTap: onView,
        ),
        ListTile(
          leading: const Icon(Icons.edit_outlined),
          title: const Text('Edit'),
          onTap: onEdit,
        ),
        ListTile(
          leading: const Icon(Icons.copy_outlined),
          title: const Text('Copy Details'),
          onTap: onCopy,
        ),
        ListTile(
          leading: const Icon(Icons.delete_outline, color: Colors.red),
          title: const Text('Delete', style: TextStyle(color: Colors.red)),
          onTap: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete Customer'),
                content: const Text(
                  'Are you sure you want to delete this customer?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );
            if (confirmed == true) {
              Navigator.pop(context);
              onDelete();
            }
          },
        ),
      ],
    );
  }
}
