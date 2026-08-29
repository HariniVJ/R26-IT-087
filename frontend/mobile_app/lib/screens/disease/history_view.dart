import 'package:flutter/material.dart';


import '../../common/brand_color.dart';
import '../../models/Disease_prediction_result_model.dart';
import '../../services/disease/history_service.dart';
import 'history_detail_view.dart';

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  late Future<List<PredictionResultModel>> futureHistory;

  @override
  void initState() {
    super.initState();

    futureHistory = HistoryService.getFirebaseHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColor.background,

      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Detection History',
          style: TextStyle(
            color: BrandColor.darkText,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      body: FutureBuilder<List<PredictionResultModel>>(
        future: futureHistory,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: BrandColor.primary),
            );
          }

          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          final data = snapshot.data ?? [];

          if (data.isEmpty) {
            return const Center(child: Text('No history found'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final item = data[index];

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HistoryDetailView(result: item),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: BrandColor.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: BrandColor.softPink,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.image_rounded,
                          color: BrandColor.primary,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.diseaseName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              '${item.severityLevel} • '
                              '${item.severityPercentage.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                color: BrandColor.primary,
                                fontSize: 12,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              'Confidence '
                              '${item.confidence.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                color: BrandColor.lightText,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Icon(Icons.arrow_forward_ios_rounded, size: 15),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
