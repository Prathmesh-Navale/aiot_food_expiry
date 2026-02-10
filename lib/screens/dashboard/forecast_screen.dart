// lib/screens/dashboard/forecast_screen.dart

import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ForecastScreen extends StatefulWidget {
  final ApiService apiService;
  const ForecastScreen({super.key, required this.apiService});

  @override
  State<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends State<ForecastScreen> {
  List<dynamic> allProducts = [];
  List<dynamic> filteredProducts = [];
  
  bool isLoading = false;
  String errorMessage = "";
  TextEditingController searchController = TextEditingController();
  
  int totalProjectedUnits = 0;
  DateTime lastUpdated = DateTime.now();

  @override
  void initState() {
    super.initState();
    fetchPredictions();
  }

  void _filterProducts(String query) {
    if (query.isEmpty) {
      setState(() => filteredProducts = allProducts);
    } else {
      setState(() {
        filteredProducts = allProducts.where((item) {
          final name = item['product'].toString().toLowerCase();
          return name.contains(query.toLowerCase());
        }).toList();
      });
    }
  }

  void _calculateMetrics() {
    int units = 0;
    for (var item in allProducts) {
      units += (item['recommended_order'] as int);
    }
    setState(() {
      totalProjectedUnits = units;
      lastUpdated = DateTime.now();
    });
  }

  Future<void> fetchPredictions() async {
    if (mounted) setState(() => isLoading = true);

    try {
      // ✅ FIXED: Use apiService
      final data = await widget.apiService.getForecast();

      if (mounted) {
        setState(() {
          allProducts = data;
          filteredProducts = data;
          errorMessage = "";
          isLoading = false;
        });
        _calculateMetrics();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = "Unable to sync with AI Core.\nServer unreachable.";
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      body: Column(
        children: [
          _buildProfessionalHeader(),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
                : errorMessage.isNotEmpty
                    ? Center(child: Text(errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)))
                    : filteredProducts.isEmpty 
                      ? const Center(child: Text("No products found", style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 10, bottom: 80),
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            final item = filteredProducts[index];
                            return ProfessionalProductCard(
                              name: item['product'],
                              orderQty: item['recommended_order'],
                              saved: item['waste_saved'],
                            );
                          },
                        ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 25),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Inventory Forecast", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF1A237E))), IconButton(icon: const Icon(Icons.refresh, color: Colors.grey), onPressed: fetchPredictions)]),
          const SizedBox(height: 4),
          Text("Updated Today • $totalProjectedUnits Units to Order", style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
          const SizedBox(height: 20),
          Container(
            height: 50,
            decoration: BoxDecoration(color: const Color(0xFFF1F3F6), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
            child: TextField(
              controller: searchController,
              onChanged: _filterProducts,
              style: const TextStyle(color: Colors.black87),
              decoration: const InputDecoration(hintText: "Search product...", hintStyle: TextStyle(color: Colors.grey), prefixIcon: Icon(Icons.search, color: Colors.grey), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 15)),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfessionalProductCard extends StatelessWidget {
  final String name;
  final int orderQty;
  final int saved;

  const ProfessionalProductCard({super.key, required this.name, required this.orderQty, required this.saved});

  @override
  Widget build(BuildContext context) {
    bool isSaving = saved > 0;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Row(
        children: [
          Container(width: 45, height: 45, decoration: BoxDecoration(color: const Color(0xFFE8EAF6), borderRadius: BorderRadius.circular(8)), child: Center(child: Text(name[0], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))))),
          const SizedBox(width: 15),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)), const SizedBox(height: 4), Row(children: [Icon(isSaving ? Icons.trending_down : Icons.check_circle, size: 14, color: isSaving ? Colors.green : Colors.blueGrey), const SizedBox(width: 4), Text(isSaving ? "Saved $saved Units" : "Standard Order", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSaving ? Colors.green.shade700 : Colors.blueGrey))])])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text("ORDER", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey.shade400)), Text("$orderQty", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1A237E)))]),
        ],
      ),
    );
  }
}