import 'package:flutter/material.dart';

import '../../common/brand_color.dart';
import '../../common/common_widgets.dart';
import '../../l10n/app_strings.dart';
import '../../models/fertilizer_advice.dart';
import '../../services/firebase/firestore_service.dart';

class FertilizerHistoryScreen extends StatefulWidget {
  const FertilizerHistoryScreen({super.key});

  @override
  State<FertilizerHistoryScreen> createState() =>
      _FertilizerHistoryScreenState();
}

class _FertilizerHistoryScreenState extends State<FertilizerHistoryScreen> {
  late Future<List<FertilizerAdvice>> _future;

  @override
  void initState() {
    super.initState();
    _future = FirestoreService.instance.getFertilizerHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text('Fertilizer History'),
        backgroundColor: BrandColor.primary,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<FertilizerAdvice>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text('Could not load fertilizer history.'),
            );
          }
          final records = snapshot.data ?? [];
          if (records.isEmpty) {
            return const Center(child: Text('No fertilizer records yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: records.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final record = records[index];
              return AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.fertilizerClass,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      record.createdAt == null
                          ? 'Saved recommendation'
                          : _format(record.createdAt!),
                      style: const TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${t('tree')}: ${record.treeId == null || record.treeId!.isEmpty ? 'POM-001' : record.treeId}',
                    ),
                    Text('N: ${record.nitrogen.toStringAsFixed(0)}  P: ${record.phosphorus.toStringAsFixed(0)}  K: ${record.potassium.toStringAsFixed(0)}'),
                    Text('${t('soilPh')}: ${record.ph?.toStringAsFixed(1) ?? '--'}'),
                    const SizedBox(height: 8),
                    Text(
                      '${t('recommendedFertilizer')}: ${record.fertilizerClass}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '${t('urea')} ${record.ureaG} g  •  ${t('tsp')} ${record.tspG} g  •  ${t('mop')} ${record.mopG} g',
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Stage: ${record.stageName.replaceAll('_', ' ')}',
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _format(DateTime time) {
    return '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} '
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
