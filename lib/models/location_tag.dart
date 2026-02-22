import 'package:flutter/material.dart';

class LocationTag {
  final String id;
  final String name;
  final String icon;
  final Color color;
  final String description;

  const LocationTag({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.description,
  });

  // Predefined tags
  static const List<LocationTag> predefinedTags = [
    LocationTag(
      id: 'home',
      name: 'Home',
      icon: '🏠',
      color: Colors.blue,
      description: 'Primary residence',
    ),
    LocationTag(
      id: 'work',
      name: 'Work',
      icon: '💼',
      color: Colors.purple,
      description: 'Office or workplace',
    ),
    LocationTag(
      id: 'travel',
      name: 'Travel',
      icon: '✈️',
      color: Colors.green,
      description: 'Travel destinations',
    ),
    LocationTag(
      id: 'gym',
      name: 'Gym',
      icon: '🏃',
      color: Colors.orange,
      description: 'Fitness locations',
    ),
    LocationTag(
      id: 'shopping',
      name: 'Shopping',
      icon: '🛒',
      color: Colors.pink,
      description: 'Stores and malls',
    ),
    LocationTag(
      id: 'dining',
      name: 'Dining',
      icon: '🍽️',
      color: Colors.red,
      description: 'Restaurants and cafes',
    ),
    LocationTag(
      id: 'medical',
      name: 'Medical',
      icon: '🏥',
      color: Colors.teal,
      description: 'Hospitals and clinics',
    ),
    LocationTag(
      id: 'education',
      name: 'Education',
      icon: '🎓',
      color: Colors.indigo,
      description: 'Schools and universities',
    ),
    LocationTag(
      id: 'gas',
      name: 'Gas',
      icon: '⛽',
      color: Colors.grey,
      description: 'Gas stations',
    ),
    LocationTag(
      id: 'hotel',
      name: 'Hotel',
      icon: '🏨',
      color: Colors.brown,
      description: 'Hotels and lodging',
    ),
  ];

  static LocationTag? getById(String id) {
    try {
      return predefinedTags.firstWhere((tag) => tag.id == id);
    } catch (e) {
      return null;
    }
  }

  static List<LocationTag> getByIds(List<String> ids) {
    return ids.map((id) => getById(id)).whereType<LocationTag>().toList();
  }
}
