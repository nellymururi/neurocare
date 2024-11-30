import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section 1: Displaying Real-Time Activity Data
              const Text(
                "Real-Time Activity Level",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              // StreamBuilder to fetch real-time data
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('steps_data')
                    .orderBy('timestamp', descending: true)
                    .limit(1) // Only get the most recent step data
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Text("Error fetching data.");
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Text("No data available.");
                  }

                  // Get the most recent data point (latest steps value)
                  var doc = snapshot.data!.docs.first;
                  int steps = doc['steps'] ?? 0;

                  // Determine the activity level based on the steps
                  String activityLevel = _getActivityLevel(steps);
                  Color progressBarColor = _getProgressBarColor(activityLevel);

                  // Display the real-time steps and activity level inside the card
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildCard(
                        title: "Current Activity Level",
                        content: Text("Steps: $steps"),
                      ),
                      const SizedBox(height: 16),
                      buildCard(
                        title: "Activity Level Indicator",
                        content: Text("Current Activity Level: $activityLevel"),
                        additionalContent: SizedBox(
                          height: 20,
                          child: LinearProgressIndicator(
                            value: _getProgressValue(activityLevel),
                            backgroundColor: Colors.grey.shade300,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(progressBarColor),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              // Other content like History or Insights
              buildCard(
                title: "Predicted Activity Levels",
                content: const Text("Prediction feature coming soon..."),
              ),
              const SizedBox(height: 16),
              buildCard(
                title: "History and Insights",
                content: const Text(
                    "Historical data and insights will appear here."),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Method to get the activity level based on the number of steps
  String _getActivityLevel(int steps) {
    if (steps >= 30) {
      return "High";
    } else if (steps >= 20) {
      return "Medium";
    } else if (steps >= 10) {
      return "Low";
    } else {
      return "Very Low";
    }
  }

  // Method to get the progress value based on the activity level
  double _getProgressValue(String activityLevel) {
    switch (activityLevel) {
      case "High":
        return 1.0; // Fully filled
      case "Medium":
        return 0.7; // 70% progress
      case "Low":
        return 0.4; // 40% progress
      case "Very Low":
        return 0.1; // 10% progress
      default:
        return 0.0; // No progress
    }
  }

  // Method to get the progress bar color based on the activity level
  Color _getProgressBarColor(String activityLevel) {
    switch (activityLevel) {
      case "High":
        return Colors.red; // Red for high activity
      case "Medium":
        return Colors.yellow; // Yellow for medium activity
      case "Low":
        return Colors.blue; // Blue for low activity
      case "Very Low":
        return Colors.grey; // Grey for very low activity
      default:
        return Colors.grey; // Default color if unknown level
    }
  }

  Widget buildCard({
    required String title,
    required Widget content,
    Widget? additionalContent,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            content,
            if (additionalContent != null) ...[
              const SizedBox(height: 12),
              additionalContent,
            ],
          ],
        ),
      ),
    );
  }
}
