import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'steps_record.dart'; // Import the StepsRecord page
import 'package:cloud_firestore/cloud_firestore.dart';
import 'predictions_record.dart';

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

  // Base URL of your Flask app
  final String baseUrl = 'http://192.168.100.90:5000';

  @override
  void initState() {
    super.initState();
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
          // Extract only the most recent step data
          final stepsList = data['steps'] as List<dynamic>;
          if (stepsList.isNotEmpty) {
            final mostRecentStep = stepsList.last;
            setState(() {
              currentMinuteSteps = {
                "steps": mostRecentStep['steps'] ?? 0,
                "time": mostRecentStep['time'] ?? "N/A",
              };
            });
          } else {
            setState(() {
              currentMinuteSteps = null;
            });
          }
        } else {
          setState(() {
            currentMinuteSteps = null;
          });
        }
      } else {
        throw Exception('Failed to fetch current minute steps');
      }
    } catch (e) {
      print('Error fetching current minute steps: $e');
    } finally {
      setState(() {
        isLoadingSteps = false;
      });
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
          await FirebaseFirestore.instance.collection('adhd_predictions').add({
            "classification": adhdPrediction!['adhd_classification'],
            "prediction_score": adhdPrediction!['adhd_prediction_score'],
            "timestamp": FieldValue.serverTimestamp(),
          });
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

  String getStepLevel(int steps) {
    if (steps >= 50) {
      return "Very High";
    } else if (steps >= 30) {
      return "Medium";
    } else if (steps >= 10) {
      return "Normal";
    } else {
      return "Very Low";
    }
  }

  double getProgressValue(int steps) {
    if (steps >= 50) {
      return 1.0; // Fully filled
    } else if (steps >= 30) {
      return 0.75; // 75% progress
    } else if (steps >= 10) {
      return 0.5; // 50% progress
    } else {
      return 0.25; // 25% progress
    }
  }

  Color getProgressColor(int steps) {
    if (steps >= 50) {
      return Colors.red; // Very High
    } else if (steps >= 30) {
      return Colors.orange; // Medium
    } else if (steps >= 10) {
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
                              content: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Level: ${getStepLevel(currentMinuteSteps!['steps'])}",
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
                                      borderRadius: BorderRadius.circular(
                                          10), // Rounded corners
                                      color:
                                          Colors.grey[300], // Background color
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: LinearProgressIndicator(
                                        value: getProgressValue(
                                            currentMinuteSteps!['steps']),
                                        backgroundColor: Colors
                                            .transparent, // Transparent for rounded corners
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          getProgressColor(
                                              currentMinuteSteps!['steps']),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
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

              buildCard(
                title: "History and Insights",
                content: const Text(
                  "Historical data and insights will appear here.",
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
