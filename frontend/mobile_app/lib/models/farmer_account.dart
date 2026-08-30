class FarmerAccount {
  final String id;
  final String fullName;
  final String mobile;
  final String email;
  final String location;
  final String role;
  final String? defaultFarmId;
  final DateTime? createdAt;

  const FarmerAccount({
    required this.id,
    required this.fullName,
    required this.mobile,
    required this.email,
    this.location = '',
    this.role = 'farmer',
    this.defaultFarmId,
    this.createdAt,
  });

  String get initials {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  FarmerAccount copyWith({
    String? fullName,
    String? mobile,
    String? email,
    String? location,
    String? defaultFarmId,
  }) {
    return FarmerAccount(
      id: id,
      fullName: fullName ?? this.fullName,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      location: location ?? this.location,
      role: role,
      defaultFarmId: defaultFarmId ?? this.defaultFarmId,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'mobile': mobile,
      'email': email,
      'location': location,
      'role': role,
      'defaultFarmId': defaultFarmId,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory FarmerAccount.fromJson(String id, Map<String, dynamic> json) {
    return FarmerAccount(
      id: id,
      fullName: (json['fullName'] ?? json['full_name'])?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      location: (json['location'] ?? json['district'] ?? json['farmLocation'])
              ?.toString() ??
          '',
      role: json['role']?.toString() ?? 'farmer',
      defaultFarmId: json['defaultFarmId']?.toString(),
      createdAt: _parseTime(json['createdAt']),
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

class AuthValidationResult {
  final bool isValid;
  final Map<String, String> fieldErrors;

  const AuthValidationResult({
    required this.isValid,
    this.fieldErrors = const {},
  });
}
