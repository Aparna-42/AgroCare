/// Treatment model for plant disease treatments
/// Maps to the treatment table in Supabase
class Treatment {
  final String id;
  final String plantName;
  final String diseaseName;
  final List<String> treatmentSuggestions;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Treatment({
    required this.id,
    required this.plantName,
    required this.diseaseName,
    required this.treatmentSuggestions,
    this.createdAt,
    this.updatedAt,
  });

  /// Factory constructor from Supabase JSON
  factory Treatment.fromJson(Map<String, dynamic> json) {
    return Treatment(
      id: json['id'] ?? '',
      plantName: json['plant_name'] ?? '',
      diseaseName: json['disease_name'] ?? '',
      treatmentSuggestions: json['treatment_suggestions'] != null
          ? List<String>.from(json['treatment_suggestions'])
          : [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  /// Convert to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plant_name': plantName,
      'disease_name': diseaseName,
      'treatment_suggestions': treatmentSuggestions,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
