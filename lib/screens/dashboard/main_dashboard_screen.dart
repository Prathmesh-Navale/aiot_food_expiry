// lib/screens/dashboard/main_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// --- NEW UNSTOP-INSPIRED DASHBOARD CARD ---

class UnstopInspiredCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const UnstopInspiredCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Card(
        elevation: 10,
        color: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: InkWell(
          onTap: () {
            print('DEBUG: Dashboard Card Tapped: Navigating to $title');
            onTap();
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(icon, size: 30, color: color),
                    const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: color,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- MAIN DASHBOARD SCREEN (Landing Page) ---
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
            'Welcome, Store-1 Manager',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 32, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: 5),
          const Text(
            'Maximize Shelf Life. Minimize Waste Line.',
            style: TextStyle(color: Colors.grey, fontSize: 18, fontStyle: FontStyle.italic),
          ),
          const Divider(height: 40),

          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 1000 ? 3 : (constraints.maxWidth > 600 ? 2 : 1);
              final cardHeight = crossAxisCount == 1 ? 160.0 : 220.0;

              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: constraints.maxWidth / (crossAxisCount * cardHeight),
                children: [
                  UnstopInspiredCard(
                      title: 'Sales Visualization',
                      subtitle: 'Track revenue, units sold, and top-performing products.',
                      icon: Icons.ssid_chart,
                      color: Colors.blue.shade400,
                      onTap: () => onNavigate('/sales-dashboard', 'Sales Visualization')
                  ),
                  UnstopInspiredCard(
                      title: 'Stock Entry',
                      subtitle: 'Scan, Add, and manage new inventory with automatic data validation.',
                      icon: Icons.scanner_outlined,
                      color: Theme.of(context).colorScheme.primary,
                      onTap: () => onNavigate('/stock-options', 'Stock Entry')
                  ),
                  UnstopInspiredCard(
                      title: 'Discounts & Alerts',
                      subtitle: 'Dynamic pricing suggestions based on AI expiry forecasting.',
                      icon: Icons.discount,
                      color: Colors.orange.shade600,
                      onTap: () => onNavigate('/alerts-discounts', 'Dynamic Discounting & Alerts')
                  ),
                  UnstopInspiredCard(
                      title: 'Donation Management',
                      subtitle: 'Direct items within 4 days of expiry to donation partners.',
                      icon: Icons.volunteer_activism,
                      color: Colors.red.shade400,
                      onTap: () => onNavigate('/donation', 'Donation Management')
                  ),
                  UnstopInspiredCard(
                      title: 'Productivity',
                      subtitle: 'AI sales forecasting, ordering optimization, and waste reports.',
                      icon: Icons.insights,
                      color: Colors.teal,
                      onTap: () => onNavigate('/productivity', 'Productivity Management')
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}