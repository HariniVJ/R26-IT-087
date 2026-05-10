import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../common/brand_color.dart';
import '../../models/prediction_result_model.dart';
import '../../services/history_service.dart';

class MonthlyReportView extends StatefulWidget {
  const MonthlyReportView({super.key});

  @override
  State<MonthlyReportView> createState() => _MonthlyReportViewState();
}

class _MonthlyReportViewState extends State<MonthlyReportView> {
  late Future<List<PredictionResultModel>> historyFuture;

  @override
  void initState() {
    super.initState();
    historyFuture = HistoryService.getFirebaseHistory();
  }

  String _monthName(int month) {
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month];
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: BrandColor.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: BrandColor.primary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Monthly Report',
          style: TextStyle(
            color: BrandColor.darkText,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: FutureBuilder<List<PredictionResultModel>>(
        future: historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: BrandColor.primary),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Error: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: BrandColor.primary),
                ),
              ),
            );
          }

          final allHistory = snapshot.data ?? [];
          final monthlyHistory = allHistory.where((item) {
            return item.detectedAt.month == now.month &&
                item.detectedAt.year == now.year;
          }).toList();

          final healthyCount = monthlyHistory
              .where((e) => e.diseaseName.toLowerCase() == 'healthy')
              .length;
          final diseasedCount = monthlyHistory.length - healthyCount;
          final uniqueDates = monthlyHistory
              .map((item) {
                final d = item.detectedAt;
                return '${d.day.toString().padLeft(2, '0')}/'
                    '${d.month.toString().padLeft(2, '0')}';
              })
              .toSet()
              .length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Month header card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: BrandColor.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.bar_chart_rounded,
                          color: BrandColor.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_monthName(now.month)} ${now.year}',
                              style: const TextStyle(
                                color: BrandColor.darkText,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Disease vs date monthly summary',
                              style: TextStyle(
                                color: BrandColor.lightText,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Summary cards
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        title: 'Total Scans',
                        value: monthlyHistory.length.toString(),
                        icon: Icons.document_scanner_rounded,
                        color: BrandColor.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        title: 'Healthy',
                        value: healthyCount.toString(),
                        icon: Icons.check_circle_rounded,
                        color: BrandColor.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        title: 'Diseased',
                        value: diseasedCount.toString(),
                        icon: Icons.coronavirus_rounded,
                        color: BrandColor.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        title: 'Dates',
                        value: uniqueDates.toString(),
                        icon: Icons.calendar_month_rounded,
                        color: const Color(0xFF7C3AED),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                const Text(
                  'Disease vs Date Chart',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: BrandColor.darkText,
                  ),
                ),
                const SizedBox(height: 14),

                if (monthlyHistory.isEmpty)
                  const _EmptyReport()
                else
                  _DiseaseVsDateChart(history: monthlyHistory),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DiseaseVsDateChart extends StatelessWidget {
  final List<PredictionResultModel> history;

  const _DiseaseVsDateChart({required this.history});

  @override
  Widget build(BuildContext context) {
    final dates = history
        .map((e) {
          final d = e.detectedAt;
          return '${d.day.toString().padLeft(2, '0')}/'
              '${d.month.toString().padLeft(2, '0')}';
        })
        .toSet()
        .toList();

    final diseases = history
        .map((e) => e.diseaseName.replaceAll('_', ' '))
        .toSet()
        .toList();

    int maxCount = 0;
    for (final date in dates) {
      for (final disease in diseases) {
        final count = history.where((item) {
          final d = item.detectedAt;
          final itemDate =
              '${d.day.toString().padLeft(2, '0')}/'
              '${d.month.toString().padLeft(2, '0')}';
          return itemDate == date &&
              item.diseaseName.replaceAll('_', ' ') == disease;
        }).length;
        if (count > maxCount) maxCount = count;
      }
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 20, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 300,
            child: BarChart(
              BarChartData(
                maxY: (maxCount + 2).toDouble(),
                alignment: BarChartAlignment.spaceAround,
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.withOpacity(0.12),
                    strokeWidth: 1,
                  ),
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
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: TextStyle(
                          color: BrandColor.softText,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= dates.length) {
                          return const SizedBox();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            dates[index],
                            style: TextStyle(
                              color: BrandColor.lightText,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(dates.length, (dateIndex) {
                  final date = dates[dateIndex];
                  return BarChartGroupData(
                    x: dateIndex,
                    barsSpace: 3,
                    barRods: List.generate(diseases.length, (diseaseIndex) {
                      final disease = diseases[diseaseIndex];
                      final count = history.where((item) {
                        final d = item.detectedAt;
                        final itemDate =
                            '${d.day.toString().padLeft(2, '0')}/'
                            '${d.month.toString().padLeft(2, '0')}';
                        return itemDate == date &&
                            item.diseaseName.replaceAll('_', ' ') == disease;
                      }).length;
                      return BarChartRodData(
                        toY: count.toDouble(),
                        width: 8,
                        borderRadius: BorderRadius.circular(4),
                        color: _barColor(diseaseIndex),
                      );
                    }),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: List.generate(diseases.length, (index) {
              return _LegendItem(
                label: diseases[index],
                color: _barColor(index),
              );
            }),
          ),
        ],
      ),
    );
  }

  Color _barColor(int index) {
    final colors = [
      BrandColor.primary,
      BrandColor.green,
      const Color(0xFFFF7043),
      const Color(0xFF7C3AED),
      Colors.orange,
      Colors.blue,
    ];
    return colors[index % colors.length];
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendItem({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: BrandColor.lightText,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(color: BrandColor.lightText, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _EmptyReport extends StatelessWidget {
  const _EmptyReport();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Center(
        child: Text(
          'No records found for this month',
          style: TextStyle(color: BrandColor.lightText, fontSize: 14),
        ),
      ),
    );
  }
}
