import 'package:flutter/material.dart';

class WeatherIcon extends StatelessWidget {
  final String weather;

  const WeatherIcon({super.key, required this.weather});

  @override
  Widget build(BuildContext context) {
    IconData iconData;
    switch (weather) {
      case "Sunny":
        iconData = Icons.wb_sunny;
        break;
      case "Cloudy":
        iconData = Icons.wb_cloudy;
        break;
      case "Rainy":
        iconData = Icons.grain;
        break;
      default:
        iconData = Icons.help_outline;
    }
    return Icon(iconData);
  }
}