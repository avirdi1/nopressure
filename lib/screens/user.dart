import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  double avgSystolic = 0;
  double avgDiastolic = 0;

  final weightController = TextEditingController();
  final heightFeetController = TextEditingController();
  final heightInchesController = TextEditingController();
  bool isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _calculateAverages();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      weightController.text = prefs.getString('userWeight') ?? '';
      final savedHeight = prefs.getString('userHeight') ?? '';
      final heightParts = RegExp(r"(\d+)'(\d+)").firstMatch(savedHeight);
      if (heightParts != null) {
        heightFeetController.text = heightParts.group(1)!;
        heightInchesController.text = heightParts.group(2)!;
      }
    });
  }

  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final height = "${heightFeetController.text}'${heightInchesController.text}";
    await prefs.setString('userHeight', height);
    await prefs.setString('userWeight', weightController.text);
    setState(() => isEditing = false);
  }

  Future<void> _calculateAverages() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLogs = prefs.getString('logsByDate') ?? '{}';

    try {
      Map<String, dynamic> decoded = json.decode(savedLogs);
      final allReadings = <String>[];

      decoded.forEach((_, readings) {
        if (readings is List) {
          allReadings.addAll(List<String>.from(readings));
        }
      });

      final systolics = <int>[];
      final diastolics = <int>[];

      for (var reading in allReadings) {
        final match = RegExp(r'(\d+)/(\d+)').firstMatch(reading);
        if (match != null) {
          systolics.add(int.parse(match.group(1)!));
          diastolics.add(int.parse(match.group(2)!));
        }
      }

      setState(() {
        avgSystolic = systolics.isEmpty
            ? 0
            : systolics.reduce((a, b) => a + b) / systolics.length;
        avgDiastolic = diastolics.isEmpty
            ? 0
            : diastolics.reduce((a, b) => a + b) / diastolics.length;
      });
    } catch (e) {
      print("Error calculating averages: $e");
    }
  }

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

  Widget buildProfileSection() {
    return Column(
      children: [
        const CircleAvatar(
          radius: 50,
          backgroundImage: AssetImage('images/nplogo.png'),
        ),
        const SizedBox(height: 10),
        const Text(
          'Anmol Virdi',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 5),
        const Text(
          'Blood Pressure Tracker',
          style: TextStyle(color: Colors.black54),
        ),
      ],
    );
  }

  Widget buildVitalsCard(String label, String value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 18)),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget buildEditHeight() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: heightFeetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Height (ft)",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: heightInchesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "in",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildEditWeight() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: weightController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Weight (lbs)',
            border: OutlineInputBorder(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedHeight = (heightFeetController.text.isEmpty || heightInchesController.text.isEmpty)
        ? "Not set"
        : "${heightFeetController.text}'${heightInchesController.text}\"";

    return Scaffold(
      backgroundColor: Colors.purple[100],
      body: SafeArea(
        child: SingleChildScrollView( // <-- Wrap with scroll view
          padding: const EdgeInsets.only(bottom: 40),
          child: Column(
            children: [
              buildPageHeader("User"),
              const SizedBox(height: 20),
              buildProfileSection(),
              const SizedBox(height: 30),
              buildVitalsCard("Average Systolic", avgSystolic == 0 ? "No data" : "${avgSystolic.toStringAsFixed(1)} mmHg"),
              buildVitalsCard("Average Diastolic", avgDiastolic == 0 ? "No data" : "${avgDiastolic.toStringAsFixed(1)} mmHg"),
              isEditing
                  ? Column(
                      children: [
                        buildEditHeight(),
                        buildEditWeight(),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 255, 1, 65),
                          ),
                          child: const Text("Save", style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        buildVitalsCard("Height", formattedHeight),
                        buildVitalsCard("Weight", weightController.text.isEmpty ? "Not set" : "${weightController.text} lbs"),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () => setState(() => isEditing = true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 255, 1, 65),
                          ),
                          child: const Text("Edit", style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
