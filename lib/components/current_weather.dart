import 'package:flutter/material.dart';
import 'package:unicons/unicons.dart';
import 'package:skymojo/services/location_cache_service.dart';

class CurrentWeather extends StatefulWidget {
  final SelectedLocation? selectedLocation;

  const CurrentWeather({super.key, this.selectedLocation});

  @override
  State<CurrentWeather> createState() => _CurrentWeatherState();
}

class _CurrentWeatherState extends State<CurrentWeather> {
  //Data Initializations
  String tempDegree = '\u2103';
  // String tempDegreeFah = '\u2109';
  String temp = '32';

  Icon currentTemp = const Icon(
    UniconsLine.cloud_sun,
    size: 160,
    color: Colors.amber,
  );

  String rainChance = '10%';
  String uvIndex = '1.4 U.V Index';
  String windSpeed = '124 km/h';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Container(
        child: Card(
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: Theme.of(context).colorScheme.outline,
            ),
            borderRadius: const BorderRadius.all(Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    currentTemp,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(UniconsLine.temperature),
                        Text(
                          temp,
                          style: const TextStyle(
                            fontSize: 80.0,
                            color: Color(0xFF083235),
                          ),
                        ),
                        Text(
                          tempDegree,
                          style: const TextStyle(
                            fontSize: 32.0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 10.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          UniconsLine.cloud_rain,
                          size: 30,
                        ),
                        Text(
                          rainChance,
                          style: const TextStyle(
                            fontSize: 16.0,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(
                          UniconsLine.sun,
                          size: 30,
                        ),
                        Text(
                          uvIndex,
                          style: const TextStyle(
                            fontSize: 16.0,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(
                          UniconsLine.wind,
                          size: 30,
                        ),
                        Text(
                          windSpeed,
                          style: const TextStyle(
                            fontSize: 16.0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
