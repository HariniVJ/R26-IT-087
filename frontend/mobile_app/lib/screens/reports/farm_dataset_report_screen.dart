// lib/screens/reports/farm_dataset_report_screen.dart
//
// FARM DATASET REPORT (new page — the old ResearchReportsScreen is not
// used or changed).
//
//   📍 Farm location name (from the irrigation GPS)
//   🗂️ Date tabs: All · Last 7 Days · Last 30 Days
//   📊 Bar chart: how many tests in each component
//      Disease 45 images · Grading 56 images · Growth … · Irrigation … ·
//      Fertilizer …
//   📋 Dataset table: count + last test date per component
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../common/brand_color.dart';
import '../../l10n/app_strings.dart';
import '../../services/reports/farm_dataset_report_service.dart';
import '../../widgets/app_bottom_nav_bar.dart';

enum _Range { all, last7, last30 }

class FarmDatasetReportScreen extends StatefulWidget {
  const FarmDatasetReportScreen({super.key});

  @override
  State<FarmDatasetReportScreen> createState() =>
      _FarmDatasetReportScreenState();
}

class _FarmDatasetReportScreenState extends State<FarmDatasetReportScreen> {
  final _service = FarmDatasetReportService.instance;

  FarmDatasetReport? _report;
  bool _loading = true;
  _Range _range = _Range.all;

  static const _textDark = Color(0xFF1F2937);
  static const _textMid = Color(0xFF6B7280);
  static const _border = Color(0xFFEDEDF0);

  static const _colors = {
    FarmComponent.disease: Color(0xFFC1121F),
    FarmComponent.grading: Color(0xFF7C3AED),
    FarmComponent.growth: Color(0xFF16A34A),
    FarmComponent.irrigation: Color(0xFF2563EB),
    FarmComponent.fertilizer: Color(0xFFD97706),
  };
  static const _icons = {
    FarmComponent.disease: Icons.coronavirus_rounded,
    FarmComponent.grading: Icons.star_rounded,
    FarmComponent.growth: Icons.eco_rounded,
    FarmComponent.irrigation: Icons.water_drop_rounded,
    FarmComponent.fertilizer: Icons.science_rounded,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _report = await _service.load();
    } catch (e) {
      debugPrint('Farm dataset report failed: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  // ── date filter ──
  bool _inRange(DateTime t) {
    if (_range == _Range.all) return true;
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final days = _range == _Range.last7 ? 6 : 29;
    final start = DateTime(
      end.year,
      end.month,
      end.day,
    ).subtract(Duration(days: days));
    return !t.isBefore(start) && !t.isAfter(end);
  }

  void _setRange(_Range r) {
    if (_range == r) return;
    setState(() => _range = r);
  }

  Map<FarmComponent, int> get _counts {
    final m = {for (final c in FarmComponent.values) c: 0};
    for (final t in _report?.tests ?? const <FarmTest>[]) {
      if (_inRange(t.time)) m[t.component] = m[t.component]! + 1;
    }
    return m;
  }

  Map<FarmComponent, DateTime?> get _lastDates {
    final m = <FarmComponent, DateTime?>{
      for (final c in FarmComponent.values) c: null,
    };
    for (final t in _report?.tests ?? const <FarmTest>[]) {
      if (!_inRange(t.time) || t.time.year < 2000) continue;
      final cur = m[t.component];
      if (cur == null || t.time.isAfter(cur)) m[t.component] = t.time;
    }
    return m;
  }

  // ═══════════════════════════════════════════════════════════════════
  //  UI
  // ═══════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LanguageController.instance,
      builder: (context, _) => Scaffold(
        backgroundColor: BrandColor.background,
        bottomNavigationBar: const AppBottomNavBar(current: AppNavTab.reports),
        appBar: AppBar(title: Text(_rt('title'))),
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(color: BrandColor.primary),
              )
            : RefreshIndicator(
                color: BrandColor.primary,
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  children: _report == null
                      ? [_messageCard(Icons.lock_outline, t('notLoggedIn'))]
                      : [
                          _locationCard(_report!.farm),
                          const SizedBox(height: 14),
                          _rangeTabs(),
                          const SizedBox(height: 14),
                          _chartCard(),
                          const SizedBox(height: 12),
                          _datasetTable(),
                        ],
                ),
              ),
      ),
    );
  }

  // ── 📍 Farm location ──
  Widget _locationCard(FarmInfo farm) {
    final hasName = farm.locationName.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: BrandColor.primary,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (farm.farmName.isNotEmpty)
                  Text(
                    farm.farmName,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                Text(
                  hasName ? farm.locationName : _rt('noLocation'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  farm.hasGps
                      ? '${farm.latitude!.toStringAsFixed(4)}, '
                            '${farm.longitude!.toStringAsFixed(4)}'
                      : _rt('noLocationHint'),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 🗂️ Segmented tabs: All · Last 7 Days · Last 30 Days ──
  Widget _rangeTabs() {
    Widget tab(_Range v, String label) {
      final selected = _range == v;
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _setRange(v),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            height: 40,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: selected ? BrandColor.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: BrandColor.primary.withOpacity(0.28),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              style: TextStyle(
                color: selected ? Colors.white : _textMid,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          tab(_Range.all, t('all')),
          const SizedBox(width: 4),
          tab(_Range.last7, t('last7')),
          const SizedBox(width: 4),
          tab(_Range.last30, t('last30')),
        ],
      ),
    );
  }

  // ── 📊 Bar chart: tests per component ──
  Widget _chartCard() {
    final counts = _counts;
    final total = counts.values.fold(0, (a, b) => a + b);
    final maxCount = counts.values.fold(0, (a, b) => a > b ? a : b);
    final maxY = maxCount == 0 ? 5.0 : (maxCount * 1.25).ceilToDouble();

    return Container(
      decoration: _card(),
      padding: const EdgeInsets.fromLTRB(12, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _rt('testsPerComponent'),
                    style: const TextStyle(
                      color: _textDark,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '${_rt('total')}: $total',
                  style: const TextStyle(
                    color: BrandColor.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 230,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                minY: 0,
                alignment: BarChartAlignment.spaceAround,
                barTouchData: BarTouchData(enabled: false),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: _border, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        if (value != value.roundToDouble()) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(color: _textMid, fontSize: 10),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      getTitlesWidget: (value, meta) {
                        final c = FarmComponent.values[value.toInt()];
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_icons[c], size: 16, color: _colors[c]),
                              const SizedBox(height: 2),
                              Text(
                                '${counts[c]}',
                                style: TextStyle(
                                  color: _colors[c],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < FarmComponent.values.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: counts[FarmComponent.values[i]]!.toDouble(),
                          color: _colors[FarmComponent.values[i]],
                          width: 24,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          if (total == 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(
                child: Text(
                  _range == _Range.all ? t('noRecords') : t('noDataForRange'),
                  style: const TextStyle(color: _textMid, fontSize: 12.5),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── 📋 Dataset table ──
  Widget _datasetTable() {
    final counts = _counts;
    final last = _lastDates;
    return Container(
      decoration: _card(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _rt('dataset'),
            style: const TextStyle(
              color: _textDark,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          for (final c in FarmComponent.values)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _colors[c]!.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(_icons[c], color: _colors[c], size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _name(c),
                          style: const TextStyle(
                            color: _textDark,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          last[c] == null
                              ? _rt('noTests')
                              : '${_rt('lastTest')}: ${_date(last[c]!)}',
                          style: const TextStyle(color: _textMid, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${counts[c]} ${_unit(c)}',
                    style: TextStyle(
                      color: _colors[c],
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _messageCard(IconData icon, String text) => Container(
    decoration: _card(),
    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
    child: Column(
      children: [
        Icon(icon, size: 40, color: BrandColor.primary.withOpacity(0.5)),
        const SizedBox(height: 10),
        Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: _textMid, fontSize: 13),
        ),
      ],
    ),
  );

  BoxDecoration _card() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: _border),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );

  String _date(DateTime d) => '${d.day}/${d.month}/${d.year}';

  String _name(FarmComponent c) {
    switch (c) {
      case FarmComponent.disease:
        return _rt('disease');
      case FarmComponent.grading:
        return _rt('grading');
      case FarmComponent.growth:
        return _rt('growth');
      case FarmComponent.irrigation:
        return t('irrigation');
      case FarmComponent.fertilizer:
        return t('fertilizer');
    }
  }

  /// Image components count images, the others count checks.
  String _unit(FarmComponent c) {
    switch (c) {
      case FarmComponent.disease:
      case FarmComponent.grading:
      case FarmComponent.growth:
        return _rt('images');
      case FarmComponent.irrigation:
      case FarmComponent.fertilizer:
        return _rt('checks');
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  //  TEXT (3 languages) — only words not already in app_strings.dart
  // ═══════════════════════════════════════════════════════════════════
  static const _text = {
    AppLang.en: {
      'title': 'Farm Report',
      'noLocation': 'Location not available',
      'noLocationHint': 'Run an irrigation check once to save the farm GPS.',
      'testsPerComponent': 'Tests per component',
      'total': 'Total',
      'dataset': 'Dataset summary',
      'disease': 'Disease detection',
      'grading': 'Quality grading',
      'growth': 'Growth stage',
      'images': 'images',
      'checks': 'checks',
      'lastTest': 'Last test',
      'noTests': 'No tests yet',
    },
    AppLang.ta: {
      'title': 'பண்ணை அறிக்கை',
      'noLocation': 'இடம் கிடைக்கவில்லை',
      'noLocationHint':
          'பண்ணையின் GPS-ஐ சேமிக்க ஒருமுறை நீர்ப்பாசன சோதனை செய்யவும்.',
      'testsPerComponent': 'ஒவ்வொரு பகுதியின் சோதனைகள்',
      'total': 'மொத்தம்',
      'dataset': 'தரவுத் தொகுப்பு சுருக்கம்',
      'disease': 'நோய் கண்டறிதல்',
      'grading': 'தர மதிப்பீடு',
      'growth': 'வளர்ச்சி நிலை',
      'images': 'படங்கள்',
      'checks': 'சோதனைகள்',
      'lastTest': 'கடைசி சோதனை',
      'noTests': 'இன்னும் சோதனைகள் இல்லை',
    },
    AppLang.si: {
      'title': 'ගොවිපල වාර්තාව',
      'noLocation': 'ස්ථානය ලබා ගත නොහැක',
      'noLocationHint':
          'ගොවිපල GPS සුරැකීමට එක් වරක් ජල සම්පාදන පරීක්ෂාවක් කරන්න.',
      'testsPerComponent': 'එක් එක් කොටසේ පරීක්ෂණ',
      'total': 'මුළු',
      'dataset': 'දත්ත කට්ටල සාරාංශය',
      'disease': 'රෝග හඳුනාගැනීම',
      'grading': 'ගුණාත්මක ශ්‍රේණිගත කිරීම',
      'growth': 'වර්ධන අවධිය',
      'images': 'රූප',
      'checks': 'පරීක්ෂණ',
      'lastTest': 'අවසන් පරීක්ෂණය',
      'noTests': 'තවම පරීක්ෂණ නැත',
    },
  };

  String _rt(String key) =>
      _text[LanguageController.instance.lang]?[key] ??
      _text[AppLang.en]![key] ??
      key;
}
