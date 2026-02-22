class UserProfile {
  final String id;
  final String? username;
  final String? fullName;
  final String? avatarUrl;
  final String? defaultLocation;
  final String temperatureUnit;
  final String themePreference;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    this.username,
    this.fullName,
    this.avatarUrl,
    this.defaultLocation,
    this.temperatureUnit = 'celsius',
    this.themePreference = 'auto',
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      username: map['username'] as String?,
      fullName: map['full_name'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      defaultLocation: map['default_location'] as String?,
      temperatureUnit: map['temperature_unit'] as String? ?? 'celsius',
      themePreference: map['theme_preference'] as String? ?? 'auto',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'default_location': defaultLocation,
      'temperature_unit': temperatureUnit,
      'theme_preference': themePreference,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? id,
    String? username,
    String? fullName,
    String? avatarUrl,
    String? defaultLocation,
    String? temperatureUnit,
    String? themePreference,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      defaultLocation: defaultLocation ?? this.defaultLocation,
      temperatureUnit: temperatureUnit ?? this.temperatureUnit,
      themePreference: themePreference ?? this.themePreference,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile &&
        other.id == id &&
        other.username == username &&
        other.fullName == fullName &&
        other.avatarUrl == avatarUrl &&
        other.defaultLocation == defaultLocation &&
        other.temperatureUnit == temperatureUnit &&
        other.themePreference == themePreference;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      username,
      fullName,
      avatarUrl,
      defaultLocation,
      temperatureUnit,
      themePreference,
    );
  }

  @override
  String toString() {
    return 'UserProfile(id: $id, username: $username, fullName: $fullName, defaultLocation: $defaultLocation)';
  }
}
