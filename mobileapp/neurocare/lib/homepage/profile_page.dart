import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _patientNameController = TextEditingController();
  final TextEditingController _doctorNameController = TextEditingController();
  final TextEditingController _doctorEmailController = TextEditingController();
  final TextEditingController _doctorPhoneController = TextEditingController();

  late String userId;
  String? photoURL;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    userId = _auth.currentUser?.uid ?? '';
    photoURL = _auth.currentUser?.photoURL; // Get the profile photo URL
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        _nameController.text = data['name'] ?? '';
        _emailController.text = _auth.currentUser?.email ?? '';
        _phoneController.text = data['phone'] ?? '';
        _patientNameController.text = data['patientName'] ?? '';
        _doctorNameController.text = data['doctorName'] ?? '';
        _doctorEmailController.text = data['doctorEmail'] ?? '';
        _doctorPhoneController.text = data['doctorPhone'] ?? '';
      } else {
        _emailController.text = _auth.currentUser?.email ?? '';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching profile: ${e.toString()}')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _updateProfile() async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'patientName': _patientNameController.text,
        'doctorName': _doctorNameController.text,
        'doctorEmail': _doctorEmailController.text,
        'doctorPhone': _doctorPhoneController.text,
      }, SetOptions(merge: true));

      if (_emailController.text != _auth.currentUser?.email) {
        await _auth.currentUser?.updateEmail(_emailController.text);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: ${e.toString()}')),
      );
    }
  }

  Future<void> _deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
      await _firestore.collection('users').doc(userId).delete();
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting account: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : Scaffold(
            appBar: AppBar(
              title: const Text('Profile'),
              backgroundColor: const Color.fromARGB(255, 249, 249, 249),
              actions: [
                if (photoURL != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: CircleAvatar(
                      backgroundImage: NetworkImage(photoURL!),
                      radius: 18,
                    ),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(Icons.account_circle),
                  ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  buildLabelField("Name", _nameController),
                  buildLabelField("Email", _emailController),
                  buildLabelField("Phone", _phoneController),
                  buildLabelField("Patient's Name", _patientNameController),
                  buildLabelField("Doctor's Name", _doctorNameController),
                  buildLabelField("Doctor's Email", _doctorEmailController),
                  buildLabelField("Doctor's Phone", _doctorPhoneController),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _updateProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 223, 218, 232),
                          ),
                          child: const Text("Update Profile"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _deleteAccount,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 223, 218, 232),
                          ),
                          child: const Text("Delete Account"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
  }

  Widget buildLabelField(String label, TextEditingController controller,
      {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}
