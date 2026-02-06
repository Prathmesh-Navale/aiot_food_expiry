// lib/screens/dashboard/productivity_screen.dart

import 'package:flutter/material.dart';
import 'package:aiot_ui/services/api_service.dart';
import 'package:aiot_ui/models/product.dart';
import 'dart:math' as math;

// Data model for the pie chart
class PieData {
  final String title;
  final double value;
  final Color color;
  PieData({required this.title, required this.value, required this.color});
}

// Widget for Pie Chart Visualization (Simulation)
class SalesPieChart extends StatelessWidget {
  final List<PieData> data;
  final double totalValue;

  const SalesPieChart({required this.data, required this.totalValue, super.key});

  @override
  Widget build(BuildContext context) {
    final nonZeroData = data.where((d) => d.value > 0).toList();
    if (nonZeroData.isEmpty) {
      return const Center(child: Text('No revenue data to display.', style: TextStyle(color: Colors.grey)));
    }

    return Row(
      children: [
        // 1. Pie Chart Area (Takes 50% of the width)
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: CustomPaint(
              size: const Size.square(double.infinity),
              painter: PieChartPainter(nonZeroData, totalValue),
            ),
          ),
        ),

        // 2. Legend (Takes 50% of the width)
        Expanded(
          flex: 5,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: nonZeroData.map((d) => _buildLegendItem(context, d, totalValue)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(BuildContext context, PieData data, double total) {
    final percentage = (data.value / total) * 100;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: data.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${data.title}: ${percentage.toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter to draw the pie chart segments
class PieChartPainter extends CustomPainter {
  final List<PieData> data;
  final double totalValue;

  PieChartPainter(this.data, this.totalValue);

  @override
  void paint(Canvas canvas, Size size) {
    double startAngle = -math.pi / 2; // Start from 12 o'clock

    for (var d in data) {
      final sweepAngle = (d.value / totalValue) * 2 * math.pi;

      final paint = Paint()
        ..color = d.color
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: size.center(Offset.zero), radius: size.width / 2),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      final borderPaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawArc(
        Rect.fromCircle(center: size.center(Offset.zero), radius: size.width / 2),
        startAngle,
        sweepAngle,
        true,
        borderPaint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant PieChartPainter oldDelegate) {
    return oldDelegate.totalValue != totalValue;
  }
}

// Widget for KPI Cards
class ValueCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const ValueCard({required this.title, required this.value, required this.icon, required this.color, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        constraints: const BoxConstraints(minWidth: 140, maxWidth: 300),
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(title, style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// --- PRODUCTIVITY MANAGEMENT SCREEN ---
class ProductivityManagementScreen extends StatelessWidget {
  final ApiService apiService;

  const ProductivityManagementScreen({super.key, required this.apiService});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Product>>(
      future: apiService.fetchProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error loading data: ${snapshot.error}'));
        }

        // --- Data Calculation (Using dummy revenue numbers) ---
        double totalInitialValue = 0.0;
        double discountedValue = 0.0;
        double donatedValue = 0.0;

        for (var p in snapshot.data!) {
          final batchValue = p.initialPrice * p.quantity;

          if (p.status == 'Discount Active') {
            discountedValue += (p.finalPrice * p.quantity);
            totalInitialValue += batchValue;
          } else if (p.daysToExpiry <= 0 || p.status == 'Donated') {
            donatedValue += batchValue;
          } else {
            totalInitialValue += batchValue;
          }
        }

        final fullSalesValue = totalInitialValue * 0.85;
        final totalRevenueTracked = fullSalesValue + discountedValue + donatedValue;

        // --- Pie Chart Data Setup ---
        final pieChartData = [
          PieData(title: 'Full Sales Revenue', value: fullSalesValue, color: Colors.green.shade400),
          PieData(title: 'Discounted Revenue', value: discountedValue, color: Colors.orange.shade400),
          PieData(title: 'Donated/Wasted Value', value: donatedValue, color: Colors.red.shade400),
        ];

        // --- AI Recommendation Logic ---
        String recommendation = 'No major supply chain issues detected. Maintain current ordering levels and monitor seasonal trends.';
        if (donatedValue > totalRevenueTracked * 0.1) {
          recommendation = 'HIGH WASTE ALERT: Inventory loss is significant. Reduce ordering quantity for the top 3 wasted categories (Check Waste Report).';
        } else if (discountedValue > fullSalesValue * 0.3) {
          recommendation = 'DISCOUNT DEPENDENCY: Consider decreasing order quantity by 5% and adjusting initial pricing to test demand elasticity.';
        } else {
          recommendation = 'SUCCESS: Sales and waste metrics are healthy. Maintain current ordering levels.';
        }

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
          children: [
            Text(
              'Predictive Supply Chain & Productivity',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 2.0),
              child: Text(
                'Optimization based on long-term trends and the effectiveness of previous inventory strategies (The Feedback Loop).',
                style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
              ),
            ),
            const Divider(height: 10),

            // --- Sales Visualization / KPI Cards (Kept for Summary) ---
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ValueCard(
                  title: 'Total Revenue',
                  value: '\$${(fullSalesValue + discountedValue).toStringAsFixed(0)}',
                  icon: Icons.attach_money,
                  color: Colors.green.shade400,
                ),
                ValueCard(
                  title: 'Discounted Value',
                  value: '\$${discountedValue.toStringAsFixed(0)}',
                  icon: Icons.local_offer,
                  color: Colors.orange.shade400,
                ),
                ValueCard(
                  title: 'Donated/Wasted Value',
                  value: '\$${donatedValue.toStringAsFixed(0)}',
                  icon: Icons.delete_forever,
                  color: Colors.red.shade400,
                ),
              ],
            ),
            const SizedBox(height: 15),

            // --- Visualization (Pie Chart) ---
            Text('Revenue Distribution Visualization', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 5),
            Container(
              height: 200,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 8)],
              ),
              child: SalesPieChart(data: pieChartData, totalValue: totalRevenueTracked),
            ),
            const SizedBox(height: 15),

            // --- Optimal Ordering Generation (AI Recommendation) ---
            Card(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              elevation: 0,
              margin: const EdgeInsets.only(top: 5),
              child: ListTile(
                leading: Icon(donatedValue > totalRevenueTracked * 0.1 ? Icons.warning : Icons.trending_up,
                    color: donatedValue > totalRevenueTracked * 0.1 ? Colors.red : Theme.of(context).colorScheme.primary,
                    size: 40),
                title: Text('AI RECOMMENDATION', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                subtitle: Text(recommendation, style: const TextStyle(fontStyle: FontStyle.italic)),
              ),
            ),
          ],
        );
      },
    );
  }
}