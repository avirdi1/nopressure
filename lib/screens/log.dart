import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

class LogPage extends StatefulWidget {
  const LogPage({super.key});

  @override
  State<LogPage> createState() => _LogPageState();
}

class _LogPageState extends State<LogPage> {
  final TextEditingController systolicController = TextEditingController();
  final TextEditingController diastolicController = TextEditingController();
  Map<String, List<String>> logsByDate = {};

  DateTime selectedDate = DateTime.now();
  String get today => DateFormat('MMMM d, yyyy').format(selectedDate);

  @override
  void initState() {
    super.initState();
    _loadLogs(); 
  }

  void _loadLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLogs = prefs.getString('logsByDate') ?? '{}';  
    try {
      Map<String, dynamic> decoded = json.decode(savedLogs);

      // Ensure it is a Map<String, List<String>>
      setState(() {
        logsByDate = Map<String, List<String>>.from(
          decoded.map((key, value) {
            if (value is List) {
              return MapEntry(key, List<String>.from(value));
            } else {
              return MapEntry(key, []);
            }
          }),
        );
      });
    } catch (e) {
      print("Error decoding logs: $e");
      // Fallback if decoding fails
      setState(() {
        logsByDate = {};
      });
    }
  }

  void _saveLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final encodedLogs = json.encode(logsByDate);
    await prefs.setString('logsByDate', encodedLogs);
  }

  // Add new log entry
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

      final newEntry = '$today - $sys/$dia mmHg';

      setState(() {
        if (logsByDate.containsKey(today)) {
          logsByDate[today]?.insert(0, newEntry);
        } else {
          logsByDate[today] = [newEntry];
        }
        systolicController.clear();
        diastolicController.clear();
      });

      _saveLogs(); 

      // warning messages
      if (sys >= 180 || dia >= 120 || sys <= 80 || dia <= 50) {
        _showAlert(
          "⚠️ Emergency",
          "Your blood pressure is at a critical level. Please call or visit emergency services immediately.",
        );
      } else if (sys >= 140 || dia >= 90 || sys <= 90 || dia <= 60) {
        _showAlert(
          "Notice",
          "Your blood pressure is outside the normal range. If you're feeling symptoms like dizziness or headaches, please consult a doctor.",
        );
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

  // Edit existing log entry
  void _showEditDialog(String date, int index, String oldValue) {
    final bpPart = oldValue.split(' - ').last.split(' ')[0]; // gets '120/80'
    final parts = bpPart.split('/');
    final systolicEdit = TextEditingController(text: parts[0]);
    final diastolicEdit = TextEditingController(text: parts[1].replaceAll("mmHg", ""));

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
                  final newEntry = '$date - $systolic/$diastolic mmHg';
                  setState(() {
                    logsByDate[date]![index] = newEntry;
                  });
                  _saveLogs();
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
      backgroundColor: Colors.red[100],
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 255, 1, 65),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  "LOG",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
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
                    DateFormat('EEEE, MMM d').format(selectedDate), // or whatever format
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
              child: logsByDate.isEmpty
                  ? const Center(
                      child: Text(
                        "No logs yet",
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    )
                  : ListView.builder(
                      itemCount: logsByDate[today]?.length ?? 0,
                      itemBuilder: (context, index) {
                        final reading = logsByDate[today]![index];
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
                                    _showEditDialog(today, index, reading);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      logsByDate[today]!.removeAt(index);
                                      if (logsByDate[today]!.isEmpty) {
                                        logsByDate.remove(today);
                                      }
                                      _saveLogs();
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
