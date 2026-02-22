import 'package:flutter/material.dart';

import 'package:skymojo/components/current_nightly.dart';
import 'package:skymojo/components/current_weather.dart';
import 'package:skymojo/components/current_forecast.dart';
import 'package:skymojo/components/sun_position.dart';
import 'package:skymojo/components/comfort_metrics.dart';
import 'package:skymojo/components/weather_alerts.dart';
import 'package:skymojo/components/location_selector.dart';
import 'package:skymojo/services/location_cache_service.dart';

class HomeDash extends StatefulWidget {
  const HomeDash({super.key});

  @override
  State<HomeDash> createState() => _HomeDashState();
}

class _HomeDashState extends State<HomeDash> {
  SelectedLocation? _selectedLocation;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 0.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Location Selector
            LocationSelector(
              onLocationChanged: (SelectedLocation location) {
                setState(() {
                  _selectedLocation = location;
                });
              },
            ),
            const SizedBox(height: 16),
            CurrentWeather(selectedLocation: _selectedLocation),
            const SizedBox(height: 16),
            SunPosition(selectedLocation: _selectedLocation),
            const SizedBox(height: 16),
            ComfortMetrics(selectedLocation: _selectedLocation),
            const SizedBox(height: 16),
            CurrentNightly(selectedLocation: _selectedLocation),
            const SizedBox(height: 16),
            WeatherAlerts(selectedLocation: _selectedLocation),
            const SizedBox(height: 16),
            CurrentForecast(selectedLocation: _selectedLocation),
          ],
        ),
      ),
    );
  }
}
