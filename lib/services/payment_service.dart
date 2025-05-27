import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_model.dart';

class PaymentService {
  static final CollectionReference _customersRef = FirebaseFirestore.instance
      .collection('customers');

  /// Add a new payment under a customer's 'payments' subcollection
  static Future<void> addPayment(Payment payment) async {
    final paymentsRef = _customersRef
        .doc(payment.customerId)
        .collection('payments');

    // Get the latest payment to calculate balance
    final latestPayment = await _getLatestPayment(payment.customerId);
    double previousBalance = latestPayment?.customerBalanceAfterThis ?? 0.0;

    // Calculate new balance based on payment status
    double newBalance;
    switch (payment.status) {
      case 'Paid':
        newBalance = previousBalance - payment.amountPaid;
        break;
      case 'Partial':
      case 'Due':
        newBalance = previousBalance + payment.amountDue;
        break;
      default:
        throw Exception('Invalid payment status: ${payment.status}');
    }

    // Create payment with updated balance
    final paymentWithBalance = Payment(
      id: payment.id,
      customerId: payment.customerId,
      packageAmount: payment.packageAmount,
      amountPaid: payment.amountPaid,
      amountDue: payment.amountDue,
      date: payment.date,
      mode: payment.mode,
      note: payment.note,
      status: payment.status,
      customerBalanceAfterThis: newBalance,
    );

    await paymentsRef.doc(payment.id).set(paymentWithBalance.toMap());

    // Update customer document
    final Map<String, dynamic> customerUpdate = {'currentBalance': newBalance};

    // Only update lastPaymentDate if it's not a due payment
    if (payment.status != 'Due') {
      customerUpdate['lastPaymentDate'] = Timestamp.fromDate(payment.date);
    }

    await _customersRef.doc(payment.customerId).update(customerUpdate);
  }

  /// Get the latest payment for a customer
  static Future<Payment?> _getLatestPayment(String customerId) async {
    final querySnapshot =
        await _customersRef
            .doc(customerId)
            .collection('payments')
            .orderBy('date', descending: true)
            .limit(1)
            .get();

    if (querySnapshot.docs.isEmpty) return null;

    return Payment.fromMap(
      querySnapshot.docs.first.data(),
      querySnapshot.docs.first.id,
    );
  }

  /// Get current balance for a customer
  static Future<double> getCurrentBalance(String customerId) async {
    final latestPayment = await _getLatestPayment(customerId);
    return latestPayment?.customerBalanceAfterThis ?? 0.0;
  }

  /// Get total amount paid by a customer
  static Future<double> getTotalPaidByCustomer(String customerId) async {
    final querySnapshot =
        await _customersRef.doc(customerId).collection('payments').get();

    double total = 0;
    for (var doc in querySnapshot.docs) {
      final payment = Payment.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
      total += payment.amountPaid;
    }
    return total;
  }

  /// Get total amount due by a customer
  static Future<double> getTotalDueByCustomer(String customerId) async {
    final querySnapshot =
        await _customersRef.doc(customerId).collection('payments').get();

    double total = 0;
    for (var doc in querySnapshot.docs) {
      final payment = Payment.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
      total += payment.amountDue;
    }
    return total;
  }

  /// Get total package amount for a customer
  static Future<double> getTotalPackageAmount(String customerId) async {
    final querySnapshot =
        await _customersRef.doc(customerId).collection('payments').get();

    double total = 0;
    for (var doc in querySnapshot.docs) {
      final payment = Payment.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
      total += payment.packageAmount;
    }
    return total;
  }

  /// Get payments for a specific customer as a stream, ordered by date descending
  static Stream<List<Payment>> getPaymentsByCustomer(String customerId) {
    return _customersRef
        .doc(customerId)
        .collection('payments')
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => Payment.fromMap(
                      doc.data() as Map<String, dynamic>,
                      doc.id,
                    ),
                  )
                  .toList(),
        );
  }

  /// Get all payments across all customers (for admin dashboard)
  /// Without requiring Firestore index
  static Stream<List<Payment>> getAllPayments() {
    return FirebaseFirestore.instance
        .collectionGroup('payments')
        .snapshots()
        .map((snapshot) {
          final payments =
              snapshot.docs
                  .map(
                    (doc) => Payment.fromMap(
                      doc.data() as Map<String, dynamic>,
                      doc.id,
                    ),
                  )
                  .toList();

          // Sort locally by date descending
          payments.sort((a, b) => b.date.compareTo(a.date));

          return payments;
        });
  }

  /// Get payments for a customer within a specific date range
  static Stream<List<Payment>> getPaymentsByDateRange(
    String customerId,
    DateTime start,
    DateTime end,
  ) {
    return _customersRef
        .doc(customerId)
        .collection('payments')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => Payment.fromMap(
                      doc.data() as Map<String, dynamic>,
                      doc.id,
                    ),
                  )
                  .toList(),
        );
  }

  /// Fetch a single payment by customerId and paymentId
  static Future<Payment?> getPaymentById(
    String customerId,
    String paymentId,
  ) async {
    final docSnapshot =
        await _customersRef
            .doc(customerId)
            .collection('payments')
            .doc(paymentId)
            .get();

    if (docSnapshot.exists) {
      return Payment.fromMap(
        docSnapshot.data() as Map<String, dynamic>,
        docSnapshot.id,
      );
    }
    return null;
  }

  /// Delete a payment by customerId and paymentId
  static Future<void> deletePayment(String customerId, String paymentId) async {
    try {
      // Get the payment to be deleted
      final payment = await getPaymentById(customerId, paymentId);
      if (payment == null) {
        throw Exception('Payment not found');
      }

      // Get the latest payment to recalculate balance
      final latestPayment = await _getLatestPayment(customerId);
      double previousBalance = latestPayment?.customerBalanceAfterThis ?? 0.0;

      // Calculate new balance based on deleted payment's status
      double newBalance;
      switch (payment.status) {
        case 'Paid':
          newBalance = previousBalance + payment.amountPaid;
          break;
        case 'Partial':
        case 'Due':
          newBalance = previousBalance - payment.amountDue;
          break;
        default:
          throw Exception('Invalid payment status: ${payment.status}');
      }

      // Delete the payment
      await _customersRef
          .doc(customerId)
          .collection('payments')
          .doc(paymentId)
          .delete();

      // Update customer balance
      await _customersRef.doc(customerId).update({
        'currentBalance': newBalance,
      });
    } catch (e) {
      throw Exception('Failed to delete payment: $e');
    }
  }

  /// Add a payment update under the original payment's updates subcollection
  static Future<void> addPaymentUpdate(
    String originalPaymentId,
    Payment updatePayment,
  ) async {
    final originalPaymentRef =
        await _customersRef
            .doc(updatePayment.customerId)
            .collection('payments')
            .doc(originalPaymentId)
            .get();

    if (!originalPaymentRef.exists) {
      throw Exception('Original payment not found');
    }

    final originalPayment = Payment.fromMap(
      originalPaymentRef.data()!,
      originalPaymentRef.id,
    );

    // Calculate new balance
    final latestPayment = await _getLatestPayment(updatePayment.customerId);
    double previousBalance = latestPayment?.customerBalanceAfterThis ?? 0.0;
    double newBalance;

    switch (updatePayment.status) {
      case 'Paid':
        newBalance = previousBalance - updatePayment.amountPaid;
        break;
      case 'Partial':
        newBalance = previousBalance - updatePayment.amountPaid;
        break;
      default:
        throw Exception(
          'Invalid payment status for update: ${updatePayment.status}',
        );
    }

    // Create payment update with the calculated balance
    final paymentWithBalance = Payment(
      id: updatePayment.id,
      customerId: updatePayment.customerId,
      packageAmount: originalPayment.packageAmount,
      amountPaid: updatePayment.amountPaid,
      amountDue: originalPayment.amountDue - updatePayment.amountPaid,
      date: updatePayment.date,
      mode: updatePayment.mode,
      note: updatePayment.note,
      status: updatePayment.status,
      customerBalanceAfterThis: newBalance,
      parentPaymentId: originalPaymentId,
    );

    // Add update to the updates subcollection
    await _customersRef
        .doc(updatePayment.customerId)
        .collection('payments')
        .doc(originalPaymentId)
        .collection('updates')
        .doc(updatePayment.id)
        .set(paymentWithBalance.toMap());

    // Calculate new totals for original payment
    final newAmountPaid = originalPayment.amountPaid + updatePayment.amountPaid;
    final newAmountDue = originalPayment.amountDue - updatePayment.amountPaid;
    final newStatus = newAmountDue <= 0 ? 'Paid' : 'Partial';

    // Update original payment
    await _customersRef
        .doc(updatePayment.customerId)
        .collection('payments')
        .doc(originalPaymentId)
        .update({
          'amountPaid': newAmountPaid,
          'amountDue': newAmountDue,
          'hasUpdates': true,
          'status': newStatus,
        });

    // Update customer document
    final customerUpdate = {
      'currentBalance': newBalance,
      'lastPaymentDate': Timestamp.fromDate(updatePayment.date),
    };

    await _customersRef.doc(updatePayment.customerId).update(customerUpdate);
  }

  /// Get payment updates for a specific payment
  static Stream<List<Payment>> getPaymentUpdates(
    String customerId,
    String paymentId,
  ) {
    return _customersRef
        .doc(customerId)
        .collection('payments')
        .doc(paymentId)
        .collection('updates')
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => Payment.fromMap(doc.data(), doc.id))
                  .toList(),
        );
  }
}
