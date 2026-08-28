class Farm {
  final String id;
  final String farmerId;
  final String farmName;
  final String district;
  final double? latitude;
  final double? longitude;
  final DateTime? createdAt;

  const Farm({
    required this.id,
    required this.farmerId,
    required this.farmName,
    this.district = '',
    this.latitude,
    this.longitude,
    this.createdAt,
  });

  factory Farm.fromFirestore(String id, Map<String, dynamic> data) {
    return Farm(
      id: id,
      farmerId: data['farmerId']?.toString() ?? '',
      farmName: data['farmName']?.toString() ?? 'My Farm',
      district: data['district']?.toString() ?? '',
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      createdAt: _parseTime(data['createdAt']),
    );
  }

  static DateTime? _parseTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    try {
      return (value as dynamic).toDate() as DateTime;
    } catch (_) {
      return DateTime.tryParse(value.toString());
    }
  }
}
