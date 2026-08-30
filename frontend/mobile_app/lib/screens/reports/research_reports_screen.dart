import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../common/brand_color.dart';
import '../../common/common_widgets.dart';
import '../../l10n/app_strings.dart';
import '../../models/fertilizer_advice.dart';
import '../../models/irrigation_history_record.dart';
import '../../services/firebase/firestore_service.dart';
import '../../widgets/app_bottom_nav_bar.dart';

enum _ReportRange { today, last7, last30, custom }

class ResearchReportsScreen extends StatefulWidget {
  const ResearchReportsScreen({super.key});

  @override
  State<ResearchReportsScreen> createState() => _ResearchReportsScreenState();
}

class _ResearchReportsScreenState extends State<ResearchReportsScreen> {
  _ReportRange _range = _ReportRange.last7;
  DateTimeRange? _custom;
  List<IrrigationHistoryRecord> _irrigation = [];
  List<FertilizerAdvice> _fertilizer = [];
  List<Map<String, dynamic>> _logs = [];
  Map<String, dynamic>? _latestSoil;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  DateTimeRange get _bounds {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    switch (_range) {
      case _ReportRange.today:
        return DateTimeRange(start: DateTime(now.year, now.month, now.day), end: end);
      case _ReportRange.last7:
        return DateTimeRange(start: end.subtract(const Duration(days: 6)), end: end);
      case _ReportRange.last30:
        return DateTimeRange(start: end.subtract(const Duration(days: 29)), end: end);
      case _ReportRange.custom:
        return _custom ??
            DateTimeRange(start: end.subtract(const Duration(days: 6)), end: end);
    }
  }

  bool _inRange(DateTime time) {
    final bounds = _bounds;
    return !time.isBefore(bounds.start) && !time.isAfter(bounds.end);
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final irrigation = await FirestoreService.instance.getIrrigationHistory();
      final fertilizer = await FirestoreService.instance.getFertilizerHistory();
      final logs = await FirestoreService.instance.getIrrigationLogs();
      final sensors = await FirestoreService.instance.getSensorHistory(limit: 1);
      if (!mounted) return;
      setState(() {
        _irrigation = irrigation;
        _fertilizer = fertilizer;
        _logs = logs;
        _latestSoil = sensors.isEmpty ? null : sensors.first;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _pickCustom() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: _bounds,
    );
    if (picked == null) return;
    setState(() {
      _range = _ReportRange.custom;
      _custom = picked;
    });
  }

  @override
  Widget build(BuildContext context) {
    final irrigation = _irrigation.where((r) => _inRange(r.createdAt)).toList();
    final fertilizer = _fertilizer
        .where((r) => r.createdAt != null && _inRange(r.createdAt!))
        .toList();
    final logs = _logs.where((row) {
      final started = row['startedAt'];
      DateTime time;
      if (started is DateTime) {
        time = started;
      } else {
        try {
          time = (started as dynamic).toDate() as DateTime;
        } catch (_) {
          time = DateTime.fromMillisecondsSinceEpoch(0);
        }
      }
      return _inRange(time);
    }).toList();

    return ListenableBuilder(
      listenable: LanguageController.instance,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: BrandColor.background,
          bottomNavigationBar: const AppBottomNavBar(current: AppNavTab.reports),
          appBar: AppBar(title: Text(t('reports'))),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _rangeChips(),
                      const SizedBox(height: 16),
                      _currentSoilCard(),
                      const SizedBox(height: 16),
                      _irrigationReport(irrigation, logs),
                      const SizedBox(height: 16),
                      _fertilizerReport(fertilizer),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _rangeChips() {
    Widget chip(_ReportRange value, String label) {
      final selected = _range == value;
      return ChoiceChip(
        label: Text(label),
        selected: selected,
        selectedColor: BrandColor.primary.withOpacity(0.15),
        labelStyle: TextStyle(
          color: selected ? BrandColor.primary : Colors.black87,
          fontWeight: FontWeight.w700,
        ),
        onSelected: (_) {
          if (value == _ReportRange.custom) {
            _pickCustom();
            return;
          }
          setState(() => _range = value);
        },
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        chip(_ReportRange.today, t('today')),
        chip(_ReportRange.last7, t('last7')),
        chip(_ReportRange.last30, t('last30')),
        chip(_ReportRange.custom, t('customRange')),
      ],
    );
  }

  Widget _stat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _currentSoilCard() {
    final soil = _latestSoil;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t('currentSoil'),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 10),
          if (soil == null)
            Text(t('noRecords'))
          else ...[
            _stat(t('soilMoisture'), '${soil['soilMoisture'] ?? '--'}%'),
            _stat(t('soilTemperature'), '${soil['soilTemperature'] ?? '--'} °C'),
            _stat(t('nitrogen'), '${soil['nitrogen'] ?? '--'}'),
            _stat(t('phosphorus'), '${soil['phosphorus'] ?? '--'}'),
            _stat(t('potassium'), '${soil['potassium'] ?? '--'}'),
            _stat(t('soilPh'), '${soil['soilPh'] ?? '--'}'),
          ],
        ],
      ),
    );
  }

  Widget _irrigationReport(
    List<IrrigationHistoryRecord> records,
    List<Map<String, dynamic>> logs,
  ) {
    final moistures = records.map((r) => r.soilMoisture).toList();
    final avg = moistures.isEmpty
        ? 0.0
        : moistures.reduce((a, b) => a + b) / moistures.length;
    final min = moistures.isEmpty ? 0.0 : moistures.reduce((a, b) => a < b ? a : b);
    final max = moistures.isEmpty ? 0.0 : moistures.reduce((a, b) => a > b ? a : b);
    final skippedRain = records.where((r) => r.finalPrediction == 'SKIP_RAIN_EXPECTED').length;
    final skippedWet = records.where((r) => r.finalPrediction == 'SKIP_SOIL_ALREADY_WET').length;
    final confidences = records
        .where((r) => r.modelConfidence != null)
        .map((r) => r.modelConfidence! <= 1 ? r.modelConfidence! * 100 : r.modelConfidence!)
        .toList();
    final avgConf = confidences.isEmpty
        ? 0.0
        : confidences.reduce((a, b) => a + b) / confidences.length;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t('irrigationReport'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 10),
          if (records.isEmpty)
            Text(t('noDataForRange'))
          else ...[
            _stat(t('avgMoisture'), '${avg.toStringAsFixed(1)}%'),
            _stat(t('minMoisture'), '${min.toStringAsFixed(1)}%'),
            _stat(t('maxMoisture'), '${max.toStringAsFixed(1)}%'),
            _stat(t('irrigationRecommendations'), '${records.length}'),
            _stat(t('irrigationEvents'), '${logs.length}'),
            _stat(t('skippedRain'), '$skippedRain'),
            _stat(t('skippedWet'), '$skippedWet'),
            _stat(t('avgConfidence'), '${avgConf.toStringAsFixed(0)}%'),
            const SizedBox(height: 16),
            _sectionTitle(t('moistureVsTime')),
            _lineChart(
              records.reversed
                  .toList()
                  .asMap()
                  .entries
                  .map((e) => FlSpot(e.key.toDouble(), e.value.soilMoisture))
                  .toList(),
              BrandColor.primary,
            ),
            const SizedBox(height: 16),
            _sectionTitle(t('rainfallVsIrrigation')),
            _lineChart(
              records.reversed.toList().asMap().entries.map((e) {
                final rain = e.value.forecastRain24h ?? 0;
                return FlSpot(e.key.toDouble(), rain);
              }).toList(),
              Colors.blue,
            ),
            const SizedBox(height: 16),
            _sectionTitle(t('dailyDecisions')),
            _decisionBars(records),
          ],
        ],
      ),
    );
  }

  Widget _fertilizerReport(List<FertilizerAdvice> records) {
    double avg(double Function(FertilizerAdvice r) read) {
      if (records.isEmpty) return 0;
      return records.map(read).reduce((a, b) => a + b) / records.length;
    }

    final low = records.where((r) => r.fertilizerClass.toUpperCase() == 'LOW').length;
    final medium = records.where((r) => r.fertilizerClass.toUpperCase() == 'MEDIUM').length;
    final high = records.where((r) => r.fertilizerClass.toUpperCase() == 'HIGH').length;
    final urea = records.fold<double>(0, (sum, r) => sum + r.ureaG);
    final tsp = records.fold<double>(0, (sum, r) => sum + r.tspG);
    final mop = records.fold<double>(0, (sum, r) => sum + r.mopG);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t('fertilizerReport'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 10),
          if (records.isEmpty)
            Text(t('noDataForRange'))
          else ...[
            _stat(t('avgN'), avg((r) => r.nitrogen).toStringAsFixed(1)),
            _stat(t('avgP'), avg((r) => r.phosphorus).toStringAsFixed(1)),
            _stat(t('avgK'), avg((r) => r.potassium).toStringAsFixed(1)),
            _stat(t('avgPh'), avg((r) => r.ph ?? 0).toStringAsFixed(2)),
            _stat(t('lowCount'), '$low'),
            _stat(t('mediumCount'), '$medium'),
            _stat(t('highCount'), '$high'),
            _stat(t('totalUrea'), '${urea.toStringAsFixed(0)} g'),
            _stat(t('totalTsp'), '${tsp.toStringAsFixed(0)} g'),
            _stat(t('totalMop'), '${mop.toStringAsFixed(0)} g'),
            const SizedBox(height: 16),
            _sectionTitle(t('npkOverTime')),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  titlesData: const FlTitlesData(
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: records.reversed
                          .toList()
                          .asMap()
                          .entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value.nitrogen))
                          .toList(),
                      color: const Color(0xFF1296F3),
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                    ),
                    LineChartBarData(
                      spots: records.reversed
                          .toList()
                          .asMap()
                          .entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value.phosphorus))
                          .toList(),
                      color: const Color(0xFFFF5722),
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                    ),
                    LineChartBarData(
                      spots: records.reversed
                          .toList()
                          .asMap()
                          .entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value.potassium))
                          .toList(),
                      color: const Color(0xFFB71FD1),
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _sectionTitle(t('fertilizerDistribution')),
            _pie([
              MapEntry('LOW', low),
              MapEntry('MEDIUM', medium),
              MapEntry('HIGH', high),
            ]),
            const SizedBox(height: 16),
            _sectionTitle(t('phOverTime')),
            _lineChart(
              records.reversed
                  .toList()
                  .asMap()
                  .entries
                  .map((e) => FlSpot(e.key.toDouble(), e.value.ph ?? 0))
                  .toList(),
              Colors.teal,
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800)),
    );
  }

  Widget _lineChart(List<FlSpot> spots, Color color) {
    if (spots.isEmpty) return Text(t('noRecords'));
    return SizedBox(
      height: 170,
      child: LineChart(
        LineChartData(
          titlesData: const FlTitlesData(
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              barWidth: 3,
              dotData: const FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _decisionBars(List<IrrigationHistoryRecord> records) {
    final irrigate = records.where((r) =>
        r.finalPrediction == 'SUITABLE_TO_IRRIGATE' ||
        r.finalPrediction == 'SUITABLE_BASED_ON_SOIL').length;
    final rain = records.where((r) => r.finalPrediction == 'SKIP_RAIN_EXPECTED').length;
    final wet = records.where((r) => r.finalPrediction == 'SKIP_SOIL_ALREADY_WET').length;
    final none = records.length - irrigate - rain - wet;
    final values = [irrigate, rain, wet, none < 0 ? 0 : none];
    final colors = [Colors.green, Colors.orange, Colors.blueGrey, Colors.grey];
    return SizedBox(
      height: 160,
      child: BarChart(
        BarChartData(
          titlesData: const FlTitlesData(
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
          barGroups: List.generate(
            values.length,
            (i) => BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: values[i].toDouble(),
                  color: colors[i],
                  width: 18,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pie(List<MapEntry<String, int>> slices) {
    final total = slices.fold<int>(0, (sum, e) => sum + e.value);
    if (total == 0) return Text(t('noRecords'));
    final colors = [Colors.green, Colors.orange, BrandColor.primary];
    return SizedBox(
      height: 180,
      child: PieChart(
        PieChartData(
          sections: [
            for (var i = 0; i < slices.length; i++)
              PieChartSectionData(
                value: slices[i].value.toDouble(),
                title: '${slices[i].key}\n${slices[i].value}',
                color: colors[i % colors.length],
                radius: 58,
                titleStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
