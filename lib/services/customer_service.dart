import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer_model.dart';

class CustomerService {
  static final CustomerService _instance = CustomerService._internal();
  factory CustomerService() => _instance;
  CustomerService._internal();

  final CollectionReference _customersRef = FirebaseFirestore.instance
      .collection('customers');

  /// Generates the next unique customer ID like "SSCN00101"
  Future<String> generateUniqueCustomerId() async {
    try {
      // Fetch all existing customer IDs starting with SSCN
      final snapshot = await _customersRef
          .orderBy(FieldPath.documentId)
          .startAt(['SSCN'])
          .endAt(['SSCN\uf8ff'])
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException('Failed to generate ID'),
          );

      // Extract existing numeric parts from IDs
      final existingIds =
          snapshot.docs
              .map((doc) => doc.id)
              .where((id) => id.startsWith('SSCN'))
              .toList();

      // Find max number suffix
      int maxNumber = 0;
      for (var id in existingIds) {
        final numberStr = id.substring(4); // after SSCN
        final number = int.tryParse(numberStr) ?? 0;
        if (number > maxNumber) maxNumber = number;
      }

      // Generate next number with leading zeros (e.g. SSCN00102)
      final nextNumber = (maxNumber + 1).toString().padLeft(5, '0');
      return 'SSCN$nextNumber';
    } catch (e) {
      throw Exception('Failed to generate customer ID: $e');
    }
  }

  /// Adds a new customer with a unique custom ID
  Future<void> addCustomer(Customer customer) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final newId = await generateUniqueCustomerId();

      // Make sure the ID doesn't exist already (extra safety)
      final docSnapshot = await _customersRef
          .doc(newId)
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException('Failed to check ID'),
          );

      if (docSnapshot.exists) {
        throw Exception('Generated customer ID already exists, try again.');
      }

      final customerWithId = Customer(
        id: newId,
        name: customer.name,
        phone: customer.phone,
        address: customer.address,
        connectionDate: customer.connectionDate,
        activationDate: customer.activationDate,
        deactivationDate: customer.deactivationDate,
        monthlyPlan: customer.monthlyPlan,
        setupBoxSerial: customer.setupBoxSerial,
        vcNumber: customer.vcNumber,
        category: customer.category,
        isActive: customer.isActive,
        packageAmount: customer.packageAmount,
        boxType: customer.boxType,
      );

      // Add the customer with the generated ID as document ID
      batch.set(_customersRef.doc(newId), customerWithId.toMap());
      await batch.commit().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Failed to add customer'),
      );
    } catch (e) {
      throw Exception('Failed to add customer: $e');
    }
  }

  /// Other existing methods...

  Future<List<Customer>> getAllCustomers() async {
    try {
      final snapshot = await _customersRef.get().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Failed to fetch customers'),
      );

      return snapshot.docs
          .map(
            (doc) =>
                Customer.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to get customers: $e');
    }
  }

  Future<Customer> getCustomer(String id) async {
    try {
      final doc = await _customersRef
          .doc(id)
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException('Failed to fetch customer'),
          );

      if (!doc.exists) {
        throw Exception('Customer not found');
      }

      return Customer.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      throw Exception('Failed to get customer: $e');
    }
  }

  Stream<List<Customer>> customersStream() {
    return _customersRef.snapshots().map(
      (snapshot) =>
          snapshot.docs
              .map(
                (doc) => Customer.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList(),
    );
  }

  Future<void> updateCustomer(Customer customer) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      batch.update(_customersRef.doc(customer.id), customer.toMap());

      await batch.commit().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Failed to update customer'),
      );
    } catch (e) {
      throw Exception('Failed to update customer: $e');
    }
  }

  Future<void> deleteCustomer(String id) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      batch.delete(_customersRef.doc(id));

      await batch.commit().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Failed to delete customer'),
      );
    } catch (e) {
      throw Exception('Failed to delete customer: $e');
    }
  }
}
