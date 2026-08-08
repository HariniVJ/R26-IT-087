import 'package:flutter/material.dart';

class FertilizerResultScreen extends StatelessWidget {
  final Map<String, dynamic> result;
  final String treeAge;
  final String nitrogen;
  final String phosphorus;
  final String potassium;

  const FertilizerResultScreen({
    super.key,
    required this.result,
    required this.treeAge,
    required this.nitrogen,
    required this.phosphorus,
    required this.potassium,
  });

  static const Color mainRed = Color(0xFFBB2222);

  String cleanStageName(String value) {
    if (value == '-') return '-';
    return value.replaceAll('_', ' ');
  }

  @override
  Widget build(BuildContext context) {
    final fertilizerClass = result['fertilizer_class']?.toString() ?? '-';
    final stageName = result['stage_name']?.toString() ?? '-';
    final amount = result['fertilizer_amount'];
    final ecWarning = result['ec_warning']?.toString() ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const Expanded(
                    child: Text(
                      'Fertilizer Recommendation',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),

              const SizedBox(height: 18),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.asset(
                            'assets/images/farm_bg.jpeg',
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CROP',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.black45,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Pomegranate',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _summaryItem('Trees', '1'),
                        _summaryItem('Age', '$treeAge years'),
                        _summaryItem('Stage', cleanStageName(stageName)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Nutrient Quantity',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  _nutrientCard(
                    title: 'Nitrogen',
                    symbol: 'N',
                    value: '$nitrogen g',
                    color: const Color(0xFF1296F3),
                  ),
                  const SizedBox(width: 10),
                  _nutrientCard(
                    title: 'Phosphorus',
                    symbol: 'P',
                    value: '$phosphorus g',
                    color: const Color(0xFFFF5722),
                  ),
                  const SizedBox(width: 10),
                  _nutrientCard(
                    title: 'Potassium',
                    symbol: 'K',
                    value: '$potassium g',
                    color: const Color(0xFFB71FD1),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recommended Fertilizer Amount',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(height: 16),

                    _fertilizerRow(
                      letter: 'U',
                      name: 'Urea',
                      amount: '${amount['urea_g']} g/tree',
                      color: const Color(0xFF26B6E8),
                    ),
                    _fertilizerRow(
                      letter: 'T',
                      name: 'TSP',
                      amount: '${amount['tsp_g']} g/tree',
                      color: const Color(0xFFF39C12),
                    ),
                    _fertilizerRow(
                      letter: 'M',
                      name: 'MOP',
                      amount: '${amount['mop_g']} g/tree',
                      color: const Color(0xFFFF3B3B),
                    ),

                    if (ecWarning.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(
                        ecWarning,
                        style: const TextStyle(
                          color: mainRed,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 28),

              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: mainRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 17),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  'View Details',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryItem(String title, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _nutrientCard({
    required String title,
    required String symbol,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        height: 124,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 2,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              symbol,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 17,
              ),
            ),
            const Text(
              'PER TREE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fertilizerRow({
    required String letter,
    required String name,
    required String amount,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E2E2)),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: color,
            child: Text(
              letter,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}