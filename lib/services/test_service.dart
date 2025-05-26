import 'package:cloud_firestore/cloud_firestore.dart';

class TestFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String collectionPath = "testCollection";

  // Create a new document with auto ID
  Future<void> createData(Map<String, dynamic> data) async {
    try {
      await _firestore.collection(collectionPath).add(data);
      print("Document Added Successfully");
    } catch (e) {
      print("Error adding document: $e");
    }
  }

  // Read all documents from the collection as a stream
  Stream<QuerySnapshot> readData() {
    return _firestore.collection(collectionPath).snapshots();
  }

  // Update a document by its documentId
  Future<void> updateData(String docId, Map<String, dynamic> newData) async {
    try {
      await _firestore.collection(collectionPath).doc(docId).update(newData);
      print("Document Updated Successfully");
    } catch (e) {
      print("Error updating document: $e");
    }
  }

  // Delete a document by its documentId
  Future<void> deleteData(String docId) async {
    try {
      await _firestore.collection(collectionPath).doc(docId).delete();
      print("Document Deleted Successfully");
    } catch (e) {
      print("Error deleting document: $e");
    }
  }
}
