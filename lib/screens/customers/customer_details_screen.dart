import 'package:flutter/material.dart';
import '../../models/customer_model.dart';
import '../../models/payment_model.dart';
import '../../screens/customers/add_edit_customer_screen.dart';
import '../../utils/app_theme.dart';
import '../../utils/payment_list_widget.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import '../payments/add_payment_screen.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

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

  // Color constants for status chips
  static const Color _redColor = Color(0xFFEF4444);
  static const Color _amberColor = Color(0xFFF59E0B);
  static const Color _emeraldColor = Color(0xFF10B981);
  static const Color _purpleColor = Color(0xFF8B5CF6);
  static const Color _blueColor = Color(0xFF3B82F6);

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

  Color get _surfaceColor {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppTheme.cardDark : AppTheme.cardLight;
  }

  Color get _backgroundColor {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight;
  }

  Color _getStatusColor(bool isActive) {
    return isActive ? _emeraldColor : _redColor;
  }

  Color _getDueColor() {
    return _redColor;
  }

  Color _getExpiryColor(int remainingDays) {
    if (remainingDays <= 0) {
      return _redColor;
    } else if (remainingDays <= 5) {
      return _redColor;
    } else if (remainingDays <= 10) {
      return _amberColor;
    } else if (remainingDays <= 15) {
      return _emeraldColor;
    }
    return _blueColor;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: CustomScrollView(
        slivers: [
          // Modern Header
          SliverAppBar(
            expandedHeight: 250.0,
            pinned: true,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_rounded,
                color: colorScheme.onPrimary,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      colorScheme.primary,
                      colorScheme.primaryContainer,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      // Top Bar
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _buildHeaderButton(
                              Icons.edit_rounded,
                              () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AddEditCustomerScreen(
                                        customer: widget.customer),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            _buildHeaderButton(
                              Icons.more_vert_rounded,
                              () => _showOptionsMenu(context),
                            ),
                          ],
                        ),
                      ),
                      // Customer Info
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        child: Row(
                          children: [
                            Hero(
                              tag: 'customer-${widget.customer.id}',
                              child: Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: colorScheme.surface.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Center(
                                  child: Text(
                                    widget.customer.name.isNotEmpty
                                        ? widget.customer.name[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.customer.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.onPrimary,
                                          letterSpacing: -0.5,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  _buildStatusChips(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Container(
                height: 60,
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _buildTab(0, Icons.person_outline_rounded, 'Profile'),
                    _buildTab(1, Icons.router_rounded, 'Connection'),
                    _buildTab(2, Icons.payment_rounded,
                        'Payments (${widget.payments.length})'),
                  ],
                ),
              ),
            ),
          ),
          // Content Area
          SliverFillRemaining(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _selectedIndex = index),
              children: [
                _buildModernBasicInfoTab(),
                _buildModernConnectionTab(),
                _buildModernPaymentHistoryTab(),
              ],
            ),
          ),
          SliverFillRemaining(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.phone,
                  color: Colors.blue,
                  title: 'Call',
                  onTap: () => _makePhoneCall(widget.customer.phone),
                ),
                _buildActionButton(
                  icon: Icons.message,
                  color: Colors.green,
                  title: 'SMS',
                  onTap: () => _sendSMS(widget.customer.phone),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildModernFAB(),
    );
  }

  Widget _buildHeaderButton(IconData icon, VoidCallback onPressed) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(
          icon,
          size: 20,
          color: colorScheme.onPrimary,
        ),
        onPressed: onPressed,
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.all(8),
      ),
    );
  }

  Widget _buildStatusChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        _buildStatusChip(
          widget.customer.isActive ? 'Active' : 'Inactive',
          _getStatusColor(widget.customer.isActive),
          widget.customer.isActive
              ? Icons.check_circle_rounded
              : Icons.cancel_rounded,
        ),
        if (widget.customer.isActive && _dueAmount > 0)
          _buildStatusChip(
            'Due: ₹${_dueAmount.toStringAsFixed(0)}',
            _getDueColor(),
            Icons.warning_rounded,
          ),
        if (widget.customer.isActive)
          _buildStatusChip(
            '${widget.customer.remainingDays} days left',
            _getExpiryColor(widget.customer.remainingDays),
            Icons.timer_outlined,
          ),
      ],
    );
  }

  Widget _buildStatusChip(String label, Color color, IconData icon) {
    final backgroundColor = color.withOpacity(0.9);
    final borderColor = color.withOpacity(0.5);
    final textColor = Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(int index, IconData icon, String label) {
    final colorScheme = Theme.of(context).colorScheme;
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
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? colorScheme.primary : colorScheme.onSurface,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color:
                      isSelected ? colorScheme.primary : colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernBasicInfoTab() {
    final colorScheme = Theme.of(context).colorScheme;
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
        'action': null,
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: _surfaceColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              itemCount: basicInfo.length,
              separatorBuilder: (_, __) => Divider(
                height: 32,
                thickness: 0.5,
                color: colorScheme.outline.withOpacity(0.1),
              ),
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
          ),
        ],
      ),
    );
  }

  Widget _buildModernConnectionTab() {
    final colorScheme = Theme.of(context).colorScheme;
    final connectionInfo = [
      {
        'icon': Icons.calendar_today_outlined,
        'title': 'Connection Date',
        'value':
            DateFormat('dd MMM yyyy').format(widget.customer.connectionDate),
      },
      if (widget.customer.activationDate != null)
        {
          'icon': Icons.play_circle_outline,
          'title': 'Activation Date',
          'value':
              DateFormat('dd MMM yyyy').format(widget.customer.activationDate!),
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: _surfaceColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              itemCount: connectionInfo.length,
              separatorBuilder: (_, __) => Divider(
                height: 32,
                thickness: 0.5,
                color: colorScheme.outline.withOpacity(0.1),
              ),
              itemBuilder: (context, index) {
                final info = connectionInfo[index];
                return _buildModernInfoTile(
                  info['icon'] as IconData,
                  info['title'] as String,
                  info['value'] as String,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernPaymentHistoryTab() {
    final colorScheme = Theme.of(context).colorScheme;

    if (_sortedPayments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _surfaceColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 48,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No payment records yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add a payment to start tracking',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: PaymentListWidget(
            payments: _sortedPayments,
            customerNames: {widget.customer.id: widget.customer.name},
            selectedPeriod: '',
          ),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: colorScheme.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              SelectableText(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        if (action != null)
          Container(
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: Icon(
                Icons.call_rounded,
                size: 20,
                color: colorScheme.primary,
              ),
              onPressed: action,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.all(8),
            ),
          ),
      ],
    );
  }

  Widget _buildModernFAB() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () => _showModernActionSheet(context),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text(
          'Add Payment',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _showModernActionSheet(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddPaymentScreen(),
      ),
    );
  }

  void _showOptionsMenu(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.share_rounded, color: colorScheme.onSurface),
              title: Text('Share Customer Details',
                  style: TextStyle(color: colorScheme.onSurface)),
              onTap: () {
                Navigator.pop(context);
                _shareCustomerDetails();
              },
            ),
            ListTile(
              leading: Icon(Icons.notifications_active_outlined,
                  color: Colors.orange),
              title: const Text('Send Payment Reminder'),
              onTap: () {
                Navigator.pop(context);
                _sendPaymentReminder();
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: colorScheme.error),
              title: Text('Delete Customer',
                  style: TextStyle(color: colorScheme.error)),
              onTap: () => _confirmDelete(context),
            ),
          ],
        ),
      ),
    );
  }

  void _shareCustomerDetails() async {
    try {
      final text = '''
*Customer Details*
------------------
Name: ${widget.customer.name}
Phone: ${widget.customer.phone}
Address: ${widget.customer.address}
Monthly Plan: ${widget.customer.monthlyPlan}
Package Amount: ₹${widget.customer.packageAmount}
Box Type: ${widget.customer.boxType}
Setup Box Serial: ${widget.customer.setupBoxSerial}
VC Number: ${widget.customer.vcNumber}
Status: ${widget.customer.isActive ? 'Active' : 'Inactive'}
${widget.customer.isActive && widget.customer.remainingDays > 0 ? '\nDays Remaining: ${widget.customer.remainingDays}' : ''}
''';

      await Share.share(
        text,
        subject: 'Customer Details - ${widget.customer.name}',
      ).catchError((error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to share: $error'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        debugPrint('Share error: $error');
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      debugPrint('Share error: $e');
    }
  }

  void _sendPaymentReminder() async {
    try {
      // Calculate total due amount
      double totalDue = _calculateDueAmount();

      // Get the next payment date (either deactivation date or current date + 30 days)
      final nextPaymentDate = widget.customer.deactivationDate ??
          DateTime.now().add(const Duration(days: 30));

      // Create a reminder message
      final message = '''
📺 *Cable TV Payment Reminder*
------------------
Dear ${widget.customer.name},

This is a friendly reminder about your cable TV subscription:

📌 *Current Plan:* ${widget.customer.monthlyPlan}
💰 *Monthly Amount:* ₹${widget.customer.packageAmount}
${totalDue > 0 ? '🔴 *Due Amount:* ₹$totalDue\n' : ''}${widget.customer.isActive ? '📅 *Valid Till:* ${DateFormat('dd MMM yyyy').format(widget.customer.deactivationDate!)}\n' : ''}
${widget.customer.isExpiringSoon ? '⚠️ *Note:* Your subscription will expire in ${widget.customer.remainingDays} days.\n' : ''}
Please make the payment to continue enjoying uninterrupted service.

Thank you for your business! 🙏
''';

      // Share the message
      await Share.share(
        message,
        subject: 'Payment Reminder - ${widget.customer.name}',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending reminder: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer'),
        content: const Text(
            'Are you sure you want to delete this customer? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      Navigator.pop(context); // Close options menu
      _deleteCustomer();
    }
  }

  void _deleteCustomer() async {
    try {
      await FirebaseFirestore.instance
          .collection('customers')
          .doc(widget.customer.id)
          .delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer deleted successfully')),
      );
      Navigator.pop(context); // Return to previous screen
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete customer: ${e.toString()}')),
      );
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String title,
    required VoidCallback onTap,
  }) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(
        icon,
        color: color,
        size: 20,
      ),
      label: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final url = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not make phone call. Please try again.'),
          ),
        );
      }
    }
  }

  Future<void> _sendSMS(String phoneNumber) async {
    final url = Uri.parse('sms:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not send SMS. Please try again.'),
          ),
        );
      }
    }
  }
}
