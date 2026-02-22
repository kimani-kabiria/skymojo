import 'package:flutter/material.dart';

class WeatherDash extends StatefulWidget {
  const WeatherDash({super.key});

  @override
  State<WeatherDash> createState() => _WeatherDashState();
}

class _WeatherDashState extends State<WeatherDash> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: const Text('Weather Dash'),
    );
  }
}
