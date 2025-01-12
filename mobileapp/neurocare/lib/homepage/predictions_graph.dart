import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PredictionsGraph extends StatelessWidget {
  const PredictionsGraph({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Predictions Graph"),
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
            return const Center(child: Text("No data available."));
          }

          final predictionsData = snapshot.data!.docs;

          // Create bar groups and labels
          List<BarChartGroupData> barGroups = [];
          List<String> labels = [];
          double maxY = 0; // Track the maximum value for scaling the Y-axis.

          for (int i = 0; i < predictionsData.length; i++) {
            final prediction = predictionsData[i];
            final rawScore = prediction['prediction_score'] ?? 0;
            final score = double.tryParse(rawScore.toString()) ??
                0.0; // Convert to double
            final timestamp = prediction['timestamp']?.toDate();

            if (timestamp != null) {
              labels.add(
                  "${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}");
              barGroups.add(
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: score, // Use the correctly parsed score
                      width: 10,
                      color: Colors.green,
                    ),
                  ],
                ),
              );

              // Update maxY to set a proper Y-axis limit
              if (score > maxY) {
                maxY = score;
              }
            }
          }

          // Display the bar chart
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              height: 300, // Adjust graph height
              child: BarChart(
                BarChartData(
                  barGroups: barGroups,
                  maxY: maxY + 10, // Add some buffer above the highest score
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      axisNameWidget: const Text(
                        "Prediction Score (%)",
                        style: TextStyle(fontSize: 14),
                      ),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: (maxY > 0) ? maxY / 5 : 20,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      axisNameWidget: const Text(
                        "Time (HH:mm)",
                        style: TextStyle(fontSize: 14),
                      ),
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < labels.length) {
                            return Text(
                              labels[index],
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(
                    show: true,
                    border: const Border(
                      left: BorderSide(color: Colors.black, width: 1),
                      bottom: BorderSide(color: Colors.black, width: 1),
                    ),
                  ),
                  barTouchData: BarTouchData(enabled: false),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
