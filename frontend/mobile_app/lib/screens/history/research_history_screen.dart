import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../common/brand_color.dart';
import '../../common/common_widgets.dart';
import '../../l10n/app_strings.dart';
import '../../l10n/d_app_strings.dart' as d;
import '../../models/Disease_prediction_result_model.dart';
import '../../models/fertilizer_advice.dart';
import '../../models/grading_result.dart';
import '../../models/irrigation_history_record.dart';
import '../../services/disease/history_service.dart';
import '../../services/firebase/firestore_service.dart';
import '../../services/grading/grading_service.dart';
import '../../utils/format_datetime.dart';
import '../../widgets/app_bottom_nav_bar.dart';
import '../../widgets/grading/grading_history_tile.dart';
import '../../widgets/severity_chip.dart';
import '../disease/history_detail_view.dart';
import '../quality/history_detail_screen.dart';

class ResearchHistoryScreen extends StatefulWidget {
  const ResearchHistoryScreen({super.key});

  @override
  State<ResearchHistoryScreen> createState() => _ResearchHistoryScreenState();
}

class _ResearchHistoryScreenState extends State<ResearchHistoryScreen> {
  List<IrrigationHistoryRecord> _irrigation = [];
  List<FertilizerAdvice> _fertilizer = [];
  List<Map<String, dynamic>> _sensors = [];
  bool _loading = true;

  static const _darkRed = Color(0xFF8E0B16);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final irrigation = await FirestoreService.instance.getIrrigationHistory();
      final fertilizer = await FirestoreService.instance.getFertilizerHistory();
      final sensors = await FirestoreService.instance.getSensorHistory(
        limit: 80,
      );
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

  // ═══════════════════════════════════════════════════════════════════
  //  Disease / Grading data (loaded when the tab is opened)
  // ═══════════════════════════════════════════════════════════════════
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Future<List<PredictionResultModel>>? _diseaseF;
  Future<List<GradingResult>>? _gradingF;

  Future<List<PredictionResultModel>> get _diseaseFuture =>
      _diseaseF ??= HistoryService.getFirebaseHistory();

  Future<List<GradingResult>> get _gradingFuture => _gradingF ??= _uid == null
      ? Future.value(<GradingResult>[])
      : GradingService().getHistory(_uid!);

  Future<void> _reloadDisease() async {
    setState(() => _diseaseF = HistoryService.getFirebaseHistory());
    await _diseaseF;
  }

  Future<void> _reloadGrading() async {
    setState(() => _gradingF = null);
    await _gradingFuture;
  }

  // Labels not in app_strings.dart (3 languages)
  static const _txt = {
    AppLang.en: {
      'disease': 'Disease',
      'grading': 'Grading',
      'growth': 'Growth',
      'growthSoon': 'Growth stage history will appear here.',
    },
    AppLang.ta: {
      'disease': 'நோய்',
      'grading': 'தரம்',
      'growth': 'வளர்ச்சி',
      'growthSoon': 'வளர்ச்சி நிலை பதிவுகள் இங்கே காட்டப்படும்.',
    },
    AppLang.si: {
      'disease': 'රෝග',
      'grading': 'ශ්‍රේණිය',
      'growth': 'වර්ධනය',
      'growthSoon': 'වර්ධන අවධි ඉතිහාසය මෙහි පෙන්වනු ඇත.',
    },
  };

  String _rt(String key) =>
      _txt[LanguageController.instance.lang]?[key] ??
      _txt[AppLang.en]![key] ??
      key;

  // ═══════════════════════════════════════════════════════════════════
  //  UI
  // ═══════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LanguageController.instance,
      builder: (context, _) {
        return DefaultTabController(
          length: 6,
          child: Builder(
            builder: (context) {
              final tabCtrl = DefaultTabController.of(context);
              final tabs = [
                (Icons.star_rounded, _rt('grading')),
                (Icons.coronavirus_rounded, _rt('disease')),
                (Icons.eco_rounded, _rt('growth')),
                (Icons.science_rounded, t('fertilizer')),
                (Icons.water_drop_rounded, t('irrigation')),
                (Icons.sensors_rounded, t('sensorData')),
              ];
              return Scaffold(
                backgroundColor: BrandColor.background,
                bottomNavigationBar: const AppBottomNavBar(
                  current: AppNavTab.history,
                ),
                appBar: AppBar(
                  backgroundColor: Colors.white,
                  elevation: 0,
                  title: Text(
                    t('history'),
                    style: const TextStyle(
                      color: BrandColor.darkText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(46),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: AnimatedBuilder(
                        animation: tabCtrl,
                        builder: (context, _) => TabBar(
                          isScrollable: true,
                          tabAlignment: TabAlignment.start,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          dividerColor: Colors.transparent,
                          indicator:
                              const BoxDecoration(), // pills draw the selection
                          overlayColor: WidgetStateProperty.all(
                            Colors.transparent,
                          ),
                          labelPadding: const EdgeInsets.only(right: 8),
                          tabs: [
                            for (var i = 0; i < tabs.length; i++)
                              _tab(tabs[i].$1, tabs[i].$2, tabCtrl.index == i),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                body: TabBarView(
                  children: [
                    _gradingTab(),
                    _diseaseTab(),
                    _growthTab(),
                    _loading ? _loader() : _fertilizerTab(),
                    _loading ? _loader() : _irrigationTab(),
                    _loading ? _loader() : _sensorTab(),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// Pill tab — same size when selected (dark red fill) and not selected (outline).
  Widget _tab(IconData icon, String label, bool selected) => Tab(
    height: 32,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? _darkRed : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? _darkRed : _darkRed.withOpacity(0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: selected ? Colors.white : _darkRed),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : _darkRed,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _empty() => ListView(
    children: [
      const SizedBox(height: 110),
      Icon(Icons.history_rounded, size: 48, color: _darkRed.withOpacity(0.35)),
      const SizedBox(height: 10),
      Text(
        t('noRecords'),
        textAlign: TextAlign.center,
        style: const TextStyle(color: BrandColor.lightText, fontSize: 13.5),
      ),
    ],
  );

  Widget _loader() =>
      const Center(child: CircularProgressIndicator(color: _darkRed));

  // ── Grading (existing Quality Grading tile, detail page and full list) ──
  Widget _gradingTab() {
    return FutureBuilder<List<GradingResult>>(
      future: _gradingFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return _loader();
        final data = snap.data ?? [];
        if (data.isEmpty)
          return RefreshIndicator(onRefresh: _reloadGrading, child: _empty());
        return RefreshIndicator(
          color: _darkRed,
          onRefresh: _reloadGrading,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ...data.map(
                (r) => GradingHistoryTile(
                  result: r,
                  margin: const EdgeInsets.only(bottom: 12),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HistoryDetailScreen(result: r),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Disease (existing Disease detail page and full list) ────────────
  Widget _diseaseTab() {
    return FutureBuilder<List<PredictionResultModel>>(
      future: _diseaseFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return _loader();
        final data = snap.data ?? [];
        if (data.isEmpty)
          return RefreshIndicator(onRefresh: _reloadDisease, child: _empty());
        return RefreshIndicator(
          color: _darkRed,
          onRefresh: _reloadDisease,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [...data.map(_diseaseCard)],
          ),
        );
      },
    );
  }

  Widget _diseaseCard(PredictionResultModel item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HistoryDetailView(result: item),
              ),
            );
            if (mounted) _reloadDisease();
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: BrandColor.border),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _photo(item.imageUrl, item.imagePath),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d.LanguageController.instance.disease(item.diseaseName),
                        style: const TextStyle(
                          color: BrandColor.darkText,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          SeverityChip(result: item),
                          ConfidenceBadge(result: item),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _fmt(item.detectedAt),
                        style: const TextStyle(
                          color: BrandColor.lightText,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: BrandColor.lightText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _fmt(dynamic v) => v is DateTime ? formatFarmDateTime(v) : '';

  /// Network image → local file → icon placeholder.
  Widget _photo(String? url, String? path, {double size = 64}) {
    Widget placeholder() => Container(
      width: size,
      height: size,
      color: BrandColor.softPink,
      child: Icon(Icons.image_rounded, color: _darkRed, size: size * 0.4),
    );
    Widget local() =>
        (path != null && path.isNotEmpty && File(path).existsSync())
        ? Image.file(File(path), width: size, height: size, fit: BoxFit.cover)
        : placeholder();
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => local(),
      );
    }
    return local();
  }

  // ── Growth (page only — the Growth component owner will add the data) ──
  Widget _growthTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      children: [
        const SizedBox(height: 100),
        Container(
          width: 84,
          height: 84,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: BrandColor.softPink,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.eco_rounded, color: _darkRed, size: 38),
        ),
        const SizedBox(height: 16),
        Text(
          _rt('growth'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: BrandColor.darkText,
            fontWeight: FontWeight.w900,
            fontSize: 17,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _rt('growthSoon'),
          textAlign: TextAlign.center,
          style: const TextStyle(color: BrandColor.lightText, fontSize: 12.5),
        ),
      ],
    );
  }

  // ── Fertilizer / Irrigation / Sensor (original cards, unchanged) ────
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
          Text(
            t('decision'),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
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
            record.createdAt == null
                ? t('history')
                : formatFarmDate(record.createdAt!),
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            '${t('tree')}: ${record.treeId == null || record.treeId!.isEmpty ? 'POM-001' : record.treeId}',
          ),
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
