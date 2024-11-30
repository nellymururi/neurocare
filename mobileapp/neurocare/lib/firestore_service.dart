import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add a user with UID as the document ID
  Future<void> addUser(
      String uid, String name, String email, String phone, String role) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
      });
      print("User added successfully!");
    } catch (e) {
      print("Error adding user: $e");
    }
  }
}
