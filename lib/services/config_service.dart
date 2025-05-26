import 'package:cloud_firestore/cloud_firestore.dart';

class ConfigService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of packages
  Stream<List<Map<String, dynamic>>> getPackages() {
    return _firestore
        .collection('packages')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => {'id': doc.id, ...doc.data()})
                  .toList(),
        );
  }

  // Stream of box types
  Stream<List<Map<String, dynamic>>> getBoxTypes() {
    return _firestore
        .collection('boxTypes')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => {'id': doc.id, ...doc.data()})
                  .toList(),
        );
  }

  // Stream of categories
  Stream<List<Map<String, dynamic>>> getCategories() {
    return _firestore
        .collection('categories')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => {'id': doc.id, ...doc.data()})
                  .toList(),
        );
  }
}
