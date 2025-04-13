import 'package:flutter/material.dart';

class ChartPage extends StatelessWidget {
  const ChartPage({super.key});

  Widget buildPageHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 255, 1, 65),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange[100],
      body: SafeArea(
        child: Column(
          children: [
            buildPageHeader("Chart"),
            const Spacer(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
