/// PlantMaintenance Model
/// 
/// Represents plant maintenance data from the Supabase `plant_maintenance` table.
/// Contains optimal growing conditions and care requirements for each plant.
/// 
/// Used in the maintenance feature to provide plant-specific care recommendations.
class PlantMaintenance {
  /// Unique identifier for the plant in the maintenance database
  final int plantId;
  
  /// Scientific/botanical name of the plant (e.g., "Solanum lycopersicum")
  final String scientificName;
  
  /// Common name of the plant (e.g., "Tomato")
  final String commonName;
  
  /// Minimum temperature the plant can tolerate (in Celsius)
  final double minTempC;
  
  /// Maximum temperature the plant can tolerate (in Celsius)
  final double maxTempC;
  
  /// Minimum humidity percentage required
  final double minHumidity;
  
  /// Maximum humidity percentage acceptable
  final double maxHumidity;
  
  /// Annual rainfall requirement in millimeters
  final double annualRainfallMm;
  
  /// Maximum wind speed the plant can withstand (in km/h)
  final double maxWindSpeedKmph;
  
  /// Number of days between watering sessions
  final int wateringFrequencyDays;
  
  /// Amount of water needed per watering session (in liters)
  final double wateringAmountLiters;
  
  /// Number of days between pruning sessions
  final int pruningFrequencyDays;
  
  /// Type of fertilizer recommended (e.g., "NPK 10-10-10", "Organic compost")
  final String fertilizerType;
  
  /// Number of days between fertilizer applications
  final int fertilizerIntervalDays;
  
  /// Preferred soil type (e.g., "Loamy", "Sandy", "Clay")
  final String soilType;
  
  /// Sunlight requirement (e.g., "Full sun", "Partial shade", "Full shade")
  final String sunlightRequirement;
  
  /// Additional maintenance notes and tips
  final String? maintenanceNotes;

  PlantMaintenance({
    required this.plantId,
    required this.scientificName,
    required this.commonName,
    required this.minTempC,
    required this.maxTempC,
    required this.minHumidity,
    required this.maxHumidity,
    required this.annualRainfallMm,
    required this.maxWindSpeedKmph,
    required this.wateringFrequencyDays,
    required this.wateringAmountLiters,
    required this.pruningFrequencyDays,
    required this.fertilizerType,
    required this.fertilizerIntervalDays,
    required this.soilType,
    required this.sunlightRequirement,
    this.maintenanceNotes,
  });

  /// Factory constructor to create PlantMaintenance from Supabase JSON response
  /// 
  /// Handles null values with sensible defaults for robustness
  factory PlantMaintenance.fromJson(Map<String, dynamic> json) {
    return PlantMaintenance(
      plantId: json['plant_id'] ?? 0,
      scientificName: json['scientific_name'] ?? 'Unknown',
      commonName: json['common_name'] ?? 'Unknown Plant',
      minTempC: (json['min_temp_c'] as num?)?.toDouble() ?? 15.0,
      maxTempC: (json['max_temp_c'] as num?)?.toDouble() ?? 30.0,
      minHumidity: (json['min_humidity'] as num?)?.toDouble() ?? 40.0,
      maxHumidity: (json['max_humidity'] as num?)?.toDouble() ?? 80.0,
      annualRainfallMm: (json['annual_rainfall_mm'] as num?)?.toDouble() ?? 800.0,
      maxWindSpeedKmph: (json['max_wind_speed_kmph'] as num?)?.toDouble() ?? 40.0,
      wateringFrequencyDays: json['watering_frequency_days'] ?? 3,
      wateringAmountLiters: (json['watering_amount_liters'] as num?)?.toDouble() ?? 1.0,
      pruningFrequencyDays: json['pruning_frequency_days'] ?? 30,
      fertilizerType: json['fertilizer_type'] ?? 'Balanced NPK',
      fertilizerIntervalDays: json['fertilizer_interval_days'] ?? 14,
      soilType: json['soil_type'] ?? 'Loamy',
      sunlightRequirement: json['sunlight_requirement'] ?? 'Full sun',
      maintenanceNotes: json['maintenance_notes'],
    );
  }

  /// Convert PlantMaintenance to JSON for Supabase operations
  Map<String, dynamic> toJson() {
    return {
      'plant_id': plantId,
      'scientific_name': scientificName,
      'common_name': commonName,
      'min_temp_c': minTempC,
      'max_temp_c': maxTempC,
      'min_humidity': minHumidity,
      'max_humidity': maxHumidity,
      'annual_rainfall_mm': annualRainfallMm,
      'max_wind_speed_kmph': maxWindSpeedKmph,
      'watering_frequency_days': wateringFrequencyDays,
      'watering_amount_liters': wateringAmountLiters,
      'pruning_frequency_days': pruningFrequencyDays,
      'fertilizer_type': fertilizerType,
      'fertilizer_interval_days': fertilizerIntervalDays,
      'soil_type': soilType,
      'sunlight_requirement': sunlightRequirement,
      'maintenance_notes': maintenanceNotes,
    };
  }

  /// Get optimal temperature range as a formatted string
  String get temperatureRange => '$minTempC°C - $maxTempC°C';

  /// Get optimal humidity range as a formatted string
  String get humidityRange => '${minHumidity.toInt()}% - ${maxHumidity.toInt()}%';

  /// Get watering schedule description
  String get wateringSchedule => 'Every $wateringFrequencyDays days, ${wateringAmountLiters}L per session';

  /// Get pruning schedule description
  String get pruningSchedule => 'Every $pruningFrequencyDays days';

  /// Get fertilization schedule description
  String get fertilizationSchedule => '$fertilizerType every $fertilizerIntervalDays days';

  /// Create a copy with modified fields
  PlantMaintenance copyWith({
    int? plantId,
    String? scientificName,
    String? commonName,
    double? minTempC,
    double? maxTempC,
    double? minHumidity,
    double? maxHumidity,
    double? annualRainfallMm,
    double? maxWindSpeedKmph,
    int? wateringFrequencyDays,
    double? wateringAmountLiters,
    int? pruningFrequencyDays,
    String? fertilizerType,
    int? fertilizerIntervalDays,
    String? soilType,
    String? sunlightRequirement,
    String? maintenanceNotes,
  }) {
    return PlantMaintenance(
      plantId: plantId ?? this.plantId,
      scientificName: scientificName ?? this.scientificName,
      commonName: commonName ?? this.commonName,
      minTempC: minTempC ?? this.minTempC,
      maxTempC: maxTempC ?? this.maxTempC,
      minHumidity: minHumidity ?? this.minHumidity,
      maxHumidity: maxHumidity ?? this.maxHumidity,
      annualRainfallMm: annualRainfallMm ?? this.annualRainfallMm,
      maxWindSpeedKmph: maxWindSpeedKmph ?? this.maxWindSpeedKmph,
      wateringFrequencyDays: wateringFrequencyDays ?? this.wateringFrequencyDays,
      wateringAmountLiters: wateringAmountLiters ?? this.wateringAmountLiters,
      pruningFrequencyDays: pruningFrequencyDays ?? this.pruningFrequencyDays,
      fertilizerType: fertilizerType ?? this.fertilizerType,
      fertilizerIntervalDays: fertilizerIntervalDays ?? this.fertilizerIntervalDays,
      soilType: soilType ?? this.soilType,
      sunlightRequirement: sunlightRequirement ?? this.sunlightRequirement,
      maintenanceNotes: maintenanceNotes ?? this.maintenanceNotes,
    );
  }

  @override
  String toString() {
    return 'PlantMaintenance(plantId: $plantId, scientificName: $scientificName, commonName: $commonName)';
  }
}
