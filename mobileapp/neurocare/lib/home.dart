import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'homepage/home_page.dart'; // Import HomePage
import 'homepage/alert_page.dart'; // Import AlertPage
import 'homepage/profile_page.dart'; // Import ProfilePage

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int _currentIndex = 0; // Bottom navigation index
  int _unreadAlertsCount = 0; // Track unread alerts

  final List<Widget> _pages = [
    const HomePage(),
    const AlertPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _fetchUnreadAlertsCount(); // Fetch unread alerts count
  }

  // Fetch unread alerts count
  void _fetchUnreadAlertsCount() {
    FirebaseFirestore.instance
        .collection('alerts')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _unreadAlertsCount = snapshot.docs.length;
      });
    });
  }

  // Mark all alerts as read
  Future<void> _markAllAlertsAsRead() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('alerts')
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.update({"isRead": true});
    }

    setState(() {
      _unreadAlertsCount = 0; // Reset the count locally
    });
  }

  // Function to handle logout
  Future<void> _logout() async {
    try {
      await _auth.signOut();
      // Navigate back to the login screen
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      // Handle any errors during logout
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error logging out: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "NeuroCare Dashboard",
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
              leading: const Icon(Icons.info,
                  color: Color.fromARGB(255, 107, 70, 176)),
              title: const Text('About'),
              onTap: () {
                Navigator.pushNamed(context, '/about');
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
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color.fromARGB(255, 107, 70, 176),
        unselectedItemColor: Colors.grey,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.notifications),
                if (_unreadAlertsCount > 0)
                  Positioned(
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$_unreadAlertsCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Alerts',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        onTap: (index) async {
          setState(() {
            _currentIndex = index;
          });

          // If Alerts page is selected, mark all alerts as read
          if (index == 1) {
            await _markAllAlertsAsRead();
          }
        },
      ),
    );
  }
}
