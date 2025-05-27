import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class Customer {
  final String id;
  final String name;
  final String phone;
  final String address;
  final DateTime connectionDate;
  final DateTime? activationDate;
  final DateTime? deactivationDate;
  final String monthlyPlan;
  final String setupBoxSerial;
  final String vcNumber;
  final String category;
  final bool isActive;
  final double packageAmount;
  final String boxType;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.connectionDate,
    this.activationDate,
    this.deactivationDate,
    required this.monthlyPlan,
    required this.setupBoxSerial,
    required this.vcNumber,
    required this.category,
    required this.isActive,
    required this.packageAmount,
    required this.boxType,
  });

  factory Customer.fromMap(Map<String, dynamic> data, String documentId) {
    DateTime? parseDateTime(dynamic value) {
      if (value == null || (value is String && value.trim().isEmpty)) {
        return null;
      }

      if (value is Timestamp) {
        return value.toDate();
      }

      if (value is String) {
        // Remove any invalid characters and clean up the string
        String cleanDate = value.replaceAll(RegExp(r'\s+'), ' ').trim();

        // Handle empty or invalid strings
        if (cleanDate.isEmpty || cleanDate == 'null') {
          return null;
        }

        // First, handle the case where we have a double T in the string
        if (cleanDate.contains('T00:00:00T00:00:00')) {
          try {
            final datePart = cleanDate.split('T00:00:00')[0];
            return DateTime.parse('${datePart}T00:00:00Z');
          } catch (e) {
            debugPrint('Error parsing double T date: $cleanDate - $e');
          }
        }

        // Handle case where we have T[time]T00:00:00
        if (cleanDate.contains('T')) {
          final parts = cleanDate.split('T');
          if (parts.length > 2) {
            try {
              // Take the date and first time part
              return DateTime.parse('${parts[0]}T${parts[1]}Z');
            } catch (e) {
              debugPrint('Error parsing T-split date: $cleanDate - $e');
            }
          }
        }

        // Try parsing as ISO date
        try {
          return DateTime.parse(cleanDate);
        } catch (e) {
          debugPrint('Error parsing clean date: $cleanDate - $e');

          // Try parsing as different formats
          try {
            // Try DD-MM-YYYY format
            final parts = cleanDate.split(RegExp(r'[-/]'));
            if (parts.length == 3) {
              return DateTime(
                int.parse(parts[2]), // year
                int.parse(parts[1]), // month
                int.parse(parts[0]), // day
              );
            }
          } catch (e) {
            debugPrint('Error parsing alternative format: $cleanDate - $e');
          }
          return null;
        }
      }

      return null;
    }

    // Parse dates with fallback to current date for required fields
    final DateTime now = DateTime.now();
    final DateTime connectionDate =
        parseDateTime(data['connectionDate']) ?? now;
    final DateTime? activationDate = parseDateTime(data['activationDate']);
    final DateTime? deactivationDate = parseDateTime(data['deactivationDate']);

    return Customer(
      id: documentId,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      address: data['address'] ?? '',
      connectionDate: connectionDate,
      activationDate: activationDate,
      deactivationDate: deactivationDate,
      monthlyPlan: data['monthlyPlan'] ?? '',
      setupBoxSerial: data['setupBoxSerial'] ?? '',
      vcNumber: data['vcNumber'] ?? '',
      category: data['category'] ?? '',
      isActive: data['isActive'] ?? false,
      packageAmount: (data['packageAmount'] ?? 0.0).toDouble(),
      boxType: data['boxType'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'address': address,
      'connectionDate': connectionDate.toIso8601String(),
      'activationDate': activationDate?.toIso8601String(),
      'deactivationDate': deactivationDate?.toIso8601String(),
      'monthlyPlan': monthlyPlan,
      'setupBoxSerial': setupBoxSerial,
      'vcNumber': vcNumber,
      'category': category,
      'isActive': isActive,
      'packageAmount': packageAmount,
      'boxType': boxType,
    };
  }

  // Helper method to get subscription status
  String get subscriptionStatus {
    if (!isActive) return 'Inactive';

    final now = DateTime.now();
    if (activationDate == null) return 'Pending';
    if (deactivationDate == null) return 'Active';

    if (now.isBefore(activationDate!)) return 'Scheduled';
    if (now.isAfter(deactivationDate!)) return 'Expired';
    return 'Active';
  }

  // Helper method to get remaining days
  int get remainingDays {
    if (deactivationDate == null) return 0;
    return deactivationDate!.difference(DateTime.now()).inDays;
  }

  // Helper method to check if subscription is expiring soon (within 7 days)
  bool get isExpiringSoon {
    if (deactivationDate == null) return false;
    final daysRemaining = remainingDays;
    return daysRemaining >= 0 && daysRemaining <= 7;
  }
}
