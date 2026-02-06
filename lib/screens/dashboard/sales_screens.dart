// lib/screens/dashboard/sales_screens.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; 
import 'package:http/http.dart' as http;
import '../../services/api_service.dart';

class SalesDashboardScreen extends StatefulWidget {
  final ApiService apiService;
  final Function(String, String) onNavigate;

  const SalesDashboardScreen({
    super.key,
    required this.apiService,
    required this.onNavigate,
  });

  @override
  State<SalesDashboardScreen> createState() => _SalesDashboardScreenState();
}

class _SalesDashboardScreenState extends State<SalesDashboardScreen> {
  bool _isLoading = true;
  double totalRevenue = 0;
  int totalUnits = 0;
  List<Map<String, dynamic>> topProducts = [];

  // CONFIG: Connects to your new MongoDB Aggregation Route
  final String apiUrl = "http://127.0.0.1:5000/api/sales-stats";

  @override
  void initState() {
    super.initState();
    _fetchSalesData();
  }

  Future<void> _fetchSalesData() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            totalRevenue = (data['total_revenue'] ?? 0).toDouble();
            totalUnits = (data['total_units'] ?? 0).toInt();
            topProducts = List<Map<String, dynamic>>.from(data['top_products'] ?? []);
            _isLoading = false;
          });
        }
      } else {
        throw Exception("Failed to load sales data: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching sales data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Professional Dark Theme Colors
    const Color bgDark = Color(0xFF121212);
    const Color cardDark = Color(0xFF1E1E1E);
    const Color accentBlue = Color(0xFF2979FF);

    return Scaffold(
      backgroundColor: bgDark,
      // Custom Dark App Bar
      appBar: AppBar(
         
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchSalesData();
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: accentBlue))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. SUMMARY CARDS ROW
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          "Total Revenue",
                          "\$${totalRevenue.toStringAsFixed(0)}",
                          Icons.attach_money,
                          const [Color(0xFF00C853), Color(0xFF69F0AE)], // Green Gradient
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSummaryCard(
                          "Units Sold",
                          "$totalUnits",
                          Icons.shopping_bag,
                          const [Color(0xFF2979FF), Color(0xFF82B1FF)], // Blue Gradient
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // 2. CHART SECTION
                  const Text(
                    "Top Performing Products",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white70),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    height: 320,
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
                    decoration: BoxDecoration(
                      color: cardDark,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white10),
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: topProducts.isEmpty
                        ? const Center(child: Text("No sales data available", style: TextStyle(color: Colors.grey)))
                        : BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: (topProducts.first['value'] as int).toDouble() * 1.2, // Dynamic Max Y
                              barTouchData: BarTouchData(
                                enabled: true,
                                touchTooltipData: BarTouchTooltipData(
                                  // --- FIX: Using tooltipBgColor for v0.66.2 ---
                                  tooltipBgColor: Colors.blueGrey.shade900,
                                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                    String productName = topProducts[group.x.toInt()]['name'];
                                    return BarTooltipItem(
                                      "$productName\n",
                                      const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      children: [
                                        TextSpan(
                                          text: (rod.toY.toInt()).toString(),
                                          style: const TextStyle(color: accentBlue),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 40,
                                    getTitlesWidget: (value, meta) {
                                      if (value.toInt() >= 0 && value.toInt() < topProducts.length) {
                                        // Show first letter of product name as label
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8.0),
                                          child: Text(
                                            topProducts[value.toInt()]['name'][0],
                                            style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                        );
                                      }
                                      return const SizedBox();
                                    },
                                  ),
                                ),
                                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              borderData: FlBorderData(show: false),
                              gridData: const FlGridData(show: false),
                              barGroups: topProducts.asMap().entries.map((entry) {
                                return BarChartGroupData(
                                  x: entry.key,
                                  barRods: [
                                    BarChartRodData(
                                      toY: (entry.value['value'] as int).toDouble(),
                                      color: accentBlue,
                                      width: 22,
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                      // Note: backDrawRodData might also need adjustment if 0.66.2 differs, 
                                      // but usually rodStackItems is the complex part. 
                                      // Simpler background rod logic:
                                      backDrawRodData: BackgroundBarChartRodData(
                                        show: true,
                                        toY: (topProducts.first['value'] as int).toDouble() * 1.2,
                                        color: Colors.white.withOpacity(0.05),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                  ),

                  const SizedBox(height: 30),

                  // 3. DETAILED LIST
                  const Text(
                    "Performance Breakdown",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  ...topProducts.map((product) => _buildListTile(product, cardDark)),
                  
                  const SizedBox(height: 50), // Bottom Padding
                ],
              ),
            ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildSummaryCard(String title, String value, IconData icon, List<Color> gradient) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: gradient.last.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildListTile(Map<String, dynamic> product, Color cardColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.1), 
                  borderRadius: BorderRadius.circular(12)
                ),
                child: Center(
                  child: Text(
                    product['name'].isNotEmpty ? product['name'][0] : "?", 
                    style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 18)
                  )
                ),
              ),
              const SizedBox(width: 16),
              Text(
                product['name'], 
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)
              ),
            ],
          ),
          Row(
            children: [
              Text(
                "${product['value']}", 
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
              ),
              const SizedBox(width: 4),
              const Text("sold", style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}