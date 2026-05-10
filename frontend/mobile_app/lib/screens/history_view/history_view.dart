import 'dart:ui';
import 'package:flutter/material.dart';
import '../../common/brand_color.dart';
import '../../common/glass_container.dart';
import '../../models/prediction_result_model.dart';
import '../../services/history_service.dart';

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  late Future<List<PredictionResultModel>> historyFuture;
  late Future<List<String>> diseaseFuture;

  String selectedDisease = 'All';
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    historyFuture = HistoryService.getFirebaseHistory();
    diseaseFuture = HistoryService.getAllDiseases();
  }

  Future<void> _refreshHistory() async {
    setState(() {
      historyFuture = HistoryService.getFirebaseHistory();
      diseaseFuture = HistoryService.getAllDiseases();
      selectedDate = null;
    });
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: BrandColor.primary,
              onPrimary: Colors.white,
              surface: BrandColor.bgDeep,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}  •  '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  bool _isHealthy(String name) => name.toLowerCase() == 'healthy';

  Color _getDiseaseColor(String name) =>
      _isHealthy(name) ? BrandColor.green : BrandColor.primary;

  void _showTreatmentPopup(PredictionResultModel item) {
    showDialog(
      context: context,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: BrandColor.bgDeep,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: BrandColor.glassBorder),
          ),
          title: Text(
            item.diseaseName.replaceAll('_', ' '),
            style: TextStyle(
              color: _getDiseaseColor(item.diseaseName),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            item.treatment,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: BrandColor.lightText,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close', style: TextStyle(color: BrandColor.accent)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteItem(PredictionResultModel item) async {
    if (item.predictionId == null || item.predictionId!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Prediction ID not found')));
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: BrandColor.bgDeep,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(color: BrandColor.glassBorder),
          ),
          title: const Text(
            'Delete History',
            style: TextStyle(color: BrandColor.darkText),
          ),
          content: Text(
            'Do you want to delete this detection record?',
            style: TextStyle(color: BrandColor.lightText),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: TextStyle(color: BrandColor.softText),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Delete', style: TextStyle(color: BrandColor.accent)),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    try {
      await HistoryService.deleteFirebaseHistory(item.predictionId!);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('History deleted successfully')),
      );

      _refreshHistory();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delete error: $e')));
    }
  }

  Widget _diseaseFilterBar() {
    return FutureBuilder<List<String>>(
      future: diseaseFuture,
      builder: (context, snapshot) {
        final diseases = ['All', ...(snapshot.data ?? [])];

        return ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              color: BrandColor.bgDeep.withOpacity(0.85),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: diseases.map((disease) {
                    final isSelected = selectedDisease == disease;

                    return GestureDetector(
                      onTap: () => setState(() => selectedDisease = disease),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(
                                  colors: [
                                    BrandColor.primary,
                                    BrandColor.secondary,
                                  ],
                                )
                              : null,
                          color: isSelected
                              ? null
                              : BrandColor.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : BrandColor.primary.withOpacity(0.25),
                          ),
                        ),
                        child: Text(
                          disease.replaceAll('_', ' '),
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : BrandColor.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _historyCard(PredictionResultModel item) {
    final color = _getDiseaseColor(item.diseaseName);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: color.withOpacity(0.22)),
              ),
              child: Icon(Icons.image_outlined, color: color, size: 30),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.diseaseName.replaceAll('_', ' '),
                    style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(right: 5),
                        decoration: BoxDecoration(
                          color: BrandColor.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Text(
                        'Confidence ${item.confidence}%',
                        style: TextStyle(
                          color: BrandColor.green,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  Text(
                    _formatDateTime(item.detectedAt),
                    style: TextStyle(color: BrandColor.softText, fontSize: 12),
                  ),
                ],
              ),
            ),

            Column(
              children: [
                _CircleIconBtn(
                  icon: Icons.visibility_rounded,
                  color: BrandColor.green,
                  onTap: () => _showTreatmentPopup(item),
                ),
                const SizedBox(height: 10),
                _CircleIconBtn(
                  icon: Icons.delete_outline_rounded,
                  color: BrandColor.primary,
                  onTap: () => _deleteItem(item),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 56, color: BrandColor.softText),
          const SizedBox(height: 14),
          Text(
            'No detection history found',
            style: TextStyle(
              color: BrandColor.lightText,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  bool _sameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColor.background,
      extendBodyBehindAppBar: true,

      appBar: DarkAppBar(
        title: 'Detection History',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GlassContainer(
              borderRadius: BorderRadius.circular(12),
              blur: 12,
              child: IconButton(
                icon: Icon(
                  Icons.calendar_month_rounded,
                  color: BrandColor.accent,
                  size: 20,
                ),
                onPressed: _pickDate,
              ),
            ),
          ),
        ],
      ),

      body: Stack(
        children: [
          const DarkBackground(),

          Column(
            children: [
              SizedBox(
                height: kToolbarHeight + MediaQuery.of(context).padding.top,
              ),

              _diseaseFilterBar(),

              if (selectedDate != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: GlassContainer(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_month_rounded,
                          color: BrandColor.accent,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Selected date: ${selectedDate!.day.toString().padLeft(2, '0')}/'
                            '${selectedDate!.month.toString().padLeft(2, '0')}/'
                            '${selectedDate!.year}',
                            style: TextStyle(
                              color: BrandColor.lightText,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => selectedDate = null),
                          child: Icon(
                            Icons.close_rounded,
                            color: BrandColor.softText,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              Expanded(
                child: FutureBuilder<List<PredictionResultModel>>(
                  future: historyFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: BrandColor.accent,
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'Error: ${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: BrandColor.accent),
                          ),
                        ),
                      );
                    }

                    var history = snapshot.data ?? [];

                    if (selectedDisease != 'All') {
                      history = history
                          .where((i) => i.diseaseName == selectedDisease)
                          .toList();
                    }

                    if (selectedDate != null) {
                      history = history
                          .where((i) => _sameDate(i.detectedAt, selectedDate!))
                          .toList();
                    }

                    if (history.isEmpty) return _emptyView();

                    return RefreshIndicator(
                      onRefresh: _refreshHistory,
                      color: BrandColor.accent,
                      backgroundColor: BrandColor.bgDeep,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: history.length,
                        itemBuilder: (_, i) => _historyCard(history[i]),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircleIconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CircleIconBtn({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withOpacity(0.14),
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.28)),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}
