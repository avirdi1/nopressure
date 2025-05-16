import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ClinicPage extends StatefulWidget {
  const ClinicPage({super.key});

  @override
  State<ClinicPage> createState() => _ClinicPageState();
}

class _ClinicPageState extends State<ClinicPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _clinics = [];
  String? _errorMessage;
  late Position _userPosition;

  @override
  void initState() {
    super.initState();
    _loadClinics();
  }

  Future<void> _loadClinics() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage = 'Location services are disabled.';
          _loading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          setState(() {
            _errorMessage = 'Location permission denied.';
            _loading = false;
          });
          return;
        }
      }

      _userPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final fetched = await fetchAndSortClinics(_userPosition);
      setState(() {
        _clinics = fetched;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _loading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> fetchAndSortClinics(Position position) async {
    final apiKey = dotenv.env['GOOGLE_PLACES_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GOOGLE_PLACES_KEY is missing or not loaded.');
    }
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
      '?location=${position.latitude},${position.longitude}'
      '&radius=5000'
      '&keyword=urgent+care+clinic|doctor+office|medical+center'
      '&key=$apiKey',
    );

    final response = await http.get(url);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch clinics');
    }

    final data = json.decode(response.body);
    final results = data['results'] as List;

    final clinics = results.map<Map<String, dynamic>>((place) {
      final lat = place['geometry']['location']['lat'];
      final lng = place['geometry']['location']['lng'];
      final distance = Geolocator.distanceBetween(
        position.latitude, position.longitude, lat, lng,
      );

      return {
        'name': place['name'] ?? 'Unknown',
        'address': place['vicinity'] ?? 'No address provided',
        'lat': lat,
        'lng': lng,
        'rating': place['rating'],
        'user_ratings_total': place['user_ratings_total'],
        'open_now': place['opening_hours']?['open_now'],
        'distance': distance,
      };
    }).toList();

    clinics.sort((a, b) => a['distance'].compareTo(b['distance']));
    return clinics;
  }

  Future<void> _openMaps(double lat, double lng, String name) async {
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&destination_place_id=$name');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open Google Maps")),
      );
    }
  }

  Widget buildClinicList() {
    if (_clinics.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          "No real clinics found nearby which is only possible if you legit in the midde of nowhere",
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        itemCount: _clinics.length,
        itemBuilder: (context, index) {
          final clinic = _clinics[index];
          final distanceMiles = (clinic['distance'] / 1609).toStringAsFixed(1);
          final isOpen = clinic['open_now'];

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.local_hospital, color: Colors.red),
              title: Text(clinic['name']),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(clinic['address']),
                  Row(
                    children: [
                      if (clinic['rating'] != null)
                        Row(
                          children: [
                            const Icon(Icons.star, size: 16, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text('${clinic['rating']} (${clinic['user_ratings_total']} reviews)'),
                            const SizedBox(width: 8),
                          ],
                        ),
                      Text('📍 $distanceMiles mi'),
                    ],
                  ),
                  if (isOpen != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        isOpen ? '🟢 Open now' : '🔴 Closed',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isOpen ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.directions),
                onPressed: () {
                  _openMaps(clinic['lat'], clinic['lng'], Uri.encodeComponent(clinic['name']));
                },
              ),
            ),
          );
        },
      ),
    );
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
            "Clinics Nearby",
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
            const SizedBox(height: 10),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              )
            else
              buildClinicList(),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
