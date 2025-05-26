import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/payment_model.dart';

class MonthlyOverviewWidget extends StatefulWidget {
  final List<Payment> allPayments;
  final Function(DateTime) onMonthSelected;
  final DateTime? selectedDate;

  const MonthlyOverviewWidget({
    Key? key,
    required this.allPayments,
    required this.onMonthSelected,
    this.selectedDate,
  }) : super(key: key);

  @override
  State<MonthlyOverviewWidget> createState() => _MonthlyOverviewWidgetState();
}

class _MonthlyOverviewWidgetState extends State<MonthlyOverviewWidget> {
  late DateTime _selectedDate;
  List<Payment> _filteredPayments = [];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate ?? DateTime.now();
    _filterPayments();
  }

  @override
  void didUpdateWidget(covariant MonthlyOverviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.allPayments != oldWidget.allPayments ||
        widget.selectedDate != oldWidget.selectedDate) {
      _filterPayments();
    }
  }

  void _filterPayments() {
    _filteredPayments =
        widget.allPayments.where((payment) {
          return payment.date.year == _selectedDate.year &&
              payment.date.month == _selectedDate.month;
        }).toList();
  }

  Future<void> _selectMonth() async {
    final DateTime? picked = await showDialog(
      context: context,
      builder:
          (context) => MonthYearPicker(
            initialDate: _selectedDate,
            firstDate: DateTime(2020),
            lastDate: DateTime.now(),
          ),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _filterPayments();
      });
      widget.onMonthSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalAmount = _filteredPayments.fold(
      0.0,
      (sum, p) => sum + p.packageAmount,
    );
    final totalPaid = _filteredPayments.fold(
      0.0,
      (sum, p) => sum + p.amountPaid,
    );
    final totalDue = _filteredPayments.fold(0.0, (sum, p) => sum + p.amountDue);
    final totalPayments = _filteredPayments.length;
    final paidPayments =
        _filteredPayments.where((p) => p.status.toLowerCase() == 'paid').length;
    final duePayments =
        _filteredPayments.where((p) => p.status.toLowerCase() == 'due').length;
    final partialPayments =
        _filteredPayments
            .where(
              (p) =>
                  p.status.toLowerCase() == 'partial' &&
                  p.status.toLowerCase() != 'due',
            )
            .length;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: _selectMonth,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_month,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('MMMM yyyy').format(_selectedDate),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_drop_down,
                    color: Theme.of(context).primaryColor,
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Collection',
                        '₹$totalAmount',
                        Icons.account_balance_wallet_outlined,
                        Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        'Amount Received',
                        '₹$totalPaid',
                        Icons.check_circle_outline,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        'Pending Amount',
                        '₹$totalDue',
                        Icons.warning_amber_outlined,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildPaymentCount(
                      'Total',
                      totalPayments,
                      Icons.receipt_long_outlined,
                    ),
                    _buildPaymentCount(
                      'Paid',
                      paidPayments,
                      Icons.check_circle_outline,
                      color: Colors.green,
                    ),
                    _buildPaymentCount(
                      'Due',
                      duePayments,
                      Icons.warning_amber_outlined,
                      color: Colors.red,
                    ),
                    _buildPaymentCount(
                      'Partial',
                      partialPayments,
                      Icons.pending_outlined,
                      color: Colors.orange,
                    ),
                  ],
                ),
                if (totalDue > 0) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade100),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.red.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Collection Alert',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'You have ₹$totalDue pending collection from $duePayments ${duePayments == 1 ? 'payment' : 'payments'}',
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 12,
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
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCount(
    String label,
    int count,
    IconData icon, {
    Color? color,
  }) {
    final displayColor = color ?? Colors.grey.shade700;
    return Column(
      children: [
        Icon(icon, color: displayColor, size: 20),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: displayColor,
            fontSize: 16,
          ),
        ),
        Text(label, style: TextStyle(color: displayColor, fontSize: 12)),
      ],
    );
  }
}

class MonthYearPicker extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  const MonthYearPicker({
    Key? key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  }) : super(key: key);

  @override
  State<MonthYearPicker> createState() => _MonthYearPickerState();
}

class _MonthYearPickerState extends State<MonthYearPicker> {
  late DateTime _selectedDate;
  late int _currentYear;
  final List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _currentYear = _selectedDate.year;
  }

  bool _isValidMonth(int month) {
    final date = DateTime(_currentYear, month);
    return date.isAfter(widget.firstDate) && date.isBefore(widget.lastDate);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed:
                      _currentYear > widget.firstDate.year
                          ? () => setState(() => _currentYear--)
                          : null,
                ),
                Text(
                  _currentYear.toString(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed:
                      _currentYear < widget.lastDate.year
                          ? () => setState(() => _currentYear++)
                          : null,
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 2,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                final month = index + 1;
                final isSelected =
                    _selectedDate.year == _currentYear &&
                    _selectedDate.month == month;
                final isValid = _isValidMonth(month);

                return Card(
                  color: isSelected ? Theme.of(context).primaryColor : null,
                  child: InkWell(
                    onTap:
                        isValid
                            ? () {
                              _selectedDate = DateTime(_currentYear, month);
                              Navigator.pop(context, _selectedDate);
                            }
                            : null,
                    child: Center(
                      child: Text(
                        _months[index],
                        style: TextStyle(
                          color:
                              isSelected
                                  ? Colors.white
                                  : (isValid ? null : Colors.grey),
                          fontWeight: isSelected ? FontWeight.bold : null,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
