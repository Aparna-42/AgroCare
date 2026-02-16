class UserSettings {
  final String id;
  final String userId;
  final int availableDaysPerWeek; // How many days user can spend on plants
  final List<String> preferredDays; // e.g., ['Monday', 'Wednesday', 'Friday']
  final String? preferredTimeOfDay; // morning, afternoon, evening
  final bool enableNotifications;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserSettings({
    required this.id,
    required this.userId,
    required this.availableDaysPerWeek,
    this.preferredDays = const [],
    this.preferredTimeOfDay,
    this.enableNotifications = true,
    this.createdAt,
    this.updatedAt,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      availableDaysPerWeek: json['available_days_per_week'] ?? 3,
      preferredDays: json['preferred_days'] != null
          ? List<String>.from(json['preferred_days'])
          : [],
      preferredTimeOfDay: json['preferred_time_of_day'],
      enableNotifications: json['enable_notifications'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'available_days_per_week': availableDaysPerWeek,
      'preferred_days': preferredDays,
      'preferred_time_of_day': preferredTimeOfDay,
      'enable_notifications': enableNotifications,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  UserSettings copyWith({
    String? id,
    String? userId,
    int? availableDaysPerWeek,
    List<String>? preferredDays,
    String? preferredTimeOfDay,
    bool? enableNotifications,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserSettings(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      availableDaysPerWeek: availableDaysPerWeek ?? this.availableDaysPerWeek,
      preferredDays: preferredDays ?? this.preferredDays,
      preferredTimeOfDay: preferredTimeOfDay ?? this.preferredTimeOfDay,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
