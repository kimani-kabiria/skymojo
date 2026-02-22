import 'package:skymojo/models/location_tag.dart';

class FavoriteLocation {
  final String id;
  final String userId;
  final String name;
  final double latitude;
  final double longitude;
  final bool isDefault;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FavoriteLocation({
    required this.id,
    required this.userId,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.isDefault = false,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory FavoriteLocation.fromMap(Map<String, dynamic> map) {
    return FavoriteLocation(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      isDefault: map['is_default'] as bool? ?? false,
      tags:
          (map['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
              [],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'is_default': isDefault,
      'tags': tags,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  FavoriteLocation copyWith({
    String? id,
    String? userId,
    String? name,
    double? latitude,
    double? longitude,
    bool? isDefault,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FavoriteLocation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isDefault: isDefault ?? this.isDefault,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  List<LocationTag> get tagObjects => LocationTag.getByIds(tags);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FavoriteLocation &&
        other.id == id &&
        other.userId == userId &&
        other.name == name &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.isDefault == isDefault;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      name,
      latitude,
      longitude,
      isDefault,
    );
  }

  @override
  String toString() {
    return 'FavoriteLocation(id: $id, name: $name, isDefault: $isDefault, tags: $tags)';
  }
}
