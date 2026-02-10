import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/api_service.dart';

class SalesDashboardScreen extends StatefulWidget {
  final ApiService apiService;
  final Function(String, String) onNavigate;

  const SalesDashboardScreen({super.key, required this.apiService, required this.onNavigate});

  @override
  State<SalesDashboardScreen> createState() => _SalesDashboardScreenState();
}

class _SalesDashboardScreenState extends State<SalesDashboardScreen> {
  bool _isLoading = true;
  double totalRevenue = 0;
  int totalUnits = 0;
  List<Map<String, dynamic>> topProducts = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final data = await widget.apiService.getSalesStats();
    if (mounted) {
      setState(() {
        totalRevenue = (data['total_revenue'] ?? 0).toDouble();
        totalUnits = (data['total_units'] ?? 0).toInt();
        topProducts = List<Map<String, dynamic>>.from(data['top_products'] ?? []);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading 
      ? const Center(child: CircularProgressIndicator()) 
      : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _summaryCard("Revenue", "\$${totalRevenue.toStringAsFixed(0)}", Colors.green)),
                  const SizedBox(width: 16),
                  Expanded(child: _summaryCard("Units Sold", "$totalUnits", Colors.blue)),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                height: 300,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(16)),
                child: BarChart(
                  BarChartData(
                    barGroups: topProducts.asMap().entries.map((e) {
                      return BarChartGroupData(x: e.key, barRods: [BarChartRodData(toY: (e.value['value'] as int).toDouble(), color: Colors.blue)]);
                    }).toList(),
                    titlesData: FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
            ],
          ),
        );
  }

  Widget _summaryCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.5))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: Colors.grey)),
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
      ]),
    );
  }
}