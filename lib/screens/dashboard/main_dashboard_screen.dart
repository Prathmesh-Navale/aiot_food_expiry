import 'package:flutter/material.dart';

class MainDashboardScreen extends StatelessWidget {
  final Function(String, String) onNavigate;

  const MainDashboardScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome, Manager',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold, 
              color: const Color(0xFF00C853)
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Maximize Shelf Life. Minimize Waste Line.',
            style: TextStyle(color: Colors.grey, fontSize: 16, fontStyle: FontStyle.italic),
          ),
          const Divider(height: 30, color: Colors.white24),

          LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  _buildCard(context, 'Sales Visualization', Icons.ssid_chart, Colors.blue, '/sales-dashboard'),
                  _buildCard(context, 'Stock Entry', Icons.scanner_outlined, const Color(0xFF00C853), '/stock-options'),
                  _buildCard(context, 'Discounts & Alerts', Icons.discount, Colors.orange, '/alerts-discounts'),
                  _buildCard(context, 'Donation Management', Icons.volunteer_activism, Colors.red, '/donation'),
                  _buildCard(context, 'Productivity', Icons.insights, Colors.teal, '/productivity'),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, String title, IconData icon, Color color, String route) {
    return Card(
      color: const Color(0xFF1E1E1E),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: color.withOpacity(0.3))),
      child: InkWell(
        onTap: () => onNavigate(route, title),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 32, color: color),
              Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}