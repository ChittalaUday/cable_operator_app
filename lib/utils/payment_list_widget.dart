import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/payment_model.dart';
import '../services/payment_service.dart';
import '../services/customer_service.dart';
import '../screens/customers/customer_details_screen.dart';
import 'package:uuid/uuid.dart';
import '../utils/app_theme.dart';

class PaymentListWidget extends StatefulWidget {
  final List<Payment> payments;
  final Map<String, String> customerNames;
  final String selectedPeriod;

  const PaymentListWidget({
    Key? key,
    required this.payments,
    required this.customerNames,
    required this.selectedPeriod,
  }) : super(key: key);

  @override
  State<PaymentListWidget> createState() => _PaymentListWidgetState();
}

class _PaymentListWidgetState extends State<PaymentListWidget> {
  late ScaffoldMessengerState _scaffoldMessenger;
  final CustomerService _customerService = CustomerService();
  Set<String> _expandedPayments = {};
  Set<String> _expandedMonths = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scaffoldMessenger = ScaffoldMessenger.of(context);
  }

  @override
  void initState() {
    super.initState();
    // Initially expand all months
    final grouped = _groupPaymentsByTime(widget.payments);
    _expandedMonths.addAll(grouped.keys);
  }

  Map<String, List<Payment>> _groupPaymentsByTime(List<Payment> payments) {
    Map<String, List<Payment>> grouped = {};

    for (var payment in payments) {
      String key = DateFormat('MMMM yyyy').format(payment.date);
      grouped.putIfAbsent(key, () => []).add(payment);
    }

    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) {
        final dateA = DateFormat('MMMM yyyy').parse(a);
        final dateB = DateFormat('MMMM yyyy').parse(b);
        return dateB.compareTo(dateA);
      });

    Map<String, List<Payment>> sortedMap = {};
    for (var key in sortedKeys) {
      sortedMap[key] = grouped[key]!;
    }

    return sortedMap;
  }

  Future<void> _handleStatusChange(Payment payment) async {
    if (payment.status.toLowerCase() != 'due') return;

    try {
      // Create a new payment with updated status
      final updatedPayment = Payment(
        id: payment.id,
        customerId: payment.customerId,
        packageAmount: payment.packageAmount,
        amountPaid: payment.amountDue, // Pay the due amount
        amountDue: 0.0, // No remaining due
        date: payment.date,
        mode: payment.mode,
        note: payment.note,
        status: 'Paid',
        customerBalanceAfterThis: 0.0, // Will be calculated by service
      );

      await PaymentService.addPayment(updatedPayment);

      if (mounted) {
        _scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Payment status updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Error updating payment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleSplitPayment(Payment payment) async {
    final TextEditingController paidAmountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Split Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Amount: ₹${payment.packageAmount}'),
            const SizedBox(height: 8),
            Text('Previously Paid: ₹${payment.amountPaid}'),
            const SizedBox(height: 8),
            Text('Remaining Due: ₹${payment.amountDue}'),
            const SizedBox(height: 16),
            TextField(
              controller: paidAmountController,
              decoration: const InputDecoration(
                labelText: 'Amount to Pay Now',
                prefixText: '₹',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final paidAmount = double.tryParse(paidAmountController.text);
              if (paidAmount == null ||
                  paidAmount <= 0 ||
                  paidAmount > payment.amountDue) {
                _scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Please enter a valid amount less than or equal to the remaining due',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(context);

              try {
                final newAmountPaid = payment.amountPaid + paidAmount;
                final newAmountDue = payment.amountDue - paidAmount;

                // Create payment update
                final updatePayment = Payment(
                  id: const Uuid().v4(),
                  customerId: payment.customerId,
                  packageAmount: payment.packageAmount,
                  amountPaid: paidAmount, // This is the new payment amount
                  amountDue: newAmountDue,
                  date: DateTime.now(),
                  mode: payment.mode,
                  note: 'Partial payment update',
                  status: newAmountDue <= 0 ? 'Paid' : 'Partial',
                  customerBalanceAfterThis:
                      0.0, // Will be calculated by service
                  parentPaymentId: payment.id,
                );

                await PaymentService.addPaymentUpdate(
                  payment.id,
                  updatePayment,
                );

                if (mounted) {
                  _scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        'Payment of ₹$paidAmount recorded successfully',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  _scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Error recording payment update: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Update Payment'),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePayment(Payment payment) async {
    try {
      await PaymentService.deletePayment(payment.customerId, payment.id);
      if (mounted) {
        _scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Payment deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Error deleting payment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _viewCustomerDetails(Payment payment) async {
    try {
      final customer = await _customerService.getCustomer(payment.customerId);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CustomerDetailsScreen(
              customer: customer,
              payments: widget.payments
                  .where((p) => p.customerId == customer.id)
                  .toList(),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Error loading customer details: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPaymentOptions(Payment payment) {
    final theme = Theme.of(context);
    final canSplit = payment.status.toLowerCase() == 'due' ||
        payment.status.toLowerCase() == 'partial';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.4,
          minChildSize: 0.2,
          maxChildSize: 0.75,
          expand: false,
          builder: (_, controller) {
            return SingleChildScrollView(
              controller: controller,
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                    left: 16,
                    right: 16,
                    top: 16,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      ListTile(
                        leading: Icon(
                          _modeIcon(payment.mode),
                          color: _statusColor(payment.status),
                        ),
                        title: Text(
                          widget.customerNames[payment.customerId] ?? 'Unknown',
                          style: AppTheme.bodyLarge.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Amount: ₹${payment.packageAmount}',
                              style: AppTheme.bodyMedium.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (payment.amountPaid > 0)
                              Text(
                                'Paid: ₹${payment.amountPaid}',
                                style: AppTheme.bodyMedium.copyWith(
                                  color: AppTheme.statusPaid,
                                ),
                              ),
                            if (payment.amountDue > 0)
                              Text(
                                'Due: ₹${payment.amountDue}',
                                style: AppTheme.bodyMedium.copyWith(
                                  color: AppTheme.statusDue,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (payment.hasUpdates) ...[
                        Divider(
                          color: theme.colorScheme.outline.withOpacity(0.3),
                          height: 1,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Payment History',
                                style: AppTheme.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              StreamBuilder<List<Payment>>(
                                stream: PaymentService.getPaymentUpdates(
                                  payment.customerId,
                                  payment.id,
                                ),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData ||
                                      snapshot.data!.isEmpty) {
                                    return const SizedBox();
                                  }

                                  final updates = snapshot.data!;
                                  return ListView.separated(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: updates.length,
                                    separatorBuilder: (context, index) =>
                                        const SizedBox(height: 8),
                                    itemBuilder: (context, index) {
                                      final update = updates[index];
                                      return Row(
                                        children: [
                                          Icon(
                                            Icons.arrow_right,
                                            size: 20,
                                            color: theme
                                                .colorScheme.onSurfaceVariant,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            DateFormat('dd MMM yyyy')
                                                .format(update.date),
                                            style: AppTheme.bodySmall.copyWith(
                                              color: theme
                                                  .colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                          const Spacer(),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppTheme.statusPaid
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: AppTheme.statusPaid
                                                    .withOpacity(0.2),
                                                width: 0.5,
                                              ),
                                            ),
                                            child: Text(
                                              '+₹${update.amountPaid}',
                                              style:
                                                  AppTheme.bodySmall.copyWith(
                                                color: AppTheme.statusPaid,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              ),
                              if (payment.amountDue > 0) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.statusDue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color:
                                          AppTheme.statusDue.withOpacity(0.2),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        size: 16,
                                        color: AppTheme.statusDue,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Remaining Due: ₹${payment.amountDue}',
                                        style: AppTheme.bodyMedium.copyWith(
                                          color: AppTheme.statusDue,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                      Divider(
                        color: theme.colorScheme.outline.withOpacity(0.3),
                        height: 1,
                      ),
                      if (canSplit) ...[
                        ListTile(
                          leading: Icon(
                            Icons.call_split_rounded,
                            color: theme.colorScheme.primary,
                          ),
                          title: Text(
                            'Split Payment',
                            style: AppTheme.bodyLarge.copyWith(
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          subtitle: Text(
                            payment.status == 'Due'
                                ? 'Pay partial amount now'
                                : 'Pay another portion of remaining ₹${payment.amountDue}',
                            style: AppTheme.bodyMedium.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _handleSplitPayment(payment);
                          },
                        ),
                      ],
                      if (payment.status == 'Due' ||
                          payment.status == 'Partial') ...[
                        ListTile(
                          leading: Icon(
                            Icons.check_circle_outline,
                            color: AppTheme.statusPaid,
                          ),
                          title: Text(
                            'Mark as Fully Paid',
                            style: AppTheme.bodyLarge.copyWith(
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          subtitle: Text(
                            'Pay remaining ₹${payment.amountDue}',
                            style: AppTheme.bodyMedium.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _handleFullPayment(payment);
                          },
                        ),
                      ],
                      ListTile(
                        leading: Icon(
                          Icons.info_outline,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        title: Text(
                          'View Customer Details',
                          style: AppTheme.bodyLarge.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _viewCustomerDetails(payment);
                        },
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.delete_outline,
                          color: AppTheme.statusDue,
                        ),
                        title: Text(
                          'Delete Payment',
                          style: AppTheme.bodyLarge.copyWith(
                            color: AppTheme.statusDue,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(
                                'Delete Payment',
                                style: AppTheme.headingMedium.copyWith(
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              content: Text(
                                'Are you sure you want to delete this payment? This action cannot be undone.',
                                style: AppTheme.bodyMedium.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(
                                    'Cancel',
                                    style: AppTheme.bodyMedium.copyWith(
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                                FilledButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _deletePayment(payment);
                                  },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppTheme.statusDue,
                                  ),
                                  child: Text(
                                    'Delete',
                                    style: AppTheme.bodyMedium.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleFullPayment(Payment payment) async {
    try {
      // Create payment update for full remaining amount
      final updatePayment = Payment(
        id: const Uuid().v4(),
        customerId: payment.customerId,
        packageAmount: payment.packageAmount,
        amountPaid: payment.amountDue,
        amountDue: 0.0,
        date: DateTime.now(),
        mode: payment.mode,
        note: 'Full payment of remaining amount',
        status: 'Paid',
        customerBalanceAfterThis: 0.0, // Will be calculated by service
        parentPaymentId: payment.id,
      );

      await PaymentService.addPaymentUpdate(payment.id, updatePayment);

      if (mounted) {
        _scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Payment completed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Error completing payment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _togglePaymentHistory(String paymentId) {
    setState(() {
      if (_expandedPayments.contains(paymentId)) {
        _expandedPayments.remove(paymentId);
      } else {
        _expandedPayments.add(paymentId);
      }
    });
  }

  void _toggleMonthExpansion(String month) {
    setState(() {
      if (_expandedMonths.contains(month)) {
        _expandedMonths.remove(month);
      } else {
        _expandedMonths.add(month);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupPaymentsByTime(widget.payments);
    final theme = Theme.of(context);

    if (widget.payments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No payments found',
              style: AppTheme.headingMedium.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters',
              style: AppTheme.bodyMedium.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final entry = grouped.entries.elementAt(index);
        final timeLabel = entry.key;
        final groupPayments = entry.value;
        final isExpanded = _expandedMonths.contains(timeLabel);

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: theme.colorScheme.outline.withOpacity(0.3),
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () => _toggleMonthExpansion(timeLabel),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: isExpanded
                        ? const BorderRadius.vertical(top: Radius.circular(12))
                        : BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            timeLabel,
                            style: AppTheme.headingMedium.copyWith(
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildStatusChip(
                            'Paid',
                            groupPayments
                                .where((p) => p.status.toLowerCase() == 'paid')
                                .fold(0.0, (sum, p) => sum + p.amountPaid),
                            AppTheme.statusPaid,
                          ),
                          const SizedBox(width: 8),
                          _buildStatusChip(
                            'Due',
                            groupPayments
                                .where(
                                  (p) =>
                                      p.status.toLowerCase() == 'due' ||
                                      p.status.toLowerCase() == 'partial',
                                )
                                .fold(0.0, (sum, p) => sum + p.amountDue),
                            AppTheme.statusDue,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (isExpanded)
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(12),
                    ),
                  ),
                  child: ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: groupPayments.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      thickness: 0.5,
                      indent: 16,
                      endIndent: 16,
                      color: theme.colorScheme.outline.withOpacity(0.3),
                    ),
                    itemBuilder: (context, index) {
                      final payment = groupPayments[index];
                      return _buildPaymentTile(payment);
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String label, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Text(
        '$label: ₹${amount.toStringAsFixed(0)}',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'partial':
        return Colors.orange;
      case 'due':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  IconData _modeIcon(String mode) {
    switch (mode.toLowerCase()) {
      case 'cash':
        return Icons.money;
      case 'upi':
        return Icons.phone_android;
      case 'bank transfer':
      case 'transfer':
        return Icons.account_balance;
      case 'cheque':
        return Icons.receipt_long;
      case 'card':
        return Icons.credit_card;
      default:
        return Icons.payment;
    }
  }

  Widget _buildPaymentTile(Payment payment) {
    final theme = Theme.of(context);
    final isExpanded = _expandedPayments.contains(payment.id);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () => _showPaymentOptions(payment),
          onLongPress: () {
            if (payment.hasUpdates) {
              _togglePaymentHistory(payment.id);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _modeIcon(payment.mode),
                        color: _statusColor(payment.status),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.customerNames[payment.customerId] ??
                                'Unknown',
                            style: AppTheme.bodyLarge.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('dd MMM yyyy').format(payment.date),
                            style: AppTheme.bodySmall.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${payment.packageAmount}',
                          style: AppTheme.bodyLarge.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _statusColor(payment.status)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: _statusColor(payment.status)
                                      .withOpacity(0.2),
                                  width: 0.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    payment.status.toLowerCase() == 'paid'
                                        ? Icons.check_circle_outline
                                        : (payment.status.toLowerCase() ==
                                                'partial'
                                            ? Icons.pending_outlined
                                            : Icons.warning_outlined),
                                    size: 14,
                                    color: _statusColor(payment.status),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    payment.status,
                                    style: TextStyle(
                                      color: _statusColor(payment.status),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              payment.mode,
                              style: AppTheme.bodySmall.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (payment.hasUpdates) ...[
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => _togglePaymentHistory(payment.id),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.history,
                                      size: 14,
                                      color: theme.colorScheme.primary,
                                    ),
                                    Icon(
                                      isExpanded
                                          ? Icons.keyboard_arrow_up
                                          : Icons.keyboard_arrow_down,
                                      size: 14,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                if (payment.status.toLowerCase() != 'paid') ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.3),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Paid',
                                style: AppTheme.bodySmall.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '₹${payment.amountPaid}',
                                style: AppTheme.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.statusPaid,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          height: 30,
                          width: 1,
                          color: theme.colorScheme.outline.withOpacity(0.3),
                        ),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Due',
                                style: AppTheme.bodySmall.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '₹${payment.amountDue}',
                                style: AppTheme.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.statusDue,
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
            ),
          ),
        ),
        if (isExpanded)
          StreamBuilder<List<Payment>>(
            stream: PaymentService.getPaymentUpdates(
              payment.customerId,
              payment.id,
            ),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();

              final updates = snapshot.data!;
              if (updates.isEmpty) return const SizedBox();

              return Container(
                margin: const EdgeInsets.fromLTRB(32, 0, 16, 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.3),
                    width: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment History',
                      style: AppTheme.bodySmall.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...updates.map((update) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Icon(
                                _modeIcon(update.mode),
                                size: 16,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '₹${update.amountPaid} paid on ${DateFormat('dd MMM yyyy').format(update.date)}',
                                  style: AppTheme.bodySmall.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
