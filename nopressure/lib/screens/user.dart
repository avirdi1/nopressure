import 'package:flutter/material.dart';

class UserPage extends StatelessWidget {
  const UserPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple[100],
      body: Stack(
        children: [
          Positioned(
            top: 100, 
            left: 15,
            right: 15, 
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 129, 129, 129),
                borderRadius: BorderRadius.circular(30),  
              ),
              child: const Text(
                "User",
                style: TextStyle(
                  color: Color.fromARGB(255, 255, 255, 255),  
                  fontSize: 50,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Positioned(
            top: 400, 
            left: MediaQuery.of(context).size.width / 2 - 60, 
            child: ElevatedButton(
              onPressed: () {
                // TODO: Add logic
              },
              child: const Text("User Settings"),
            ),
          ),
        ],
      ),
    );
  }
}
