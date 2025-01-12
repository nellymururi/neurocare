import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // Number of tabs
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Admin Page"),
          backgroundColor: Colors.purple[200], // Lilac purple color
          bottom: const TabBar(
            tabs: [
              Tab(text: "Users", icon: Icon(Icons.people)),
              Tab(text: "Predictions", icon: Icon(Icons.analytics)),
              Tab(text: "Alerts", icon: Icon(Icons.notifications)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            RegisteredUsersTab(),
            PredictionsTab(),
            AlertsTab(),
          ],
        ),
        bottomNavigationBar: BottomAppBar(
          color: Colors.purple[200],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushReplacementNamed(context, '/login');
                },
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text(
                  "Logout",
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RegisteredUsersTab extends StatelessWidget {
  void _viewUserDetails(BuildContext context, String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UserDetailsPage(userId: userId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No registered users found."));
        }
        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>?;
            final name = data?['name'] ?? 'No Name';
            final email = data?['email'] ?? 'No Email';
            return ListTile(
              title: Text(name),
              subtitle: Text(email),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _viewUserDetails(context, doc.id),
            );
          },
        );
      },
    );
  }
}

class UserDetailsPage extends StatefulWidget {
  final String userId;

  UserDetailsPage({required this.userId});

  @override
  _UserDetailsPageState createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> {
  late Future<DocumentSnapshot> _userDetailsFuture;

  @override
  void initState() {
    super.initState();
    _userDetailsFuture = _fetchUserDetails();
  }

  Future<DocumentSnapshot> _fetchUserDetails() async {
    return await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get();
  }

  void _updateUser(Map<String, dynamic> currentData) {
    // Initialize controllers with current values
    final nameController =
        TextEditingController(text: currentData['name'] ?? '');
    final emailController =
        TextEditingController(text: currentData['email'] ?? '');
    final phoneController =
        TextEditingController(text: currentData['phone'] ?? '');
    final roleController =
        TextEditingController(text: currentData['role'] ?? '');
    final doctorNameController =
        TextEditingController(text: currentData['doctorName'] ?? '');
    final doctorEmailController =
        TextEditingController(text: currentData['doctorEmail'] ?? '');
    final doctorPhoneController =
        TextEditingController(text: currentData['doctorPhone'] ?? '');

    // Show dialog for editing user details
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Update User"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Name"),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Email"),
              ),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: "Phone"),
              ),
              TextField(
                controller: roleController,
                decoration: const InputDecoration(labelText: "Role"),
              ),
              const Divider(),
              TextField(
                controller: doctorNameController,
                decoration: const InputDecoration(labelText: "Doctor Name"),
              ),
              TextField(
                controller: doctorEmailController,
                decoration: const InputDecoration(labelText: "Doctor Email"),
              ),
              TextField(
                controller: doctorPhoneController,
                decoration: const InputDecoration(labelText: "Doctor Phone"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              // Fetch updated values
              final updatedData = {
                'name': nameController.text.trim(),
                'email': emailController.text.trim(),
                'phone': phoneController.text.trim(),
                'role': roleController.text.trim(),
                'doctorName': doctorNameController.text.trim(),
                'doctorEmail': doctorEmailController.text.trim(),
                'doctorPhone': doctorPhoneController.text.trim(),
              };

              // Validate non-empty fields
              if (updatedData.values.any((value) => value.isEmpty)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please fill in all fields.")),
                );
                return;
              }

              try {
                // Perform Firestore update
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.userId)
                    .update(updatedData);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("User updated successfully.")),
                );

                // Re-fetch updated data and refresh the UI
                setState(() {
                  _userDetailsFuture = _fetchUserDetails();
                });

                Navigator.pop(context); // Close dialog
              } catch (e) {
                // Log and display error
                print("Error updating user: $e");
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Failed to update user.")),
                );
              }
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  void _deleteUser(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User deleted successfully.")),
      );
      Navigator.pop(context);
    } catch (e) {
      print("Error deleting user: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to delete user.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Details"),
        backgroundColor: Colors.purple[200],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _userDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("User not found."));
          }
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                Text("Name: ${data?['name'] ?? 'N/A'}",
                    style: const TextStyle(fontSize: 18)),
                Text("Email: ${data?['email'] ?? 'N/A'}",
                    style: const TextStyle(fontSize: 18)),
                Text("Phone: ${data?['phone'] ?? 'N/A'}",
                    style: const TextStyle(fontSize: 18)),
                Text("Age: ${data?['age'] ?? 'N/A'}",
                    style: const TextStyle(fontSize: 18)),
                Text("Gender: ${data?['gender'] ?? 'N/A'}",
                    style: const TextStyle(fontSize: 18)),
                Text("Role: ${data?['role'] ?? 'N/A'}",
                    style: const TextStyle(fontSize: 18)),
                const Divider(),
                Text("Doctor Name: ${data?['doctorName'] ?? 'N/A'}",
                    style: const TextStyle(fontSize: 18)),
                Text("Doctor Email: ${data?['doctorEmail'] ?? 'N/A'}",
                    style: const TextStyle(fontSize: 18)),
                Text("Doctor Phone: ${data?['doctorPhone'] ?? 'N/A'}",
                    style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _updateUser(data ?? {}),
                      icon: const Icon(Icons.edit),
                      label: const Text("Edit"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple[200],
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: () => _deleteUser(context),
                      icon: const Icon(Icons.delete),
                      label: const Text("Delete"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class PredictionsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('adhd_predictions')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No predictions recorded."));
        }

        final predictionsData = snapshot.data!.docs;

        return ListView.builder(
          itemCount: predictionsData.length,
          itemBuilder: (context, index) {
            final prediction = predictionsData[index];
            final classification = prediction['classification'] ?? "Unknown";
            final score =
                (prediction['prediction_score'] ?? 0).toStringAsFixed(1);

            return ListTile(
              leading: classification == "ADHD Detected"
                  ? const Icon(Icons.warning, color: Colors.red)
                  : const Icon(Icons.check_circle, color: Colors.green),
              title: Text("Classification: $classification"),
              subtitle: Text("Prediction Score: $score%"),
              trailing: Text(
                prediction['timestamp'] != null
                    ? DateTime.fromMillisecondsSinceEpoch(
                            prediction['timestamp'].millisecondsSinceEpoch)
                        .toString()
                    : "Unknown Time",
              ),
            );
          },
        );
      },
    );
  }
}

class AlertsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('alerts')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No alerts available."));
        }

        final alerts = snapshot.data!.docs;

        return ListView.builder(
          itemCount: alerts.length,
          itemBuilder: (context, index) {
            final alert = alerts[index];
            return ListTile(
              title: Text(alert['message'] ?? "Unknown Alert"),
              subtitle: Text(
                alert['timestamp'] != null
                    ? DateTime.fromMillisecondsSinceEpoch(
                            alert['timestamp'].millisecondsSinceEpoch)
                        .toString()
                    : "Unknown Time",
              ),
              trailing: alert['isRead'] == false
                  ? const Icon(Icons.notifications_active, color: Colors.red)
                  : const Icon(Icons.notifications, color: Colors.grey),
              onTap: () async {
                await FirebaseFirestore.instance
                    .collection('alerts')
                    .doc(alert.id)
                    .update({"isRead": true});
              },
            );
          },
        );
      },
    );
  }
}
