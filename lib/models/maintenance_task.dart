class MaintenanceTask {
  final String id;
  final String userId;
  final String plantId;
  final String taskType; // watering, fertilization, pruning, etc
  final String description;
  final DateTime scheduledDate;
  final DateTime? completedDate;
  final bool isCompleted;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MaintenanceTask({
    required this.id,
    required this.userId,
    required this.plantId,
    required this.taskType,
    required this.description,
    required this.scheduledDate,
    this.completedDate,
    required this.isCompleted,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  // Factory constructor from Supabase JSON
  factory MaintenanceTask.fromJson(Map<String, dynamic> json) {
    return MaintenanceTask(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      plantId: json['plant_id'] ?? '',
      taskType: json['task_type'] ?? 'watering',
      description: json['description'] ?? '',
      scheduledDate: json['scheduled_date'] != null 
          ? DateTime.parse(json['scheduled_date']) 
          : DateTime.now(),
      completedDate: json['completed_date'] != null 
          ? DateTime.parse(json['completed_date']) 
          : null,
      isCompleted: json['is_completed'] ?? false,
      notes: json['description'],
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
      'plant_id': plantId,
      'task_type': taskType,
      'description': description,
      'scheduled_date': scheduledDate.toIso8601String().split('T')[0],
      'is_completed': isCompleted,
      'completed_date': completedDate?.toIso8601String().split('T')[0],
    };
  }

  MaintenanceTask copyWith({
    String? id,
    String? userId,
    String? plantId,
    String? taskType,
    String? description,
    DateTime? scheduledDate,
    DateTime? completedDate,
    bool? isCompleted,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MaintenanceTask(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      plantId: plantId ?? this.plantId,
      taskType: taskType ?? this.taskType,
      description: description ?? this.description,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      completedDate: completedDate ?? this.completedDate,
      isCompleted: isCompleted ?? this.isCompleted,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
