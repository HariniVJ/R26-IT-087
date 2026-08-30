import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

const Color kPrimary = Color(0xFFC13B57);
const Color kPrimaryPink = Color(0xFFE14D75);
const Color kBg = Color(0xFFFFF5F7);
const Color kGreen = Color(0xFF2E7D32);
const Color kOrange = Color(0xFFE76F51);
const Color kGray = Color(0xFF6B7280);
const Color kBlack = Color(0xFF111111);

class GrowthHistoryScreen extends StatefulWidget {
  const GrowthHistoryScreen({super.key});

  @override
  State<GrowthHistoryScreen> createState() => _GrowthHistoryScreenState();
}

class _GrowthHistoryScreenState extends State<GrowthHistoryScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  late String _farmerId;
  bool _isLoading = true;
  List<Map<String, dynamic>> _records = [];

  @override
  void initState() {
    super.initState();
    _loadGrowthHistory();
  }

  Future<void> _loadGrowthHistory() async {
    try {
      // Get current farmer ID from Firebase Auth
      final uid = FirebaseFirestore.instance
          .app
          .options
          .projectId; // You can also use FirebaseAuth.instance.currentUser?.uid

      // For now, we'll query all records (you can filter by farmerId later)
      final snapshot = await _db
          .collection('growth_predictions')
          .orderBy('recordedAt', descending: true)
          .limit(50)
          .get();

      if (mounted) {
        setState(() {
          _records = snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading growth history: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: kPrimary.withOpacity(0.2),
              ),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 15,
              color: kPrimary,
            ),
          ),
        ),
        title: const Text(
          'Growth Detection History',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: kBlack,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              decoration: BoxDecoration(
                color: kBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: kPrimary.withOpacity(0.2),
                ),
              ),
              child: const Icon(
                Icons.refresh_rounded,
                size: 16,
                color: kPrimary,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: kPrimary,
              ),
            )
          : _records.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox_rounded,
                        size: 48,
                        color: kGray.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No records yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: kGray,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Capture and analyze images to see history',
                        style: TextStyle(
                          fontSize: 12,
                          color: kGray.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: _records.length,
                  itemBuilder: (context, index) {
                    final record = _records[index];
                    return _recordCard(record);
                  },
                ),
    );
  }

  Widget _recordCard(Map<String, dynamic> record) {
    final stage = record['detectedStage'] ?? 'Unknown';
    final confidence =
        (record['confidencePercent'] as num?)?.toDouble() ?? 0;
    final soilTemp = (record['soilTemperatureCelsius'] as num?)?.toDouble();
    final weatherTemp =
        (record['weatherTemperatureCelsius'] as num?)?.toDouble();
    final captured = record['capturedAt'] as Timestamp?;
    final dateStr = captured != null
        ? '${captured.toDate().day}/${captured.toDate().month}/${captured.toDate().year}'
        : 'N/A';

    Color stageColor = kGreen;
    if (stage == 'MatureFruit') {
      stageColor = kOrange;
    } else if (stage == 'Flower') {
      stageColor = kPrimaryPink;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Stage and Confidence
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: stageColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: stageColor.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  stage,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: stageColor,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${confidence.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: kBlack,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.check_circle_rounded,
                size: 14,
                color: confidence > 80 ? kGreen : kOrange,
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Date and Time
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 14,
                color: kGray,
              ),
              const SizedBox(width: 6),
              Text(
                dateStr,
                style: TextStyle(
                  fontSize: 12,
                  color: kGray,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.access_time_rounded,
                size: 14,
                color: kGray,
              ),
              const SizedBox(width: 6),
              Text(
                captured != null
                    ? '${captured.toDate().hour}:${captured.toDate().minute.toString().padLeft(2, '0')}'
                    : 'N/A',
                style: TextStyle(
                  fontSize: 12,
                  color: kGray,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Temperature Data
          Row(
            children: [
              Expanded(
                child: _tempBadge(
                  label: 'Soil',
                  value: soilTemp,
                  icon: Icons.water_drop_rounded,
                  source: record['soilSensorSource'] ?? 'api',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _tempBadge(
                  label: 'Weather',
                  value: weatherTemp,
                  icon: Icons.cloud_rounded,
                  source: 'api',
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Care Tip (if available)
          if ((record['careTip'] as String?)?.isNotEmpty ?? false) ...[
            Text(
              'Care Tip',
              style: TextStyle(
                fontSize: 10,
                color: kGray,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              record['careTip'] ?? '',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[700],
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _tempBadge({
    required String label,
    required double? value,
    required IconData icon,
    required String source,
  }) {
    final displayValue = value != null ? '${value.toStringAsFixed(1)}°C' : 'N/A';
    final showLive = source == 'esp32_ble';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: kBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: kGray),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  color: kGray,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (showLive) ...[
                const SizedBox(width: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: kGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    'Live',
                    style: TextStyle(
                      fontSize: 7,
                      color: kGreen,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(
            displayValue,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: kBlack,
            ),
          ),
        ],
      ),
    );
  }
}
