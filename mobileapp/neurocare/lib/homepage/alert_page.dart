import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AlertPage extends StatefulWidget {
  const AlertPage({super.key});

  @override
  State<AlertPage> createState() => _AlertPageState();
}

class _AlertPageState extends State<AlertPage> {
  int _alertThreshold = 50; // Default threshold
  late FirebaseMessaging _messaging;

  @override
  void initState() {
    super.initState();
    _fetchAlertThreshold();
    _setupFirebaseMessaging();
  }

  // Fetch the current threshold from Firestore
  void _fetchAlertThreshold() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('alertThreshold')
          .get();

      if (doc.exists) {
        setState(() {
          _alertThreshold = doc.data()?['threshold'] ?? 50;
        });
      }
    } catch (e) {
      print("Error fetching alert threshold: $e");
    }
  }

  // Save the updated threshold to Firestore
  void _updateAlertThreshold(int newThreshold) async {
    try {
      await FirebaseFirestore.instance
          .collection('settings')
          .doc('alertThreshold')
          .set({'threshold': newThreshold});

      setState(() {
        _alertThreshold = newThreshold;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Alert threshold updated successfully.")),
      );
    } catch (e) {
      print("Error updating alert threshold: $e");
    }
  }

  // Firebase Messaging Setup
  void _setupFirebaseMessaging() async {
    _messaging = FirebaseMessaging.instance;

    // Request notification permissions
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else {
      print('User declined or has not accepted permission');
    }

    // Get the device token (useful for sending targeted notifications)
    String? token = await _messaging.getToken();
    print("Device Token: $token");

    // Listen for foreground notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground Message: ${message.notification?.title}');
      _showNotification(message.notification?.title ?? 'Alert',
          message.notification?.body ?? 'ADHD Alert');
    });

    // Handle when the app is opened via a notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification clicked!');
    });
  }

  // Show a notification pop-up in the app
  void _showNotification(String title, String body) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Open a dialog to customize the threshold
  void _showThresholdDialog() {
    final TextEditingController _controller =
        TextEditingController(text: _alertThreshold.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Set Alert Threshold"),
          content: TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "Threshold (%)",
              hintText: "Enter a value (e.g., 50)",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                final newThreshold = int.tryParse(_controller.text);
                if (newThreshold != null && newThreshold > 0) {
                  _updateAlertThreshold(newThreshold);
                  Navigator.of(context).pop(); // Close the dialog
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Please enter a valid number.")),
                  );
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Alerts"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showThresholdDialog, // Open the dialog
            tooltip: "Customize Alert Threshold",
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('alerts')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Error fetching alerts."));
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
                  // Mark alert as read
                  await FirebaseFirestore.instance
                      .collection('alerts')
                      .doc(alert.id)
                      .update({"isRead": true});
                },
              );
            },
          );
        },
      ),
    );
  }
}
