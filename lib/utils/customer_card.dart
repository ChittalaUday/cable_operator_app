// lib/utils/customer_card.dart
import 'package:flutter/material.dart';
import '../../models/customer_model.dart';
import '../utils/app_theme.dart';

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
    final theme = Theme.of(context);

    Color getStatusColor() {
      switch (subscriptionStatus.toLowerCase()) {
        case 'active':
          return AppTheme.statusConnected;
        case 'inactive':
          return AppTheme.statusDisconnected;
        case 'pending':
          return AppTheme.statusPending;
        case 'expired':
          return AppTheme.statusDisconnected;
        case 'scheduled':
          return theme.colorScheme.primary;
        default:
          return theme.colorScheme.onSurfaceVariant;
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
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
                // Avatar with status gradient
                Container(
                  height: 52,
                  width: 52,
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
                  child: Icon(
                    Icons.person_rounded,
                    color: theme.colorScheme.onPrimary,
                    size: 22,
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
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _buildStatusChip(
                            text: subscriptionStatus.toUpperCase(),
                            color: getStatusColor(),
                            showDot: true,
                            theme: theme,
                          ),
                          if (customer.isActive)
                            _buildStatusChip(
                              text:
                                  '₹${customer.packageAmount.toStringAsFixed(0)}',
                              color: theme.colorScheme.primary,
                              icon: Icons.currency_rupee,
                              iconSize: 10,
                              theme: theme,
                            ),
                          if (isExpiringSoon)
                            _buildStatusChip(
                              text: '${customer.remainingDays}d',
                              color: AppTheme.statusPending,
                              icon: Icons.schedule_rounded,
                              iconSize: 10,
                              theme: theme,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Menu Button
                if (onMenuPressed != null)
                  SizedBox(
                    height: 42,
                    width: 42,
                    child: IconButton(
                      onPressed: onMenuPressed,
                      icon: Icon(
                        Icons.more_vert_rounded,
                        size: 20,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      padding: EdgeInsets.zero,
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
                _buildInfoChip(
                  text: customer.phone,
                  icon: Icons.phone_rounded,
                  onTap: () => onCall(customer.phone),
                  theme: theme,
                ),
                _buildInfoChip(
                  text: customer.address,
                  icon: Icons.location_on_rounded,
                  theme: theme,
                ),
                _buildInfoChip(
                  text: customer.monthlyPlan,
                  icon: Icons.subscriptions_rounded,
                  theme: theme,
                ),
                _buildInfoChip(
                  text: '${customer.boxType} • ${customer.setupBoxSerial}',
                  icon: Icons.tv_rounded,
                  theme: theme,
                ),
                if (customer.vcNumber.isNotEmpty)
                  _buildInfoChip(
                    text: customer.vcNumber,
                    icon: Icons.confirmation_number_rounded,
                    theme: theme,
                  ),
                _buildInfoChip(
                  text: customer.category,
                  icon: Icons.category_rounded,
                  theme: theme,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required String text,
    required IconData icon,
    required ThemeData theme,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Color.alphaBlend(
        theme.colorScheme.onSurface.withOpacity(0.04),
        theme.colorScheme.surfaceVariant,
      ),
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  text,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip({
    required String text,
    required Color color,
    required ThemeData theme,
    IconData? icon,
    double? iconSize,
    bool showDot = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
            color.withOpacity(0.15), theme.colorScheme.surface),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              height: 6,
              width: 6,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          if (icon != null) ...[
            Icon(
              icon,
              size: iconSize ?? 12,
              color: color,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
