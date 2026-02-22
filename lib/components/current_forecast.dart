import 'package:flutter/material.dart';

import 'package:skymojo/components/utils/weather_icon.dart';
import 'package:skymojo/services/location_cache_service.dart';

class CurrentForecast extends StatefulWidget {
  final SelectedLocation? selectedLocation;

  const CurrentForecast({super.key, this.selectedLocation});

  @override
  State<CurrentForecast> createState() => _CurrentForecastState();
}

class _CurrentForecastState extends State<CurrentForecast> {
  List<Map<String, dynamic>> days = [
    {"day": "Today", "date": "14/04", "weather": "Sunny"},
    {"day": "Tue", "date": "15/04", "weather": "Cloudy"},
    {"day": "Wed", "date": "16/04", "weather": "Rainy"},
    {"day": "Thur", "date": "17/04", "weather": "Sunny"},
    {"day": "Fri", "date": "18/04/", "weather": "Windy"},
    {"day": "Sat", "date": "19/04", "weather": "Snowy"},
    {"day": "Sun", "date": "20/04", "weather": "Foggy"},
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              "7 Day Forecast",
              style: TextStyle(
                fontSize: 20.0,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.left,
            ),
          ),
          const SizedBox(
            height: 5.0,
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 5.0),
            height: 200.0,
            child: ListView(
              // This next line does the trick.
              scrollDirection: Axis.horizontal,
              children: days.map((day) {
                return weatherBox(day["day"], day["date"], day["weather"],
                    Colors.deepPurpleAccent);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget weatherBox(
      String day, String date, String weather, Color backgroundcolor) {
    return Card(
      color: const Color(0xFFE59500),
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline,
        ),
        borderRadius: const BorderRadius.all(Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 6.0),
            width: 100,
            alignment: Alignment.topCenter,
            child: Column(
              children: [
                Text(day,
                    style: const TextStyle(color: Colors.white, fontSize: 20)),
                Text(date,
                    style: const TextStyle(color: Colors.white, fontSize: 20)),
                WeatherIcon(weather: weather)
              ],
            )),
      ),
    );
  }
}
