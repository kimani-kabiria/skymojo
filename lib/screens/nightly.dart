import 'package:flutter/material.dart';

class NightlyDash extends StatefulWidget {
  const NightlyDash({super.key});

  @override
  State<NightlyDash> createState() => _NightlyDashState();
}

class _NightlyDashState extends State<NightlyDash> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: const Text('Nightly Dash'),
    );
  }
}
