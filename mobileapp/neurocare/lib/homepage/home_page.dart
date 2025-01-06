import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'steps_record.dart'; // Import the StepsRecord page
import 'package:cloud_firestore/cloud_firestore.dart';
import 'predictions_record.dart';
import 'package:fl_chart/fl_chart.dart';
import 'predictions_graph.dart';
import 'alert_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? currentMinuteSteps;
  Map<String, dynamic>? adhdPrediction;
  bool isLoadingSteps = true;
  bool isLoadingPrediction = true;
  int _alertThreshold = 50; // Default threshold

  // Base URL of your Flask app
  final String baseUrl = 'http://192.168.100.90:5000';

  @override
  void initState() {
    super.initState();
    fetchAlertThreshold(); // Fetch threshold first
    fetchCurrentMinuteSteps();
    fetchADHDPredictions();
  }

  Future<void> fetchCurrentMinuteSteps() async {
    setState(() {
      isLoadingSteps = true;
    });

    try {
      final response = await http.get(Uri.parse('$baseUrl/real_time_steps'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          final stepsList = data['steps'] as List<dynamic>;
          if (stepsList.isNotEmpty) {
            final mostRecentStep = stepsList.last;

            setState(() {
              currentMinuteSteps = {
                "steps": mostRecentStep['steps'] ?? 0,
                "time": mostRecentStep['time'] ?? "N/A",
              };
            });

            // Store hourly data in Firestore
            final hour = mostRecentStep['time']?.split(":")[0] ?? "N/A";
            final stepCount = mostRecentStep['steps'] ?? 0;

            // Update or add hourly data
            final hourDoc = await FirebaseFirestore.instance
                .collection('steps_data')
                .doc(hour)
                .get();

            if (hourDoc.exists) {
              await hourDoc.reference.update({
                "steps": FieldValue.increment(stepCount),
              });
            } else {
              await FirebaseFirestore.instance
                  .collection('steps_data')
                  .doc(hour)
                  .set({
                "hour": hour,
                "steps": stepCount,
              });
            }
          }
        }
      } else {
        throw Exception('Failed to fetch real-time steps.');
      }
    } catch (e) {
      print('Error fetching current minute steps: $e');
    } finally {
      setState(() {
        isLoadingSteps = false;
      });
    }
  }

  Future<int> fetchTotalStepsForCurrentHour() async {
    final now = DateTime.now();
    final currentHour =
        now.hour.toString().padLeft(2, '0'); // Format hour as HH

    try {
      final hourDoc = await FirebaseFirestore.instance
          .collection('steps_data')
          .doc(currentHour)
          .get();

      if (hourDoc.exists) {
        return hourDoc.data()?['steps'] ?? 0; // Return step count
      }
    } catch (e) {
      print("Error fetching steps for current hour: $e");
    }

    return 0; // Default to 0 if no data exists
  }

  Future<void> fetchAlertThreshold() async {
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

  Future<void> fetchADHDPredictions() async {
    setState(() {
      isLoadingPrediction = true;
    });

    try {
      final response = await http.get(Uri.parse('$baseUrl/adhd_predictions'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            adhdPrediction = data['prediction'];
          });

          // Store the prediction in Firestore
          final predictionScore =
              ((adhdPrediction!['adhd_prediction_score'] ?? 0) * 100).toInt();

          final classification = adhdPrediction!['adhd_classification'];

          await FirebaseFirestore.instance.collection('adhd_predictions').add({
            "classification": classification,
            "prediction_score": predictionScore,
            "timestamp": FieldValue.serverTimestamp(),
          });

          // Add an alert if the prediction score is >= 50%
          // Trigger alert if score exceeds the threshold
          if (predictionScore >= _alertThreshold) {
            String severityLevel;

            if (predictionScore >= 90) {
              severityLevel = "Serious ADHD Detected";
            } else if (predictionScore >= 70) {
              severityLevel = "High ADHD Detected";
            } else if (predictionScore >= 50) {
              severityLevel = "Normal ADHD Detected";
            } else {
              severityLevel = "No Significant ADHD Detected";
            }

            final alertMessage = "ADHD Level: $severityLevel";

            // Store the alert in Firestore
            await FirebaseFirestore.instance.collection('alerts').add({
              "message": alertMessage,
              "timestamp": FieldValue.serverTimestamp(),
              "isRead": false, // Unread by default
            });

            // Trigger a pop-up notification
            _showNotification('ADHD Alert', alertMessage);
          }
        } else {
          setState(() {
            adhdPrediction = null;
          });
        }
      } else {
        throw Exception('Failed to fetch ADHD predictions');
      }
    } catch (e) {
      print('Error fetching ADHD predictions: $e');
    } finally {
      setState(() {
        isLoadingPrediction = false;
      });
    }
  }

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

  String getStepLevel(int hourlySteps) {
    if (hourlySteps >= 300) {
      return "Very High";
    } else if (hourlySteps >= 200) {
      return "Medium";
    } else if (hourlySteps >= 100) {
      return "Normal";
    } else {
      return "Very Low";
    }
  }

  double getProgressValue(int hourlySteps) {
    if (hourlySteps >= 300) {
      return 1.0; // Fully filled
    } else if (hourlySteps >= 200) {
      return 0.75; // 75% progress
    } else if (hourlySteps >= 100) {
      return 0.5; // 50% progress
    } else {
      return 0.25; // 25% progress
    }
  }

  Color getProgressColor(int hourlySteps) {
    if (hourlySteps >= 300) {
      return Colors.red; // Very High
    } else if (hourlySteps >= 200) {
      return Colors.orange; // Medium
    } else if (hourlySteps >= 100) {
      return Colors.green; // Normal
    } else {
      return Colors.grey; // Very Low
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Real-Time Steps Section
              const Text(
                "Real-Time Activity Level",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              isLoadingSteps
                  ? const Center(child: CircularProgressIndicator())
                  : currentMinuteSteps != null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () {
                                // Navigate to StepsRecord page when tapped
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        StepsRecord(baseUrl: baseUrl),
                                  ),
                                );
                              },
                              child: buildCard(
                                title: "Current Activity Level",
                                content: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Show the steps for the most recent minute
                                    Text(
                                      "Steps Count: ${currentMinuteSteps!['steps']}",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                    // Show the time for the most recent minute
                                    Text(
                                      "Time: ${currentMinuteSteps!['time']}",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontStyle: FontStyle.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Indicator Bar for Step Level
                            buildCard(
                              title: "Activity Level Indicator",
                              content: FutureBuilder<int>(
                                future:
                                    fetchTotalStepsForCurrentHour(), // Fetch hourly step count
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                        child: CircularProgressIndicator());
                                  }
                                  if (snapshot.hasError || !snapshot.hasData) {
                                    return const Text(
                                        "Error fetching step data.");
                                  }

                                  final hourlySteps = snapshot.data ??
                                      0; // Total steps for current hour
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Hourly Steps: $hourlySteps",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        height:
                                            20, // Adjusted height for a bigger indicator bar
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          color: Colors
                                              .grey[300], // Background color
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          child: LinearProgressIndicator(
                                            value:
                                                getProgressValue(hourlySteps),
                                            backgroundColor: Colors.transparent,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              getProgressColor(hourlySteps),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ],
                        )
                      : const Text("No steps data available."),

              const SizedBox(height: 16),

              // ADHD Predictions Section
              const Text(
                "Predicted Activity Level",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              isLoadingPrediction
                  ? const Center(child: CircularProgressIndicator())
                  : adhdPrediction != null
                      ? GestureDetector(
                          onTap: () {
                            // Navigate to Predictions Record page when tapped
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PredictionsRecord(),
                              ),
                            );
                          },
                          child: buildCard(
                            title: "ADHD Prediction",
                            content: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Classification Section
                                Row(
                                  children: [
                                    // Classification Indicator
                                    Container(
                                      width: 20, // Square width
                                      height: 20, // Square height
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(5),
                                        color: adhdPrediction![
                                                    'adhd_classification'] ==
                                                "ADHD Detected"
                                            ? Colors.red
                                            : Colors.green,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      adhdPrediction!['adhd_classification'],
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Prediction Score Section
                                const Text(
                                  "Prediction Score",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${((adhdPrediction!['adhd_prediction_score'] ?? 0) * 100).toStringAsFixed(1)}%",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : const Text("No ADHD predictions available."),
              const SizedBox(height: 16),

              // History and Insights Section
              const Text(
                "History and Insights",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  // Navigate to Predictions Graph Page
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PredictionsGraph()),
                  );
                },
                child: buildCard(
                  title: "Predictions Graph",
                  content: Container(
                    height: 300, // Adjusted graph height
                    child:
                        PredictionsGraph(), // Fetch and display predictions data
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildCard({
    required String title,
    required Widget content,
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
          ],
        ),
      ),
    );
  }
}

class PredictionsGraph extends StatelessWidget {
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
          List<BarChartGroupData> barGroups = [];
          List<String> labels = [];

          for (int i = 0; i < predictionsData.length; i++) {
            final prediction = predictionsData[i];
            final score = (prediction['prediction_score'] ?? 0).toDouble();
            final timestamp = prediction['timestamp'];

            if (timestamp != null && timestamp is Timestamp) {
              final time = timestamp.toDate();
              labels.add(
                  "${time.hour}:${time.minute.toString().padLeft(2, '0')}"); // Add exact time
              barGroups.add(
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: score,
                      width: 15,
                      color: Colors.green,
                    ),
                  ],
                ),
              );
            } else {
              print("Invalid or missing timestamp for prediction at index $i");
            }
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              width: barGroups.length * 40, // Dynamic width based on data
              child: BarChart(
                BarChartData(
                  barGroups: barGroups,
                  maxY: 100, // Fixed Y-axis to scale up to 100
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      axisNameWidget: const Text(
                        "Prediction Score (%)",
                        style: TextStyle(fontSize: 14),
                      ),
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 20,
                        reservedSize: 40,
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
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(
                    show: true,
                    border: const Border(
                      left: BorderSide(color: Colors.black, width: 1),
                      bottom: BorderSide(color: Colors.black, width: 1),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          "${rod.toY.toStringAsFixed(1)}%",
                          const TextStyle(color: Colors.white),
                        );
                      },
                    ),
                  ),
                  alignment: BarChartAlignment.spaceEvenly,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
