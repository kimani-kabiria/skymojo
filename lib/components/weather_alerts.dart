import 'package:flutter/material.dart';
import 'package:unicons/unicons.dart';

class WeatherAlerts extends StatelessWidget {
  const WeatherAlerts({super.key});

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
            const Row(
              children: [
                Icon(
                  UniconsLine.exclamation_triangle,
                  color: Colors.red,
                ),
                SizedBox(width: 8),
                Text(
                  'Weather Alerts',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF083235),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildAlert(
              title: 'Heavy Rain Warning',
              description: 'Expected heavy rainfall in your area',
              severity: 'Moderate',
              color: Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildAlert(
              title: 'Strong Winds',
              description: 'Wind speeds may reach up to 40km/h',
              severity: 'Low',
              color: Colors.yellow[700]!,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlert({
    required String title,
    required String description,
    required String severity,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  severity,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}