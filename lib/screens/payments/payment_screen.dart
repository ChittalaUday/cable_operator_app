import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/customer_model.dart';
import '../../models/payment_model.dart';
import '../../services/payment_service.dart';
import 'package:intl/intl.dart';

class PaymentScreen extends StatefulWidget {
  final Customer customer;

  const PaymentScreen({Key? key, required this.customer}) : super(key: key);

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = Uuid();

  late TextEditingController _amountController;
  late TextEditingController _modeController;
  late TextEditingController _noteController;
  DateTime _paymentDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _modeController = TextEditingController(text: 'Cash'); // default mode
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _modeController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectPaymentDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _paymentDate) {
      setState(() {
        _paymentDate = picked;
      });
    }
  }

  void _savePayment() async {
    if (_formKey.currentState!.validate()) {
      final amount = double.parse(_amountController.text.trim());
      final payment = Payment(
        id: _uuid.v4(),
        customerId: widget.customer.id,
        packageAmount: amount,
        amountPaid: amount, // Full amount paid
        amountDue: 0.0, // No due amount
        date: _paymentDate,
        mode: _modeController.text.trim(),
        note: _noteController.text.trim(),
        status: 'Paid',
        customerBalanceAfterThis: 0.0, // Will be calculated by service
      );

      await PaymentService.addPayment(payment);

      // Clear form
      _amountController.clear();
      _noteController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment recorded successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Payments for ${widget.customer.name}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Payment form
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(labelText: 'Amount (₹)'),
                    keyboardType: TextInputType.number,
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Enter amount';
                      if (int.tryParse(val) == null)
                        return 'Enter valid number';
                      return null;
                    },
                  ),

                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Payment Date: ${_paymentDate.toLocal().toString().split(' ')[0]}',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: _selectPaymentDate,
                  ),

                  TextFormField(
                    controller: _modeController,
                    decoration: const InputDecoration(
                      labelText: 'Payment Mode (Cash, Online, etc.)',
                    ),
                  ),

                  TextFormField(
                    controller: _noteController,
                    decoration: const InputDecoration(
                      labelText: 'Note (optional)',
                    ),
                  ),

                  const SizedBox(height: 12),

                  ElevatedButton(
                    onPressed: _savePayment,
                    child: const Text('Add Payment'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Payment history list header
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Payment History',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 8),

            // Payment history list
            Expanded(
              child: StreamBuilder<List<Payment>>(
                stream: PaymentService.getPaymentsByCustomer(
                  widget.customer.id,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  final payments = snapshot.data ?? [];
                  if (payments.isEmpty) {
                    return const Center(child: Text('No payments recorded.'));
                  }

                  return ListView.builder(
                    itemCount: payments.length,
                    itemBuilder: (context, index) {
                      final payment = payments[index];
                      return ListTile(
                        title: Text(
                          '₹${payment.packageAmount} - ${payment.mode}',
                        ),
                        subtitle: Text(
                          'Amount: ₹${(payment.amountPaid + payment.amountDue).toStringAsFixed(0)} • ${DateFormat('dd MMM yyyy').format(payment.date)}',
                        ),
                        isThreeLine: true,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
