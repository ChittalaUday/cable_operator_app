import 'package:cloud_firestore/cloud_firestore.dart';

class Payment {
  final String id;
  final String customerId;
  final double packageAmount; // Total price of the service
  final double amountPaid; // Actual amount paid in this transaction
  final double amountDue; // Remaining unpaid amount
  final DateTime date;
  final String mode;
  final String note;
  final String status; // 'Paid', 'Partial', or 'Due'
  final double customerBalanceAfterThis;
  final String?
  parentPaymentId; // Reference to parent payment if this is an update
  final bool hasUpdates; // Indicates if this payment has updates

  Payment({
    required this.id,
    required this.customerId,
    required this.packageAmount,
    required this.amountPaid,
    required this.amountDue,
    required this.date,
    required this.mode,
    required this.note,
    required this.status,
    required this.customerBalanceAfterThis,
    this.parentPaymentId,
    this.hasUpdates = false,
  });

  factory Payment.fromMap(Map<String, dynamic> map, String id) {
    return Payment(
      id: id,
      customerId: map['customerId'] as String,
      packageAmount: (map['packageAmount'] as num).toDouble(),
      amountPaid: (map['amountPaid'] as num).toDouble(),
      amountDue: (map['amountDue'] as num).toDouble(),
      date: (map['date'] as Timestamp).toDate(),
      mode: map['mode'] as String,
      note: map['note'] as String,
      status: map['status'] as String,
      customerBalanceAfterThis:
          (map['customerBalanceAfterThis'] as num).toDouble(),
      parentPaymentId: map['parentPaymentId'] as String?,
      hasUpdates: map['hasUpdates'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'packageAmount': packageAmount,
      'amountPaid': amountPaid,
      'amountDue': amountDue,
      'date': Timestamp.fromDate(date),
      'mode': mode,
      'note': note,
      'status': status,
      'customerBalanceAfterThis': customerBalanceAfterThis,
      'parentPaymentId': parentPaymentId,
      'hasUpdates': hasUpdates,
    };
  }

  // Helper method to check if payment is complete
  bool get isComplete => status == 'Paid';

  // Helper method to check if payment is partial
  bool get isPartial => status == 'Partial';

  // Helper method to check if payment is due
  bool get isDue => status == 'Due';
}
