/// User Model
/// 
/// Represents an authenticated user in the AgroCare system.
/// Stores user profile information, location for weather data,
/// and profile customization settings.
class User {
  /// Unique identifier matching auth.users.id
  final String id;
  
  /// Display name
  final String name;
  
  /// Email address for authentication
  final String email;
  
  /// Profile picture URL from storage
  final String? profileImage;
  
  /// User location for weather data and plant recommendations
  final String? location;
  
  /// Account creation timestamp
  final DateTime? createdAt;
  
  /// Last profile update timestamp
  final DateTime? updatedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.profileImage,
    this.location,
    this.createdAt,
    this.updatedAt,
  });

  // Factory constructor to create User from Supabase JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? 'User',
      email: json['email'] ?? '',
      profileImage: json['profile_image_url'],
      location: json['location'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }

  // Convert User to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profile_image_url': profileImage,
      'location': location,
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? profileImage,
    String? location,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      profileImage: profileImage ?? this.profileImage,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
