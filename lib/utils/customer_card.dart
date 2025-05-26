// lib/utils/customer_card.dart
import 'package:flutter/material.dart';
import '../../models/customer_model.dart';

class CustomerCard extends StatelessWidget {
  final Customer customer;
  final Function(String) onCall;
  final VoidCallback? onMenuPressed;

  const CustomerCard({
    super.key,
    required this.customer,
    required this.onCall,
    this.onMenuPressed,
  });

  @override
  Widget build(BuildContext context) {
    final subscriptionStatus = customer.subscriptionStatus;
    final isExpiringSoon = customer.isExpiringSoon;

    Color getStatusColor() {
      switch (subscriptionStatus.toLowerCase()) {
        case 'active':
          return const Color(0xFF10B981);
        case 'inactive':
          return const Color(0xFFEF4444);
        case 'pending':
          return const Color(0xFFF59E0B);
        case 'expired':
          return const Color(0xFFEF4444);
        case 'scheduled':
          return const Color(0xFF3B82F6);
        default:
          return const Color(0xFF6B7280);
      }
    }

    return RepaintBoundary(
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with name and status
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  Container(
                    height: 32,
                    width: 32,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          getStatusColor().withOpacity(0.8),
                          getStatusColor(),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Name and Status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          customer.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _buildChip(
                              text: subscriptionStatus.toUpperCase(),
                              color: getStatusColor(),
                              showDot: true,
                            ),
                            if (customer.isActive)
                              _buildChip(
                                text:
                                    '₹${customer.packageAmount.toStringAsFixed(0)}',
                                color: Colors.blue,
                                icon: Icons.currency_rupee,
                                iconSize: 10,
                              ),
                            if (isExpiringSoon)
                              _buildChip(
                                text: '${customer.remainingDays}d',
                                color: const Color(0xFFF59E0B),
                                icon: Icons.schedule_rounded,
                                iconSize: 10,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Menu Button
                  if (onMenuPressed != null)
                    SizedBox(
                      height: 32,
                      width: 32,
                      child: IconButton(
                        onPressed: onMenuPressed,
                        icon: const Icon(Icons.more_vert_rounded, size: 20),
                        padding: EdgeInsets.zero,
                        color: Colors.grey[600],
                        splashRadius: 20,
                      ),
                    ),
                ],
              ),

              // Contact Info and Details
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  // Contact Info
                  _buildInfoChip(
                    text: customer.phone,
                    icon: Icons.phone_rounded,
                    onTap: () => onCall(customer.phone),
                  ),
                  _buildInfoChip(
                    text: customer.address,
                    icon: Icons.location_on_rounded,
                  ),
                  // Additional Details
                  _buildInfoChip(
                    text: customer.monthlyPlan,
                    icon: Icons.subscriptions_rounded,
                  ),
                  _buildInfoChip(
                    text: '${customer.boxType} • ${customer.setupBoxSerial}',
                    icon: Icons.tv_rounded,
                  ),
                  if (customer.vcNumber.isNotEmpty)
                    _buildInfoChip(
                      text: customer.vcNumber,
                      icon: Icons.confirmation_number_rounded,
                    ),
                  _buildInfoChip(
                    text: customer.category,
                    icon: Icons.category_rounded,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required String text,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: Colors.grey.shade700),
              const SizedBox(width: 6),
              SelectableText(
                text,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade800,
                ),
                toolbarOptions: const ToolbarOptions(
                  copy: true,
                  selectAll: true,
                  cut: false,
                  paste: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip({
    required String text,
    required Color color,
    IconData? icon,
    double? iconSize,
    bool showDot = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              height: 6,
              width: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
          ],
          if (icon != null) ...[
            Icon(icon, size: iconSize ?? 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
