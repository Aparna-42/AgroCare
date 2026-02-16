/// Plant Model
/// 
/// Represents a plant in the user's collection with AI identification data
/// and care instructions. Includes health status tracking and maintenance history.
class Plant {
  /// Unique identifier for the plant
  final String id;
  
  /// Owner's user ID (for RLS security)
  final String userId;
  
  /// Common name identified by AI
  final String plantName;
  
  /// Scientific/botanical name
  final String? scientificName;
  
  /// User-given nickname for the plant
  final String? nickname;
  
  /// Cloud storage URL for plant image
  final String? imageUrl;
  
  /// AI identification confidence score (0-100)
  final double confidence;
  
  /// Watering instructions
  final String? careWater;
  
  /// Sunlight requirements
  final String? careSunlight;
  
  /// Temperature range preferences
  final String? careTemperature;
  
  /// Current health status: 'healthy', 'warning', or 'critical'
  final String healthStatus;
  
  /// Timestamp when plant was added
  final DateTime? createdAt;
  
  /// Last update timestamp
  final DateTime? updatedAt;

  Plant({
    required this.id,
    required this.userId,
    required this.plantName,
    this.scientificName,
    this.nickname,
    this.imageUrl,
    required this.confidence,
    this.careWater,
    this.careSunlight,
    this.careTemperature,
    this.healthStatus = 'healthy',
    this.createdAt,
    this.updatedAt,
  });

  // Factory constructor from Supabase JSON
  factory Plant.fromJson(Map<String, dynamic> json) {
    return Plant(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      plantName: json['plant_name'] ?? 'Plant',
      scientificName: json['scientific_name'],
      nickname: json['nickname'],
      imageUrl: json['image_url'],
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      careWater: json['care_water'],
      careSunlight: json['care_sunlight'],
      careTemperature: json['care_temperature'],
      healthStatus: json['health_status'] ?? 'healthy',
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
      'id': id,
      'user_id': userId,
      'plant_name': plantName,
      'scientific_name': scientificName,
      'nickname': nickname,
      'image_url': imageUrl,
      'confidence': confidence,
      'care_water': careWater,
      'care_sunlight': careSunlight,
      'care_temperature': careTemperature,
      'health_status': healthStatus,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Plant copyWith({
    String? id,
    String? userId,
    String? plantName,
    String? scientificName,
    String? nickname,
    String? imageUrl,
    double? confidence,
    String? careWater,
    String? careSunlight,
    String? careTemperature,
    String? healthStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Plant(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      plantName: plantName ?? this.plantName,
      scientificName: scientificName ?? this.scientificName,
      nickname: nickname ?? this.nickname,
      imageUrl: imageUrl ?? this.imageUrl,
      confidence: confidence ?? this.confidence,
      careWater: careWater ?? this.careWater,
      careSunlight: careSunlight ?? this.careSunlight,
      careTemperature: careTemperature ?? this.careTemperature,
      healthStatus: healthStatus ?? this.healthStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
