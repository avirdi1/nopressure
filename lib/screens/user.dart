import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/login.dart';

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
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _calculateAverages();
  }

  Future<void> _loadProfile() async {
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('profiles').doc(user!.uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        weightController.text = data['weight'] ?? '';
        final height = data['height'] ?? "";
        final match = RegExp(r"(\d+)'(\d+)").firstMatch(height);
        if (match != null) {
          heightFeetController.text = match.group(1)!;
          heightInchesController.text = match.group(2)!;
        }
      });
    }
  }

  Future<void> _saveProfile() async {
    if (user == null) return;
    final height = "${heightFeetController.text}'${heightInchesController.text}";
    await FirebaseFirestore.instance.collection('profiles').doc(user!.uid).set({
      'height': height,
      'weight': weightController.text,
    });
    setState(() => isEditing = false);
  }

  Future<void> _calculateAverages() async {
    if (user == null) return;
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('logs')
        .get();

    final systolics = <int>[];
    final diastolics = <int>[];

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final s = int.tryParse(data['systolic'].toString());
      final d = int.tryParse(data['diastolic'].toString());
      if (s != null && d != null) {
        systolics.add(s);
        diastolics.add(d);
      }
    }

    setState(() {
      avgSystolic = systolics.isEmpty ? 0 : systolics.reduce((a, b) => a + b) / systolics.length;
      avgDiastolic = diastolics.isEmpty ? 0 : diastolics.reduce((a, b) => a + b) / diastolics.length;
    });
  }

  Widget buildProfileSection() {
    return Column(
      children: [
        const CircleAvatar(
          radius: 50,
          backgroundImage: AssetImage('images/nplogo.png'),
        ),
        const SizedBox(height: 10),
        Text(
          user?.email ?? 'User',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
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

  void _confirmSignOut() async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Sign Out"),
        content: const Text("Are you sure you want to sign out?"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: const Text("Sign Out", style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (shouldSignOut == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedHeight = (heightFeetController.text.isEmpty || heightInchesController.text.isEmpty)
        ? "Not set"
        : "${heightFeetController.text}'${heightInchesController.text}\"";

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 235, 235, 235),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 255, 1, 65),
        title: const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "User",
            style: TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _confirmSignOut,
          )
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 40),
          child: Column(
            children: [
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
