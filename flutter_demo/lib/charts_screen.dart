import 'package:flutter/material.dart';

// Represents a historical chart visualization screen.
class ChartsScreen extends StatelessWidget {
  final String systemId;
  const ChartsScreen({required this.systemId, super.key});

  // Helper method to create a standardized card for each sensor chart.
  Widget _buildChartCard(
    BuildContext context, {
    required String title,
    // Add an optional hint for what kind of chart will go here
    String chartHint = 'Historical Line Chart',
    // Optional icon for visual appeal
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 6,
      // Rounded corners for the card
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and Icon Row
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 10),
                Text(
                  // Chart Title
                  '$title Trend',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade700,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),

            // --- Placeholder Area for the Actual Chart Widget ---
            Container(
              // Give the chart area a fixed, large height to demonstrate space
              height: 250,
              width: double.infinity, // Take full width
              decoration: BoxDecoration(
                color:
                    Colors.grey.shade100, // Light background for the chart area
                borderRadius: BorderRadius.circular(10),
                // Using withAlpha(128) for 50% opacity (255 * 0.5 = 127.5)
                border: Border.all(color: color.withAlpha(128), width: 1),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Using withAlpha(178) for 70% opacity (255 * 0.7 = 178.5)
                    Icon(Icons.bar_chart,
                        size: 48, color: color.withAlpha(178)),
                    const SizedBox(height: 8),
                    Text(
                      '$chartHint for $title on $systemId',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
            // --- End of Placeholder Area ---
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // Light teal background for the whole screen
      color: Colors.teal.shade50,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main Screen Title
            Text(
              systemId,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade700,
              ),
            ),
            const Divider(height: 20, thickness: 1),

            // 1. Temperature Chart
            _buildChartCard(
              context,
              title: 'Temperature',
              icon: Icons.thermostat_outlined,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),

            // 2. pH Level Chart
            _buildChartCard(
              context,
              title: 'pH Level',
              icon: Icons.science_outlined,
              color: Colors.green.shade400,
            ),
            const SizedBox(height: 16),

            // 3. Water Level Chart
            _buildChartCard(
              context,
              title: 'Water Level',
              icon: Icons.water_drop_outlined,
              color: Colors.blue.shade400,
            ),
            const SizedBox(height: 16),

            // 4. Conductivity Chart
            _buildChartCard(
              context,
              title: 'Conductivity',
              icon: Icons.scatter_plot_outlined,
              color: Colors.purple.shade400,
            ),
            const SizedBox(height: 16),

            // 5. Light Intensity Chart
            _buildChartCard(
              context,
              title: 'Light Intensity',
              icon: Icons.lightbulb_outline,
              color: Colors.amber.shade400,
            ),
            const SizedBox(height: 16),

            // 6. Turbidity Chart
            _buildChartCard(
              context,
              title: 'Turbidity',
              icon: Icons.opacity_outlined,
              color: Colors.brown.shade400,
            ),
            const SizedBox(height: 16),

            // 7. Colour Density Chart
            _buildChartCard(
              context,
              title: 'Colour Density',
              icon: Icons.color_lens_outlined,
              color: Colors.lime.shade600,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
