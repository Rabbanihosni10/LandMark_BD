class Landmark {
  final String id;
  String title;
  double latitude;
  double longitude;
  String? imagePath;
  DateTime createdAt;

  Landmark({
    required this.id,
    required this.title,
    required this.latitude,
    required this.longitude,
    this.imagePath,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Landmark.fromJson(Map<String, dynamic> json) => Landmark(
    id: json['id'].toString(),
    title: json['title'] ?? '',
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    imagePath: json['imagePath'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'latitude': latitude,
    'longitude': longitude,
    'imagePath': imagePath,
    'createdAt': createdAt.toIso8601String(),
  };
}
