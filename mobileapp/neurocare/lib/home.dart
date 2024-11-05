import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home "),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          "My Home Page",
          style: TextStyle(
            fontSize: 24, // You can adjust the font size as needed
            fontWeight: FontWeight.bold, // Makes the text bold
          ),
        ),
      ),
    );
  }
}
