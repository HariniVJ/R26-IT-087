import 'package:flutter/material.dart';

import '../../common/brand_color.dart';
import '../../common/common_widgets.dart';
import '../../l10n/app_strings.dart';
import '../../models/fertilizer_advice.dart';
import '../../models/irrigation_history_record.dart';
import '../../services/firebase/firestore_service.dart';
import '../../utils/format_datetime.dart';
import '../../widgets/app_bottom_nav_bar.dart';

class ResearchHistoryScreen extends StatefulWidget {
  const ResearchHistoryScreen({super.key});

  @override
  State<ResearchHistoryScreen> createState() => _ResearchHistoryScreenState();
}

class _ResearchHistoryScreenState extends State<ResearchHistoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  List<IrrigationHistoryRecord> _irrigation = [];
  List<FertilizerAdvice> _fertilizer = [];
  List<Map<String, dynamic>> _sensors = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final irrigation = await FirestoreService.instance.getIrrigationHistory();
      final fertilizer = await FirestoreService.instance.getFertilizerHistory();
      final sensors = await FirestoreService.instance.getSensorHistory(limit: 80);
      if (!mounted) return;
      setState(() {
        _irrigation = irrigation;
        _fertilizer = fertilizer;
        _sensors = sensors;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  DateTime _sensorTime(Map<String, dynamic> row) {
    final value = row['timestamp'];
    if (value is DateTime) return value;
    try {
      return (value as dynamic).toDate() as DateTime;
    } catch (_) {
      return DateTime.tryParse('$value') ?? DateTime.now();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LanguageController.instance,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: BrandColor.background,
          bottomNavigationBar: const AppBottomNavBar(current: AppNavTab.history),
          appBar: AppBar(
            title: Text(t('history')),
            bottom: TabBar(
              controller: _tabs,
              isScrollable: true,
              labelColor: BrandColor.primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: BrandColor.primary,
              tabs: [
                Tab(text: t('all')),
                Tab(text: t('irrigation')),
                Tab(text: t('fertilizer')),
                Tab(text: t('sensorData')),
              ],
            ),
          ),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabs,
                  children: [
                    _allTab(),
                    _irrigationTab(),
                    _fertilizerTab(),
                    _sensorTab(),
                  ],
                ),
        );
      },
    );
  }

  Widget _empty() => Center(child: Text(t('noRecords')));

  Widget _allTab() {
    final items = <_HistoryItem>[
      ..._irrigation.map((r) => _HistoryItem(r.createdAt, 'irrigation', r)),
      ..._fertilizer.map(
        (r) => _HistoryItem(r.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0), 'fertilizer', r),
      ),
      ..._sensors.map((r) => _HistoryItem(_sensorTime(r), 'sensor', r)),
    ]..sort((a, b) => b.time.compareTo(a.time));

    if (items.isEmpty) return _empty();
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = items[index];
          if (item.kind == 'irrigation') {
            return _irrigationCard(item.value as IrrigationHistoryRecord);
          }
          if (item.kind == 'fertilizer') {
            return _fertilizerCard(item.value as FertilizerAdvice);
          }
          return _sensorCard(item.value as Map<String, dynamic>);
        },
      ),
    );
  }

  Widget _irrigationTab() {
    if (_irrigation.isEmpty) return _empty();
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _irrigation.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _irrigationCard(_irrigation[i]),
      ),
    );
  }

  Widget _fertilizerTab() {
    if (_fertilizer.isEmpty) return _empty();
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _fertilizer.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _fertilizerCard(_fertilizer[i]),
      ),
    );
  }

  Widget _sensorTab() {
    if (_sensors.isEmpty) return _empty();
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _sensors.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _sensorCard(_sensors[i]),
      ),
    );
  }

  Widget _irrigationCard(IrrigationHistoryRecord record) {
    final rainLine = record.rainExpectedInHours == null
        ? t('noRainExpected')
        : t('rainAlertBody').replaceAll(
            '{hours}',
            '${record.rainExpectedInHours! < 1 ? 1 : record.rainExpectedInHours}',
          );
    final confidence = record.modelConfidence == null
        ? '--'
        : '${((record.modelConfidence! <= 1 ? record.modelConfidence! * 100 : record.modelConfidence!)).round()}%';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formatFarmDateTime(record.createdAt),
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            '${t('soilMoisture')}: ${record.soilMoisture.toStringAsFixed(0)}%',
          ),
          Text('${t('rainForecast')}: $rainLine'),
          const SizedBox(height: 8),
          Text(t('decision'), style: const TextStyle(fontWeight: FontWeight.w800)),
          Text(
            irrigationDecisionLabel(record.finalPrediction, record.status),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text('${t('confidence')}: $confidence'),
          Text('${t('pumpStatus')}: ${record.pumpStatus ?? t('pumpOff')}'),
        ],
      ),
    );
  }

  Widget _fertilizerCard(FertilizerAdvice record) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            record.createdAt == null ? t('history') : formatFarmDate(record.createdAt!),
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text('${t('tree')}: ${record.treeId == null || record.treeId!.isEmpty ? 'POM-001' : record.treeId}'),
          Text('N: ${record.nitrogen.toStringAsFixed(0)}'),
          Text('P: ${record.phosphorus.toStringAsFixed(0)}'),
          Text('K: ${record.potassium.toStringAsFixed(0)}'),
          Text('${t('soilPh')}: ${record.ph?.toStringAsFixed(1) ?? '--'}'),
          Text('${t('treeAge')}: ${record.treeAge}'),
          const SizedBox(height: 8),
          Text(
            '${t('recommendedFertilizer')}: ${record.fertilizerClass}',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          Text('${t('urea')}: ${record.ureaG} g'),
          Text('${t('tsp')}: ${record.tspG} g'),
          Text('${t('mop')}: ${record.mopG} g'),
        ],
      ),
    );
  }

  Widget _sensorCard(Map<String, dynamic> row) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formatFarmDateTime(_sensorTime(row)),
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text('${t('soilMoisture')}: ${row['soilMoisture'] ?? '--'}%'),
          Text('${t('soilTemperature')}: ${row['soilTemperature'] ?? '--'} °C'),
          Text('${t('nitrogen')}: ${row['nitrogen'] ?? '--'}'),
          Text('${t('phosphorus')}: ${row['phosphorus'] ?? '--'}'),
          Text('${t('potassium')}: ${row['potassium'] ?? '--'}'),
          Text('${t('soilPh')}: ${row['soilPh'] ?? '--'}'),
        ],
      ),
    );
  }
}

class _HistoryItem {
  final DateTime time;
  final String kind;
  final Object value;

  _HistoryItem(this.time, this.kind, this.value);
}
