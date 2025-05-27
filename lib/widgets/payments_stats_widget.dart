import 'package:flutter/material.dart';
import '../models/payment_model.dart';
import '../utils/app_theme.dart';
import 'common/modern_text_field.dart';

class PaymentStatsWidget extends StatefulWidget {
  final List<Payment> payments;

  const PaymentStatsWidget({
    Key? key,
    required this.payments,
  }) : super(key: key);

  @override
  State<PaymentStatsWidget> createState() => _PaymentStatsWidgetState();
}

class _PaymentStatsWidgetState extends State<PaymentStatsWidget> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final stats = _calculatePaymentStats(widget.payments);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ModernCard(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with expand/collapse
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(0),
              child: Row(
                children: [
                  Icon(
                    Icons.analytics_rounded,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Stats',
                    style: AppTheme.bodyLarge.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '₹${stats['totalAmount'].toStringAsFixed(0)}',
                    style: AppTheme.bodyLarge.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    ' (${stats['totalCount']})',
                    style: AppTheme.bodyMedium.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),

          // Expandable content
          AnimatedCrossFade(
            firstChild: const SizedBox(height: 0),
            secondChild: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ModernDivider(margin: EdgeInsets.zero),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Total Amount',
                            style: AppTheme.bodyMedium.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Total Payments',
                            style: AppTheme.bodyMedium.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '₹${stats['totalAmount'].toStringAsFixed(0)}',
                            style: AppTheme.headingMedium.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${stats['totalCount']}',
                            style: AppTheme.headingMedium.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatusCard(
                              context,
                              'Paid',
                              stats['statusCount']['Paid'] ?? 0,
                              stats['statusAmount']['Paid'] ?? 0,
                              AppTheme.statusConnected,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatusCard(
                              context,
                              'Due',
                              stats['statusCount']['Due'] ?? 0,
                              stats['statusAmount']['Due'] ?? 0,
                              AppTheme.statusDisconnected,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(
    BuildContext context,
    String status,
    int count,
    double amount,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            status,
            style: AppTheme.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$count payments',
            style: AppTheme.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: AppTheme.headingSmall.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _calculatePaymentStats(List<Payment> payments) {
    double totalAmount = 0;
    int totalCount = payments.length;
    Map<String, int> statusCount = {'Paid': 0, 'Due': 0};
    Map<String, double> statusAmount = {
      'Paid': 0.0,
      'Due': 0.0,
    };

    for (var payment in payments) {
      totalAmount += payment.packageAmount;

      if (payment.status.toLowerCase() == 'paid') {
        statusCount['Paid'] = (statusCount['Paid'] ?? 0) + 1;
        statusAmount['Paid'] =
            (statusAmount['Paid'] ?? 0) + payment.packageAmount;
      } else if (payment.status.toLowerCase() == 'due') {
        statusCount['Due'] = (statusCount['Due'] ?? 0) + 1;
        statusAmount['Due'] = (statusAmount['Due'] ?? 0) + payment.amountDue;
      } else if (payment.status.toLowerCase() == 'partial') {
        statusAmount['Paid'] = (statusAmount['Paid'] ?? 0) + payment.amountPaid;
        statusAmount['Due'] = (statusAmount['Due'] ?? 0) + payment.amountDue;
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
}

// Enhanced Alternative Design with Cards Layout
class PaymentStatsCardsWidget extends StatelessWidget {
  final List<Payment> payments;

  const PaymentStatsCardsWidget({
    Key? key,
    required this.payments,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final stats = _calculatePaymentStats(payments);

    return Column(
      children: [
        // Quick Stats Row
        _buildQuickStatsRow(context, stats),
        const SizedBox(height: 16),
        // Detailed Cards
        _buildDetailedCards(context, stats),
      ],
    );
  }

  Widget _buildQuickStatsRow(BuildContext context, Map<String, dynamic> stats) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: _buildQuickStatCard(
              context,
              '₹${stats['totalAmount'].toStringAsFixed(0)}',
              'Total Amount',
              Icons.account_balance_wallet,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildQuickStatCard(
              context,
              '${stats['totalCount']}',
              'Total Payments',
              Icons.receipt,
              Colors.purple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatCard(
    BuildContext context,
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedCards(BuildContext context, Map<String, dynamic> stats) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildStatusDetailCard(
            context,
            'Paid Payments',
            stats['statusCount']['Paid'] ?? 0,
            stats['statusAmount']['Paid'] ?? 0,
            Icons.check_circle,
            Colors.green,
            'Successfully completed',
          ),
          const SizedBox(height: 12),
          _buildStatusDetailCard(
            context,
            'Due Payments',
            stats['statusCount']['Due'] ?? 0,
            stats['statusAmount']['Due'] ?? 0,
            Icons.pending,
            Colors.orange,
            'Awaiting payment',
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDetailCard(
    BuildContext context,
    String title,
    int count,
    double amount,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '$count payments',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '₹${amount.toStringAsFixed(0)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: color,
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
    );
  }

  Map<String, dynamic> _calculatePaymentStats(List<Payment> payments) {
    double totalAmount = 0;
    int totalCount = payments.length;
    Map<String, int> statusCount = {'Paid': 0, 'Due': 0};
    Map<String, double> statusAmount = {'Paid': 0.0, 'Due': 0.0};

    for (var payment in payments) {
      totalAmount += payment.packageAmount;

      if (payment.status.toLowerCase() == 'paid') {
        statusCount['Paid'] = (statusCount['Paid'] ?? 0) + 1;
        statusAmount['Paid'] =
            (statusAmount['Paid'] ?? 0) + payment.packageAmount;
      } else if (payment.status.toLowerCase() == 'due') {
        statusCount['Due'] = (statusCount['Due'] ?? 0) + 1;
        statusAmount['Due'] = (statusAmount['Due'] ?? 0) + payment.amountDue;
      } else if (payment.status.toLowerCase() == 'partial') {
        // For partial payments, split the amounts
        statusAmount['Paid'] = (statusAmount['Paid'] ?? 0) + payment.amountPaid;
        statusAmount['Due'] = (statusAmount['Due'] ?? 0) + payment.amountDue;
        // Count as due if there's any amount due
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
}
