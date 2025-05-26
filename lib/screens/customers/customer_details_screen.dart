import 'package:flutter/material.dart';
import '../../models/customer_model.dart';
import '../../models/payment_model.dart';
import '../../screens/customers/add_edit_customer_screen.dart';
import '../../utils/app_theme.dart';
import '../../utils/payment_list_widget.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomerDetailsScreen extends StatefulWidget {
  final Customer customer;
  final List<Payment> payments;

  const CustomerDetailsScreen({
    Key? key,
    required this.customer,
    this.payments = const [],
  }) : super(key: key);

  @override
  State<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  // Cache variables
  late final double _dueAmount;
  late final List<Payment> _sortedPayments;
  bool _calculationsInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCalculations();
  }

  void _initializeCalculations() {
    if (_calculationsInitialized) return;

    // Sort payments by date (newest first)
    _sortedPayments = List<Payment>.unmodifiable(
      widget.payments..sort((a, b) => b.date.compareTo(a.date)),
    );

    // Calculate due amount
    _dueAmount = _calculateDueAmount();

    _calculationsInitialized = true;
  }

  double _calculateDueAmount() {
    double totalDue = 0.0;
    for (var payment in _sortedPayments) {
      if (payment.status.toLowerCase() == 'due') {
        totalDue += payment.amountDue;
      }
    }
    return totalDue;
  }

  double _calculateTotalAmount() {
    double total = 0.0;
    for (var payment in _sortedPayments) {
      total += payment.amountPaid + payment.amountDue;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          _buildModernAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 16),
                _buildNavigationTabs(),
                const SizedBox(height: 8),
                _buildContentArea(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildModernFAB(),
    );
  }

  Widget _buildModernAppBar() {
    return SliverAppBar(
      expandedHeight: 160,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Hero(
                    tag: 'customer-${widget.customer.id}',
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          widget.customer.name.isNotEmpty
                              ? widget.customer.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.customer.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            _buildHeaderStatusChip(
                              widget.customer.isActive ? 'Active' : 'Inactive',
                              widget.customer.isActive
                                  ? Colors.teal
                                  : Colors.deepOrange,
                              widget.customer.isActive
                                  ? Icons.check_circle
                                  : Icons.cancel,
                            ),
                            if (widget.customer.isActive && _dueAmount > 0)
                              _buildHeaderStatusChip(
                                'Due: ₹${_dueAmount.toStringAsFixed(0)}',
                                Colors.red[700]!,
                                Icons.warning_rounded,
                              ),
                            if (widget.customer.isActive)
                              _buildHeaderStatusChip(
                                '${widget.customer.remainingDays} days left',
                                widget.customer.isExpiringSoon
                                    ? Colors.orange[700]!
                                    : Colors.teal[700]!,
                                Icons.timer_outlined,
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
        ),
      ),
      leading: _buildAppBarButton(
        Icons.arrow_back_ios_rounded,
        () => Navigator.pop(context),
      ),
      actions: [
        _buildAppBarButton(Icons.edit_rounded, () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddEditCustomerScreen(customer: widget.customer),
            ),
          );
        }),
        _buildAppBarButton(
          Icons.more_vert_rounded,
          () => _showOptionsMenu(context),
        ),
      ],
    );
  }

  Widget _buildAppBarButton(IconData icon, VoidCallback onPressed) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildHeaderStatusChip(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernFAB() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () => _showModernActionSheet(context),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Payment'),
      ),
    );
  }

  Widget _buildNavigationTabs() {
    final tabs = [
      {'icon': Icons.person_outline_rounded, 'label': 'Profile'},
      {'icon': Icons.router_rounded, 'label': 'Connection'},
      {
        'icon': Icons.payment_rounded,
        'label': 'Payments (${widget.payments.length})',
      },
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
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
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = _selectedIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedIndex = index);
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tabs[index]['icon'] as IconData,
                      color: isSelected ? Colors.white : Colors.grey[600],
                      size: 20,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tabs[index]['label'] as String,
                      style: AppTheme.bodySmall.copyWith(
                        color: isSelected ? Colors.white : Colors.grey[600],
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildContentArea() {
    return Container(
      height: MediaQuery.of(context).size.height - 280,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: PageView(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _selectedIndex = index),
        children: [
          _buildModernBasicInfoTab(),
          _buildModernConnectionTab(),
          _buildModernPaymentHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildModernBasicInfoTab() {
    final basicInfo = [
      {
        'icon': Icons.badge_outlined,
        'title': 'Customer ID',
        'value': widget.customer.id,
        'action': null,
      },
      {
        'icon': Icons.phone_outlined,
        'title': 'Mobile Number',
        'value': widget.customer.phone,
        'action': () async {
          final url = Uri.parse('tel:${widget.customer.phone}');
          if (await canLaunchUrl(url)) {
            await launchUrl(url);
          }
        },
      },
      {
        'icon': Icons.location_on_outlined,
        'title': 'Address',
        'value': widget.customer.address,
        'action': null,
      },
      {
        'icon': Icons.category_outlined,
        'title': 'Category',
        'value': widget.customer.category,
        'action': null,
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: basicInfo.length,
        separatorBuilder: (_, __) => const SizedBox(height: 20),
        itemBuilder: (context, index) {
          final info = basicInfo[index];
          return _buildModernInfoTile(
            info['icon'] as IconData,
            info['title'] as String,
            info['value'] as String,
            action: info['action'] as Function()?,
          );
        },
      ),
    );
  }

  Widget _buildModernConnectionTab() {
    final connectionInfo = [
      {
        'icon': Icons.calendar_today_outlined,
        'title': 'Connection Date',
        'value': DateFormat(
          'dd MMM yyyy',
        ).format(widget.customer.connectionDate),
      },
      if (widget.customer.activationDate != null)
        {
          'icon': Icons.play_circle_outline,
          'title': 'Activation Date',
          'value': DateFormat(
            'dd MMM yyyy',
          ).format(widget.customer.activationDate!),
        },
      {
        'icon': Icons.subscriptions_outlined,
        'title': 'Monthly Plan',
        'value': widget.customer.monthlyPlan,
      },
      {
        'icon': Icons.currency_rupee,
        'title': 'Package Amount',
        'value': '₹${widget.customer.packageAmount}',
      },
      {
        'icon': Icons.tv_outlined,
        'title': 'Setup Box Serial',
        'value': widget.customer.setupBoxSerial,
      },
      {
        'icon': Icons.settings_outlined,
        'title': 'Box Type',
        'value': widget.customer.boxType,
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: connectionInfo.length,
        separatorBuilder: (_, __) => const SizedBox(height: 20),
        itemBuilder: (context, index) {
          final info = connectionInfo[index];
          return _buildModernInfoTile(
            info['icon'] as IconData,
            info['title'] as String,
            info['value'] as String,
          );
        },
      ),
    );
  }

  Widget _buildModernPaymentHistoryTab() {
    if (_sortedPayments.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.receipt_long_outlined,
                  size: 48,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'No payment records yet',
                style: AppTheme.headingMedium.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                'Add a payment to start tracking',
                style: AppTheme.bodyMedium.copyWith(color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: PaymentListWidget(
          payments: _sortedPayments,
          customerNames: {widget.customer.id: widget.customer.name},
          selectedPeriod: '',
        ),
      ),
    );
  }

  Widget _buildModernInfoTile(
    IconData icon,
    String title,
    String value, {
    Function()? action,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: Theme.of(context).primaryColor, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.bodySmall.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              SelectableText(
                value,
                style: AppTheme.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
        if (action != null)
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: action,
            color: Theme.of(context).primaryColor,
            tooltip: 'Call $value',
          ),
      ],
    );
  }

  void _showModernActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Quick Actions',
                  style: AppTheme.headingMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _buildActionTile(
                  Icons.payment_rounded,
                  'Add Payment',
                  'Record a new payment',
                  () {
                    Navigator.pop(context);
                    // TODO: Navigate to add payment screen
                  },
                ),
                const SizedBox(height: 12),
                _buildActionTile(
                  Icons.history_rounded,
                  'Payment History',
                  'View all payment records',
                  () {
                    Navigator.pop(context);
                    // TODO: Navigate to payment history screen
                  },
                ),
                const SizedBox(height: 12),
                _buildActionTile(
                  Icons.print_rounded,
                  'Generate Report',
                  'Print customer details',
                  () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Print feature coming soon'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }

  Widget _buildActionTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Theme.of(context).primaryColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTheme.bodySmall.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.share_rounded),
                  title: const Text('Share Customer Details'),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  leading: const Icon(Icons.print_rounded),
                  title: const Text('Print Details'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Print feature coming soon'),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.delete_outline, color: Colors.red[400]),
                  title: Text(
                    'Delete Customer',
                    style: TextStyle(color: Colors.red[400]),
                  ),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
    );
  }
}
