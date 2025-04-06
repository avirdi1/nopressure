import 'package:flutter/material.dart';
import 'screens/clinic.dart';
import 'screens/log.dart';
import 'screens/scan.dart';
import 'screens/chart.dart';
import 'screens/user.dart';
import 'landing.dart';

void main() {
  runApp(const NoPressureApp());
}

class NoPressureApp extends StatelessWidget {
  const NoPressureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NoPressure App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const LandingScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 2;

  final List<Widget> _pages = const [
    ClinicPage(),
    LogPage(),
    ScanPage(),
    ChartPage(),
    UserPage(),
  ];

  final List<String> _labels = ["Clinic", "Log", "Scan", "Chart", "User"];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(5, (index) {
            return GestureDetector(
              onTap: () => _onItemTapped(index),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _selectedIndex == index ? Colors.black : Colors.grey[400],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    _labels[index],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
