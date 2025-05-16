import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LogPage extends StatefulWidget {
  const LogPage({super.key});

  @override
  State<LogPage> createState() => _LogPageState();
}

class _LogPageState extends State<LogPage> {
  final TextEditingController systolicController = TextEditingController();
  final TextEditingController diastolicController = TextEditingController();
  Map<String, List<Map<String, dynamic>>> logsByDate = {};
  bool _loading = true;

  DateTime selectedDate = DateTime.now();
  String get today => DateFormat('MMMM d, yyyy').format(selectedDate);

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  void _loadLogs() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('logs')
          .orderBy('timestamp', descending: true)
          .get();

      Map<String, List<Map<String, dynamic>>> grouped = {};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (!data.containsKey('systolic') || !data.containsKey('diastolic') || !data.containsKey('timestamp')) continue;
        final date = DateFormat('MMMM d, yyyy').format(data['timestamp'].toDate());
        final reading = {
          'value': "${data['systolic']}/${data['diastolic']} mmHg",
          'id': doc.id
        };
        if (!grouped.containsKey(date)) grouped[date] = [];
        grouped[date]!.add(reading);
      }

      setState(() {
        logsByDate = grouped;
        _loading = false;
      });
    } catch (e) {
      print("Error loading logs from Firestore: $e");
      setState(() {
        logsByDate = {};
        _loading = false;
      });
    }
  }

  void _saveLogToFirestore(String sys, String dia) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance.collection('users').doc(uid).collection('logs').add({
      'systolic': sys,
      'diastolic': dia,
      'timestamp': DateTime.now(),
    });
  }

  void _updateLogInFirestore(String docId, String sys, String dia) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance.collection('users').doc(uid).collection('logs').doc(docId).update({
      'systolic': sys,
      'diastolic': dia,
    });
  }

  void _deleteLogFromFirestore(String docId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance.collection('users').doc(uid).collection('logs').doc(docId).delete();
  }

  void logEntry() {
    final systolic = systolicController.text;
    final diastolic = diastolicController.text;

    if (systolic.isNotEmpty && diastolic.isNotEmpty) {
      final sys = int.tryParse(systolic);
      final dia = int.tryParse(diastolic);

      if (sys == null || dia == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Invalid input. Please enter valid numbers."),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      systolicController.clear();
      diastolicController.clear();

      _saveLogToFirestore(sys.toString(), dia.toString());
      _loadLogs();

      if (sys >= 180 || dia >= 120 || sys <= 80 || dia <= 50) {
        _showAlert("⚠️ Emergency", "Your blood pressure is at a critical level. Please call or visit emergency services immediately.");
      } else if (sys >= 140 || dia >= 90 || sys <= 90 || dia <= 60) {
        _showAlert("Notice", "Your blood pressure is outside the normal range. If you're feeling symptoms like dizziness or headaches, please consult a doctor.");
      }

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter both systolic and diastolic values"),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text("OK"),
            onPressed: () => Navigator.of(context).pop(),
          )
        ],
      ),
    );
  }

  void _showEditDialog(String date, int index, String oldValue, String docId) {
    final parts = oldValue.replaceAll(" mmHg", "").split("/");
    final systolicEdit = TextEditingController(text: parts[0]);
    final diastolicEdit = TextEditingController(text: parts[1]);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Edit Entry"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: systolicEdit,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Systolic'),
              ),
              TextField(
                controller: diastolicEdit,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Diastolic'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                final systolic = systolicEdit.text;
                final diastolic = diastolicEdit.text;

                if (systolic.isNotEmpty && diastolic.isNotEmpty) {
                  final newEntry = {'value': '$systolic/$diastolic mmHg', 'id': docId};
                  setState(() {
                    logsByDate[date]![index] = newEntry;
                  });
                  _updateLogInFirestore(docId, systolic, diastolic);
                  Navigator.of(ctx).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please enter both systolic and diastolic values"),
                      duration: Duration(seconds: 2),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final dateKeys = logsByDate.keys.toList();
    dateKeys.sort((a, b) => DateFormat('MMMM d, yyyy').parse(b).compareTo(DateFormat('MMMM d, yyyy').parse(a)));

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 235, 235, 235),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 255, 1, 65),
        title: const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Log",
            style: TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_left),
                  onPressed: () {
                    setState(() {
                      selectedDate = selectedDate.subtract(const Duration(days: 1));
                    });
                  },
                ),
                TextButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        selectedDate = picked;
                      });
                    }
                  },
                  icon: const Icon(Icons.calendar_today, color: Colors.black54),
                  label: Text(
                    DateFormat('EEEE, MMM d').format(selectedDate),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_right),
                  onPressed: () {
                    if (!isToday(selectedDate)) {
                      setState(() {
                        selectedDate = selectedDate.add(const Duration(days: 1));
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: systolicController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Systolic',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: diastolicController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Diastolic',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: logEntry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 255, 1, 65),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'Save Reading',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            const Divider(thickness: 1),
            const SizedBox(height: 10),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : logsByDate[today] == null || logsByDate[today]!.isEmpty
                      ? const Center(
                          child: Text(
                            "No logs yet",
                            style: TextStyle(fontSize: 16, color: Colors.black54),
                          ),
                        )
                      : ListView.builder(
                          itemCount: logsByDate[today]!.length,
                          itemBuilder: (context, index) {
                            final entry = logsByDate[today]![index];
                            final reading = entry['value'];
                            final docId = entry['id'];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: ListTile(
                                title: Text(reading),
                                trailing: Wrap(
                                  spacing: 12,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () {
                                        _showEditDialog(today, index, reading, docId);
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () {
                                        _deleteLogFromFirestore(docId);
                                        setState(() {
                                          logsByDate[today]!.removeAt(index);
                                          if (logsByDate[today]!.isEmpty) {
                                            logsByDate.remove(today);
                                          }
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
