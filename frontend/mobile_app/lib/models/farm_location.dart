class FarmLocation {
  final double latitude;
  final double longitude;
  final String source;
  final String? placeName;

  const FarmLocation({
    required this.latitude,
    required this.longitude,
    required this.source,
    this.placeName,
  });

  FarmLocation copyWith({String? placeName}) {
    return FarmLocation(
      latitude: latitude,
      longitude: longitude,
      source: source,
      placeName: placeName ?? this.placeName,
    );
  }
}
