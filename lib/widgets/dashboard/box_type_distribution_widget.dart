import 'package:flutter/material.dart';
import '../../models/customer_model.dart';
import '../../utils/app_theme.dart';
import 'package:fl_chart/fl_chart.dart';

class BoxTypeDistributionWidget extends StatelessWidget {
  final List<Customer> customers;
  final List<String> boxTypes;

  const BoxTypeDistributionWidget({
    Key? key,
    required this.customers,
    required this.boxTypes,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate distribution
    Map<String, int> distribution = {};
    for (var type in boxTypes) {
      distribution[type] = customers.where((c) => c.boxType == type).length;
    }

    // Generate colors for each box type
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
    ];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Box Type Distribution',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (distribution.isEmpty)
              AppTheme.buildEmptyState(
                icon: Icons.pie_chart_outline,
                message: 'No Box Types',
                submessage: 'Add customers with different box types',
              )
            else
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sections: List.generate(distribution.length, (index) {
                      final type = distribution.keys.elementAt(index);
                      final count = distribution[type] ?? 0;
                      final percentage = (count / customers.length * 100);

                      return PieChartSectionData(
                        color: colors[index % colors.length],
                        value: count.toDouble(),
                        title: '${percentage.toStringAsFixed(1)}%',
                        radius: 100,
                        titleStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }),
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(distribution.length, (index) {
                final type = distribution.keys.elementAt(index);
                final count = distribution[type] ?? 0;

                return Chip(
                  avatar: CircleAvatar(
                    backgroundColor: colors[index % colors.length],
                    radius: 8,
                  ),
                  label: Text(
                    '$type ($count)',
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: colors[index % colors.length].withOpacity(
                    0.1,
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
