import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChartPage extends StatefulWidget {
  const ChartPage({super.key});

  @override
  State<ChartPage> createState() => _ChartPageState();
}

class _ChartPageState extends State<ChartPage> {
  List<String> labels = [];
  List<double> systolic = [];
  List<double> diastolic = [];

  @override
  void initState() {
    super.initState();
    _loadAndPrepareData();
  }

  Future<void> _loadAndPrepareData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final now = DateTime.now();
    final formatter = DateFormat('MMMM d, yyyy');
    final labelFormat = DateFormat('EEE');

    List<String> past7 = List.generate(7, (i) {
      return formatter.format(now.subtract(Duration(days: 6 - i)));
    });

    List<double> sysAvg = [];
    List<double> diaAvg = [];
    List<String> xLabels = [];

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('logs')
        .orderBy('timestamp', descending: false)
        .get();

    Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (!data.containsKey('systolic') || !data.containsKey('diastolic') || !data.containsKey('timestamp')) continue;
      final date = formatter.format(data['timestamp'].toDate());
      if (!grouped.containsKey(date)) grouped[date] = [];
      grouped[date]!.add({
        'systolic': int.tryParse(data['systolic'].toString()),
        'diastolic': int.tryParse(data['diastolic'].toString())
      });
    }

    for (var dateStr in past7) {
      final entries = grouped[dateStr];
      final dayLabel = labelFormat.format(formatter.parse(dateStr));
      if (entries != null && entries.isNotEmpty) {
        List<int> sys = [];
        List<int> dia = [];

        for (var entry in entries) {
          if (entry['systolic'] != null) sys.add(entry['systolic']);
          if (entry['diastolic'] != null) dia.add(entry['diastolic']);
        }

        sysAvg.add(sys.isNotEmpty ? sys.reduce((a, b) => a + b) / sys.length : 0);
        diaAvg.add(dia.isNotEmpty ? dia.reduce((a, b) => a + b) / dia.length : 0);
      } else {
        sysAvg.add(0);
        diaAvg.add(0);
      }
      xLabels.add(dayLabel);
    }

    setState(() {
      labels = xLabels;
      systolic = sysAvg;
      diastolic = diaAvg;
    });
  }

  Widget buildLegend() {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.circle, size: 10, color: Colors.red),
          SizedBox(width: 4),
          Text("Systolic  "),
          Icon(Icons.circle, size: 10, color: Colors.blue),
          SizedBox(width: 4),
          Text("Diastolic"),
        ],
      ),
    );
  }

  Widget buildBarChart() {
    return BarChart(
      BarChartData(
        maxY: 190,
        minY: 50,
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 35),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                return i >= 0 && i < labels.length
                    ? Text(labels[i], style: const TextStyle(fontSize: 12))
                    : const Text('');
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barGroups: List.generate(labels.length, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: systolic[i],
                width: 6,
                color: Colors.red,
              ),
              BarChartRodData(
                toY: diastolic[i],
                width: 6,
                color: Colors.blue,
              ),
            ],
            barsSpace: 4,
          );
        }),
        gridData: FlGridData(show: true),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(enabled: true),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: 60,
              color: Colors.purple.withOpacity(0.25),
              strokeWidth: 80,
            ),
            HorizontalLine(
              y: 95,
              color: Colors.green.withOpacity(0.25),
              strokeWidth: 190,
            ),
            HorizontalLine(
              y: 130,
              color: Colors.yellow.withOpacity(0.25),
              strokeWidth: 78,
            ),
            HorizontalLine(
              y: 165,
              color: Colors.red.withOpacity(0.25),
              strokeWidth: 190,
            ),
          ],
        ),
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
            "Chart",
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
            buildLegend(),
            const Text("High 🔴  Pre-High 🟡  Ideal 🟢  Low 🟣", style: TextStyle(fontSize: 12)),
            const SizedBox(height: 12),
            Expanded(
              child: systolic.isEmpty || diastolic.isEmpty
                  ? const Center(child: Text("No chart data available"))
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: buildBarChart(),
                    ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
