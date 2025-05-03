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

  Future<void> startScan() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile == null) return;

    setState(() => isScanning = true);

    final imageBytes = await File(pickedFile.path).readAsBytes();
    final base64Image = base64Encode(imageBytes);

    final jsonKey = await rootBundle.loadString('credentials/vision_key.json');
    final key = json.decode(jsonKey);
    final tokenUrl = "https://oauth2.googleapis.com/token";

    final jwtHeader = {
      "alg": "RS256",
      "typ": "JWT"
    };

    final iat = (DateTime.now().millisecondsSinceEpoch ~/ 1000);
    final exp = iat + 3600;
    final jwtClaimSet = {
      "iss": key["client_email"],
      "scope": "https://www.googleapis.com/auth/cloud-platform",
      "aud": tokenUrl,
      "iat": iat,
      "exp": exp
    };

    // TODO: use package like `dart_jsonwebtoken` to create JWT properly.
    // But for now we'll use API key shortcut for testing.

    final apiKey = key["private_key_id"];

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
      backgroundColor: const Color.fromARGB(255, 247, 239, 239),
      body: SafeArea(
        child: Column(
          children: [
            buildPageHeader("Scan"),
            const Spacer(),
            if (isScanning) const CircularProgressIndicator(),
            ElevatedButton(
              onPressed: isScanning ? null : startScan,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 255, 1, 65),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text(
                "Start Scan",
                style: TextStyle(fontSize: 18, color: Colors.white),
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