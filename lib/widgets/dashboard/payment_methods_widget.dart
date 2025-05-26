import 'package:flutter/material.dart';
import '../../models/payment_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class PaymentMethodsWidget extends StatelessWidget {
  final List<Payment> payments;
  final List<String> paymentModes;

  const PaymentMethodsWidget({
    Key? key,
    required this.payments,
    required this.paymentModes,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Methods',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _generatePieSections(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  startDegreeOffset: -90,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Wrap(spacing: 16, runSpacing: 8, children: _buildLegendItems()),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _generatePieSections() {
    final Map<String, double> modeAmounts = {};
    double totalAmount = 0;

    for (var payment in payments) {
      if (payment.status == 'Paid' || payment.status == 'Partial') {
        modeAmounts[payment.mode] =
            (modeAmounts[payment.mode] ?? 0) + payment.amountPaid;
        totalAmount += payment.amountPaid;
      }
    }

    final List<Color> colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
    ];

    return List.generate(paymentModes.length, (index) {
      final mode = paymentModes[index];
      final amount = modeAmounts[mode] ?? 0;
      final percentage = totalAmount > 0 ? amount / totalAmount : 0;

      return PieChartSectionData(
        color: colors[index % colors.length],
        value: percentage * 100,
        title: '${(percentage * 100).toStringAsFixed(1)}%',
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    });
  }

  List<Widget> _buildLegendItems() {
    final Map<String, double> modeAmounts = {};
    final currencyFormat = NumberFormat.currency(symbol: '₹');

    for (var payment in payments) {
      if (payment.status == 'Paid' || payment.status == 'Partial') {
        modeAmounts[payment.mode] =
            (modeAmounts[payment.mode] ?? 0) + payment.amountPaid;
      }
    }

    final List<Color> colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
    ];

    return List.generate(paymentModes.length, (index) {
      final mode = paymentModes[index];
      final amount = modeAmounts[mode] ?? 0;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colors[index % colors.length].withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colors[index % colors.length].withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: colors[index % colors.length],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              mode,
              style: TextStyle(
                color: colors[index % colors.length],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              currencyFormat.format(amount),
              style: TextStyle(
                color: colors[index % colors.length],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    });
  }
}
