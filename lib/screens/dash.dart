import 'package:flutter/material.dart';

import 'package:skymojo/components/current_nightly.dart';
import 'package:skymojo/components/current_weather.dart';
import 'package:skymojo/components/current_forecast.dart';
import 'package:skymojo/components/sun_position.dart';
import 'package:skymojo/components/comfort_metrics.dart';
import 'package:skymojo/components/weather_alerts.dart';

class HomeDash extends StatefulWidget {
  const HomeDash({super.key});

  @override
  State<HomeDash> createState() => _HomeDashState();
}

class _HomeDashState extends State<HomeDash> {
  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 0.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CurrentWeather(),
            SizedBox(height: 16),
            SunPosition(),
            SizedBox(height: 16),
            ComfortMetrics(),
            SizedBox(height: 16),
            CurrentNightly(),
            SizedBox(height: 16),
            WeatherAlerts(),
            SizedBox(height: 16),
            CurrentForecast(),
          ],
        ),
      ),
    );
  }
}