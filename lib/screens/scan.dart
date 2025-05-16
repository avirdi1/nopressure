import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  String? scanResult;
  bool isScanning = false;
  File? _scannedImage;

  Future<void> startScan() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile == null) return;

    setState(() {
      isScanning = true;
      _scannedImage = File(pickedFile.path);
    });

    final imageBytes = await File(pickedFile.path).readAsBytes();
    final base64Image = base64Encode(imageBytes);

    final jsonKey = await rootBundle.loadString('credentials/vision_key.json');
    final key = json.decode(jsonKey);
    final visionUrl = "https://vision.googleapis.com/v1/images:annotate?key=${key["private_key_id"]}";

    final response = await http.post(
      Uri.parse(visionUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "requests": [
          {
            "image": {"content": base64Image},
            "features": [
              {"type": "TEXT_DETECTION"}
            ]
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final text = data["responses"][0]["fullTextAnnotation"]["text"];
      setState(() => scanResult = text);

      final sysDia = extractSysDia(text);
      if (sysDia != null) {
        await addToLog(sysDia[0], sysDia[1]);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Reading added to log!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not detect blood pressure values.")),
        );
      }
    } else {
      print(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vision API request failed.")),
      );
    }

    setState(() => isScanning = false);
  }

  List<int>? extractSysDia(String text) {
    final regex = RegExp(r'(\d{2,3})[\s/:\\-]?(\d{2,3})');
    final match = regex.firstMatch(text);
    if (match != null) {
      final sys = int.tryParse(match.group(1)!);
      final dia = int.tryParse(match.group(2)!);
      if (sys != null && dia != null) {
        return [sys, dia];
      }
    }
    return null;
  }

  Future<void> addToLog(int systolic, int diastolic) async {
    final prefs = await SharedPreferences.getInstance();
    final logsByDateStr = prefs.getString('logsByDate') ?? '{}';
    final Map<String, dynamic> decoded = json.decode(logsByDateStr);

    final logs = Map<String, List<String>>.from(
      decoded.map((key, value) => MapEntry(key, List<String>.from(value))),
    );

    final now = DateTime.now();
    final dateKey = DateFormat('MMMM d, yyyy').format(now);
    final entry = '$dateKey - $systolic/$diastolic mmHg';

    logs[dateKey] = (logs[dateKey] ?? [])..insert(0, entry);
    await prefs.setString('logsByDate', json.encode(logs));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 235, 235, 235),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 255, 1, 65),
        title: const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Scan",
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
            if (_scannedImage != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Image.file(
                  _scannedImage!,
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            if (isScanning)
              const CircularProgressIndicator()
            else
              Center(
                child: ElevatedButton(
                  onPressed: startScan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 255, 1, 65),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: const Text(
                    "Start Scan",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            if (scanResult != null) ...[
              const Padding(
                padding: EdgeInsets.only(top: 20),
                child: Text("Recognized Text:", style: TextStyle(fontSize: 16)),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(scanResult!, textAlign: TextAlign.center),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
