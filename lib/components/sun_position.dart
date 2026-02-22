import 'package:flutter/material.dart';
import 'package:unicons/unicons.dart';

class SunPosition extends StatelessWidget {
  const SunPosition({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline,
        ),
        borderRadius: const BorderRadius.all(Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sun & Moon Position',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF083235),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
              ),
              child: CustomPaint(
                size: const Size(double.infinity, 120),
                painter: SunPathPainter(),
                child: Stack(
                  children: [
                    Positioned(
                      left: MediaQuery.of(context).size.width * 0.3,
                      top: 30,
                      child: const Icon(
                        UniconsLine.sun,
                        color: Colors.orange,
                        size: 32,
                      ),
                    ),
                    Positioned(
                      right: MediaQuery.of(context).size.width * 0.15,
                      top: 60,
                      child: const Icon(
                        UniconsLine.moon,
                        color: Color(0xFF083235),
                        size: 32,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sunrise',
                      style: TextStyle(color: Colors.grey),
                    ),
                    Text(
                      '6:30 AM',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Sunset',
                      style: TextStyle(color: Colors.grey),
                    ),
                    Text(
                      '6:45 PM',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SunPathPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    path.moveTo(0, size.height);
    path.quadraticBezierTo(
      size.width / 2,
      0,
      size.width,
      size.height,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}