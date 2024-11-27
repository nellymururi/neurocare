import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Function to handle logout
  Future<void> _logout() async {
    try {
      await _auth.signOut();
      // Navigate back to the authentication screen
      Navigator.of(context).pushReplacementNamed(
          '/login'); // Ensure '/auth' is the route to your authentication screen
    } catch (e) {
      // Handle any errors during logout
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error logging out: ${e.toString()}")),
      );
    }
  }

  // Placeholder for fetching real-time steps (Google Fit integration)
  // Future<String> getRealTimeSteps() async {
  //   // Placeholder for the data fetched from Google Fit
  //   return "1200"; // Example real-time step count
  // }
// buildCard function definition
  Widget buildCard({
    required String title,
    required String content,
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
            Text(
              content,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
            if (additionalContent != null) ...[
              const SizedBox(height: 12),
              additionalContent,
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "NeuroCare",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor:
            const Color.fromARGB(255, 107, 70, 176), // Lavender AppBar
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 107, 70, 176), // Lavender background
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home,
                  color: Color.fromARGB(255, 107, 70, 176)),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.note,
                  color: Color.fromARGB(255, 107, 70, 176)),
              title: const Text('Notes'),
              onTap: () {
                Navigator.pushNamed(context, '/notes');
              },
            ),

            ListTile(
              leading: const Icon(Icons.settings,
                  color: Color.fromARGB(255, 107, 70, 176)),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info,
                  color: Color.fromARGB(255, 107, 70, 176)),
              title: const Text('About'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            const Divider(), // Adds a separator before logout
            ListTile(
              leading: const Icon(Icons.logout,
                  color: Color.fromARGB(255, 107, 70, 176)),
              title: const Text('Logout'),
              onTap: () async {
                await _logout(); // Call the logout function
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              buildCard(
                title: "Real-Time Activity Level",
                content: "Steps: 1200 (Placeholder for real-time data)",
              ),
              const SizedBox(height: 16),
              buildCard(
                title: "Activity Level Indicator",
                content: "Current Activity Level: Medium",
                additionalContent: SizedBox(
                  height: 20,
                  child: LinearProgressIndicator(
                    value: 0.7,
                    backgroundColor: Colors.grey.shade300,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              buildCard(
                title: "Predicted Activity Levels",
                content: "Prediction feature coming soon...",
              ),
              const SizedBox(height: 16),
              buildCard(
                title: "History and Insights",
                content: "Historical data and insights will appear here.",
              ),
            ],
          ),
        ),
      ),
    );
  }
}


              //Commented out for future API integration
              // FutureBuilder<String>(
              //   future: getRealTimeSteps(),
              //   builder: (context, snapshot) {
              //     if (snapshot.connectionState == ConnectionState.waiting) {
              //       return const Center(
              //         child: CircularProgressIndicator(),
              //       );
              //     } else if (snapshot.hasError) {
              //       return const Text("Error fetching real-time data");
              //     } else {
              //       return Text(
              //         "Steps: ${snapshot.data}",
              //         style: const TextStyle(fontSize: 16, color: Colors.black),
              //       );
              //     }
              //   },
              // ),