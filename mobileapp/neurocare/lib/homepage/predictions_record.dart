import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PredictionsRecord extends StatelessWidget {
  const PredictionsRecord({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Predictions Record"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('adhd_predictions')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Error fetching data."));
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
      ),
    );
  }
}
