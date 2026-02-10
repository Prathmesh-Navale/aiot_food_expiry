import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/product.dart';

class DonationScreen extends StatefulWidget {
  final ApiService apiService;
  final VoidCallback refreshHome;

  const DonationScreen({super.key, required this.apiService, required this.refreshHome});

  @override
  State<DonationScreen> createState() => _DonationScreenState();
}

class _DonationScreenState extends State<DonationScreen> {
  List<Product> _donationList = [];
  bool _isLoading = true;
  double totalValue = 0;

  // NGO/Partner Selection
  final List<String> _ngoPartners = ["City Food Bank", "Homeless Shelter HQ", "ZeroWaste Community"];
  String? _selectedNGO;

  @override
  void initState() {
    super.initState();
    _fetchDonations();
  }

  Future<void> _fetchDonations() async {
    setState(() => _isLoading = true);
    try {
      final allProducts = await widget.apiService.fetchProducts();
      List<Product> candidates = [];

      for (var p in allProducts) {
        bool shouldDonate = false;

        // Rule 1: Expires in 4 days or less
        if (p.daysToExpiry <= 4 && p.status != 'Donated') {
          shouldDonate = true;
        } 
        // Rule 2: High Discount (> 70%) means AI recommends donation
        else if (p.daysToExpiry <= 30 && p.status != 'Donated') { 
           try {
             final result = await widget.apiService.calculateDiscount(p);
             double discount = result['discount_percentage'] ?? 0.0;
             if (discount > 70.0) {
               shouldDonate = true;
             }
           } catch (e) { /* ignore calculation errors */ }
        }

        if (shouldDonate) {
          candidates.add(p);
        }
      }

      double tempValue = 0;
      for (var item in candidates) tempValue += (item.quantity * item.initialPrice);

      if (mounted) {
        setState(() {
          _donationList = candidates;
          totalValue = tempValue;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsDonated(String id) async {
    await widget.apiService.deleteProduct(id);
    _fetchDonations(); // Refresh list
  }

  void _generateManifest() {
    if (_selectedNGO == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select an NGO Partner")));
      return;
    }
    // Logic to generate manifest would go here
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Manifest generated for $_selectedNGO")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC), // Professional Light Grey (Matches Productivity)
      body: Column(
        children: [
          // --- RED HEADER (Kept for Context) ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
            decoration: const BoxDecoration(
              color: Color(0xFFD32F2F),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))]
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("TOTAL WRITE-OFF VALUE", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 4),
                Text("\$${totalValue.toStringAsFixed(0)}", style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                // Partner Selection inside Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: const Text("Select Logistics / NGO Partner", style: TextStyle(color: Colors.grey, fontSize: 14)),
                      value: _selectedNGO,
                      icon: const Icon(Icons.local_shipping, color: Color(0xFFD32F2F)),
                      items: _ngoPartners.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() => _selectedNGO = v),
                    ),
                  ),
                )
              ],
            ),
          ),

          // --- PRODUCTIVITY-STYLE LIST ---
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFD32F2F)))
                : _donationList.isEmpty
                    ? const Center(child: Text("No Pending Donations", style: TextStyle(fontSize: 16, color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 16, bottom: 80),
                        itemCount: _donationList.length,
                        itemBuilder: (context, index) {
                          final p = _donationList[index];
                          return _buildProductivityStyleCard(p);
                        },
                      ),
          ),
        ],
      ),
      
      // Floating Action Button for Manifest
      floatingActionButton: _donationList.isNotEmpty 
        ? FloatingActionButton.extended(
            onPressed: _generateManifest,
            backgroundColor: const Color(0xFFD32F2F),
            icon: const Icon(Icons.receipt_long, color: Colors.white),
            label: const Text("GENERATE MANIFEST", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        : null,
    );
  }

  // --- THE NEW CARD STYLE (Matches Productivity GUI) ---
  Widget _buildProductivityStyleCard(Product item) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200), // Subtle border like Productivity
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          // 1. Leading Icon (Rounded Square)
          Container(
            width: 45, height: 45,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE), // Light Red (instead of Indigo)
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                item.productName.isNotEmpty ? item.productName[0] : '?', 
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFD32F2F))
              )
            ),
          ),
          
          const SizedBox(width: 15),
          
          // 2. Main Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName, 
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)
                ),
                const SizedBox(height: 4),
                // Status Row (Similar to "Saved X Units")
                Row(
                  children: [
                    const Icon(Icons.access_time_filled, size: 14, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text(
                      "Expires in ${item.daysToExpiry} days",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.orange.shade800),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 3. Trailing Info & Action
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Value display (Matches "ORDER" style)
              Text("VALUE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey.shade400)),
              Text(
                "\$${(item.initialPrice * item.quantity).toStringAsFixed(0)}", 
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF263238))
              ),
              const SizedBox(height: 4),
              // Compact Log Button
              SizedBox(
                height: 28,
                child: ElevatedButton(
                  onPressed: () => _markAsDonated(item.id!),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFD32F2F),
                    elevation: 0,
                    side: const BorderSide(color: Color(0xFFD32F2F), width: 1),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)
                  ),
                  child: const Text("LOG"),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}