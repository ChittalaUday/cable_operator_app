import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/payment_model.dart';
import '../../services/payment_service.dart';

class PaymentsNotifier extends ChangeNotifier {
  List<Payment> _payments = [];
  Map<String, String> _customerNames = {};
  StreamSubscription<List<Payment>>? _paymentSubscription;

  List<Payment> get payments => _payments;
  Map<String, String> get customerNames => _customerNames;

  PaymentsNotifier() {
    _listenPayments();
  }

  void _listenPayments() {
    _paymentSubscription = PaymentService.getAllPayments().listen((
      paymentsData,
    ) async {
      _payments = paymentsData;
      notifyListeners();
      await _fetchCustomerNames(paymentsData);
    });
  }

  Future<void> _fetchCustomerNames(List<Payment> payments) async {
    final ids = payments.map((p) => p.customerId).toSet().toList();
    if (ids.isEmpty) {
      _customerNames = {};
      notifyListeners();
      return;
    }

    final chunks = <List<String>>[];
    for (var i = 0; i < ids.length; i += 10) {
      chunks.add(ids.sublist(i, i + 10 > ids.length ? ids.length : i + 10));
    }

    Map<String, String> namesMap = {};
    for (var chunk in chunks) {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('customers')
              .where(FieldPath.documentId, whereIn: chunk)
              .get();

      for (var doc in snapshot.docs) {
        namesMap[doc.id] = doc['name'] ?? 'Unknown';
      }
    }

    _customerNames = namesMap;
    notifyListeners();
  }

  Future<void> refresh() async {
    // To refresh, clear customer names and refetch for current payments
    _customerNames = {};
    notifyListeners();
    await _fetchCustomerNames(_payments);
  }

  @override
  void dispose() {
    _paymentSubscription?.cancel();
    super.dispose();
  }
}
