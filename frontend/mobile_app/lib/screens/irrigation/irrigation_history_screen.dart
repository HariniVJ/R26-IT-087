import 'package:flutter/material.dart';

import '../../common/brand_color.dart';
import '../../common/common_widgets.dart';
import '../../models/irrigation_history_record.dart';
import '../../services/irrigation_history_service.dart';

class IrrigationHistoryScreen extends StatefulWidget {
  const IrrigationHistoryScreen({super.key});

  @override
  State<IrrigationHistoryScreen> createState() =>
      _IrrigationHistoryScreenState();
}

class _IrrigationHistoryScreenState extends State<IrrigationHistoryScreen> {
  late Future<List<IrrigationHistoryRecord>> _future;

  @override
  void initState() {
    super.initState();
    _future = IrrigationHistoryService.instance.getAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text('Irrigation History'),
        backgroundColor: BrandColor.primary,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<IrrigationHistoryRecord>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final records = snapshot.data!;
          if (records.isEmpty) {
            return const Center(
              child: Text('No irrigation records yet.'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: records.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _HistoryTile(record: records[index]),
          );
        },
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final IrrigationHistoryRecord record;

  const _HistoryTile({required this.record});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            record.status,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            _format(record.createdAt),
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(record.reason, style: const TextStyle(height: 1.4)),
          const SizedBox(height: 8),
          Text(
            'Soil ${record.soilMoisture}%  •  Weather: ${record.weatherSource}',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  String _format(DateTime time) {
    return '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} '
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
