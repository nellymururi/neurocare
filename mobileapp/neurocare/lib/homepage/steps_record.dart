import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class StepsRecord extends StatefulWidget {
  final String baseUrl;

  const StepsRecord({super.key, required this.baseUrl});

  @override
  _StepsRecordState createState() => _StepsRecordState();
}

class _StepsRecordState extends State<StepsRecord> {
  List<dynamic>? recordedSteps;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRecordedSteps();
  }

  Future<void> fetchRecordedSteps() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response =
          await http.get(Uri.parse('${widget.baseUrl}/real_time_steps'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            recordedSteps = (data['steps'] as List<dynamic>).reversed.toList();
          });
        } else {
          setState(() {
            recordedSteps = null;
          });
        }
      } else {
        throw Exception('Failed to fetch recorded steps');
      }
    } catch (e) {
      print('Error fetching recorded steps: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Steps Record"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : recordedSteps != null
              ? ListView.builder(
                  itemCount: recordedSteps!.length,
                  itemBuilder: (context, index) {
                    final step = recordedSteps![index];
                    return ListTile(
                      leading: const Icon(Icons.directions_walk),
                      title: Text("Steps: ${step['steps']}"),
                      subtitle: Text("Time: ${step['time']}"),
                    );
                  },
                )
              : const Center(child: Text("No recorded steps available.")),
    );
  }
}
