class AppNotification {
  final String id;
  final String farmerId;
  final String? farmId;
  final String? treeId;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.farmerId,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.farmId,
    this.treeId,
  });

  factory AppNotification.fromFirestore(String id, Map<String, dynamic> data) {
    return AppNotification(
      id: id,
      farmerId: (data['farmerId'] ?? data['userId'])?.toString() ?? '',
      farmId: data['farmId']?.toString(),
      treeId: (data['treeId'] ?? data['zoneId'])?.toString(),
      type: data['type']?.toString() ?? '',
      title: data['title']?.toString() ?? '',
      message: data['message']?.toString() ?? '',
      isRead: data['isRead'] == true,
      createdAt: _parseTime(data['createdAt']) ?? DateTime.now().toUtc(),
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
