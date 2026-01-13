class Plant {
  final String id;
  final String userId;
  final String name;
  final String type;
  final String? imageUrl;
  final DateTime plantedDate;
  final String healthStatus; // healthy, warning, critical
  final List<String> symptoms;
  final String? disease;
  final String? location;
  final int daysGrown;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Plant({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    this.imageUrl,
    required this.plantedDate,
    required this.healthStatus,
    required this.symptoms,
    this.disease,
    this.location,
    required this.daysGrown,
    this.createdAt,
    this.updatedAt,
  });

  // Factory constructor from Supabase JSON
  factory Plant.fromJson(Map<String, dynamic> json) {
    return Plant(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      name: json['name'] ?? 'Plant',
      type: json['type'] ?? 'Unknown',
      imageUrl: json['image_url'],
      plantedDate: json['planted_date'] != null 
          ? DateTime.parse(json['planted_date']) 
          : DateTime.now(),
      healthStatus: json['health_status'] ?? 'healthy',
      symptoms: json['symptoms'] != null 
          ? (json['symptoms'] as String).split(',').map((s) => s.trim()).toList()
          : [],
      disease: json['disease'],
      location: json['location'],
      daysGrown: json['days_grown'] ?? 0,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }

  // Convert to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'type': type,
      'image_url': imageUrl,
      'planted_date': plantedDate.toIso8601String().split('T')[0],
      'health_status': healthStatus,
      'symptoms': symptoms.join(','),
      'disease': disease,
      'location': location,
      'days_grown': daysGrown,
    };
  }

  Plant copyWith({
    String? id,
    String? userId,
    String? name,
    String? type,
    String? imageUrl,
    DateTime? plantedDate,
    String? healthStatus,
    List<String>? symptoms,
    String? disease,
    String? location,
    int? daysGrown,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Plant(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      imageUrl: imageUrl ?? this.imageUrl,
      plantedDate: plantedDate ?? this.plantedDate,
      healthStatus: healthStatus ?? this.healthStatus,
      symptoms: symptoms ?? this.symptoms,
      disease: disease ?? this.disease,
      location: location ?? this.location,
      daysGrown: daysGrown ?? this.daysGrown,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
