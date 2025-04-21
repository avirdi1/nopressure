import 'package:flutter/material.dart';
import 'screens/clinic.dart';
import 'screens/log.dart';
import 'screens/scan.dart';
import 'screens/chart.dart';
import 'screens/user.dart';
import 'landing.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp( 
    options: DefaultFirebaseOptions.currentPlatform,
  );
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

  final List<String> _labels = ["Clinic", "Log", "+", "Chart", "User"];

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
        color: const Color.fromARGB(255, 235, 235, 235),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(5, (index) {
            return GestureDetector(
              onTap: () => _onItemTapped(index),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _selectedIndex == index ? Colors.grey[500] : Color.fromARGB(255, 255, 1, 65), //: Colors.grey[400],
                  borderRadius: index == 2 ? BorderRadius.circular(25) : BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    _labels[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: index == 2 ? 35 : 14,
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
