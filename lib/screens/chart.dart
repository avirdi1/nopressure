import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    final prefs = await SharedPreferences.getInstance();
    final savedLogs = prefs.getString('logsByDate') ?? '{}';
    final decoded = json.decode(savedLogs) as Map<String, dynamic>;

    final logs = Map<String, List<String>>.from(
      decoded.map((k, v) => MapEntry(k, List<String>.from(v))),
    );

    final now = DateTime.now();
    final formatter = DateFormat('MMMM d, yyyy');
    final labelFormat = DateFormat('EEE');

    List<String> past7 = List.generate(7, (i) {
      return formatter.format(now.subtract(Duration(days: 6 - i)));
    });

    List<double> sysAvg = [];
    List<double> diaAvg = [];
    List<String> xLabels = [];

    for (var dateStr in past7) {
      final dayLabel = labelFormat.format(formatter.parse(dateStr));
      final entries = logs[dateStr];
      if (entries != null && entries.isNotEmpty) {
        List<int> sys = [];
        List<int> dia = [];

        for (var entry in entries) {
          try {
            final bp = entry.split(' - ').last.split(' ')[0];
            final parts = bp.split('/');
            sys.add(int.parse(parts[0]));
            dia.add(int.parse(parts[1]));
          } catch (_) {}
        }

        sysAvg.add(sys.reduce((a, b) => a + b) / sys.length);
        diaAvg.add(dia.reduce((a, b) => a + b) / dia.length);
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
      backgroundColor: Colors.orange[100],
      body: SafeArea(
        child: Column(
          children: [
            buildPageHeader("Chart"),
            const SizedBox(height: 10),
            buildLegend(),
            const Text("Color zones: High 🔴  Pre-High 🟡  Ideal 🟢  Low 🟣", style: TextStyle(fontSize: 12)),
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
