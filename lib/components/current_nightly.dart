import 'package:flutter/material.dart';

class CurrentNightly extends StatefulWidget {
  const CurrentNightly({super.key});

  @override
  State<CurrentNightly> createState() => _CurrentNightlyState();
}

class _CurrentNightlyState extends State<CurrentNightly> {
  Image moonPhaseImg = Image.asset('assets/full-moon.png');
  String moonPhase = 'Full Moon';

  final planetsTonight = [
    Image.asset(
      'assets/mars-planet.png',
      height: 32,
    ),
    Image.asset(
      'assets/venus-planet.png',
      height: 32,
    ),
    Image.asset(
      'assets/jupiter-planet.png',
      height: 32,
    ),
    Image.asset(
      'assets/saturn-planet.png',
      height: 32,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Container(
        child: Card(
            color: const Color(0xFF083235),
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color: Theme.of(context).colorScheme.outline,
              ),
              borderRadius: const BorderRadius.all(Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      moonPhaseImg,
                      const SizedBox(width: 10.0),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tonight\'s Moon Phase:',
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            moonPhase,
                            style: TextStyle(
                              fontSize: 28.0,
                              color: Colors.yellow[700],
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: Center(
                    child: Text(
                      'Planets visible tonight',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ...planetsTonight,
                    ],
                  ),
                ),
                const SizedBox(height: 10.0),
              ],
            )),
      ),
    );
  }
}
