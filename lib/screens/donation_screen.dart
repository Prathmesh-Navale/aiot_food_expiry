// lib/screens/donation_screen.dart

import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DonationItem {
  final String productName;
  final int currentStock;
  final double markedPrice;
  final int remainingLife;
  final String actionStatus;

  DonationItem({
    required this.productName,
    required this.currentStock,
    required this.markedPrice,
    required this.remainingLife,
    required this.actionStatus,
  });

  factory DonationItem.fromJson(Map<String, dynamic> json) {
    return DonationItem(
      productName: json['product_name'] ?? json['Product_Name'] ?? 'Unknown',
      currentStock: json['current_stock'] ?? json['Stock_Quantity'] ?? 0,
      markedPrice: (json['marked_price'] ?? 0).toDouble(),
      remainingLife: (json['remaining_life'] ?? json['Days_Until_Expiry'] ?? 0).toInt(),
      actionStatus: json['action_status'] ?? json['Action_Status'] ?? 'Keep Price',
    );
  }
}

class DonationScreen extends StatefulWidget {
  final ApiService apiService;
  final VoidCallback refreshHome;

  const DonationScreen({
    super.key,
    required this.apiService,
    required this.refreshHome,
  });

  @override
  State<DonationScreen> createState() => _DonationScreenState();
}

class _DonationScreenState extends State<DonationScreen> {
  List<DonationItem> _donationList = [];
  bool _isLoading = true;
  String? _selectedNGO; 
  
  double totalValue = 0;
  int totalMeals = 0; 

  final List<String> _ngoPartners = ["City Food Bank", "Homeless Shelter HQ", "ZeroWaste Community", "Orphanage Trust"];

  @override
  void initState() {
    super.initState();
    _fetchDonations();
  }

  Future<void> _fetchDonations() async {
    setState(() => _isLoading = true);
    try {
      // ✅ FIXED: Uses apiService instead of hardcoded URL
      final body = await widget.apiService.getDiscountsRaw();
      
      // FILTER: Keep ONLY items marked "DONATE"
      List<DonationItem> allItems = body
          .map((item) => DonationItem.fromJson(item))
          .where((item) => item.actionStatus == "DONATE") 
          .toList();

      double tempValue = 0;
      int tempStock = 0;
      for (var item in allItems) {
        tempValue += (item.currentStock * item.markedPrice);
        tempStock += item.currentStock;
      }

      if (mounted) {
        setState(() {
          _donationList = allItems;
          totalValue = tempValue;
          totalMeals = tempStock; 
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint("Error fetching donations: $e");
    }
  }

  void _processDonation() {
    if (_selectedNGO == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an NGO partner."), backgroundColor: Colors.red),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context); // Close loader
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Column(children: [Icon(Icons.check_circle, color: Colors.green, size: 50), SizedBox(height: 10), Text("Transfer Initiated", style: TextStyle(fontWeight: FontWeight.bold))]),
          content: Text("A copy of this manifest has been sent to accounting.\nPartner: $_selectedNGO", textAlign: TextAlign.center),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx); 
                setState(() { _donationList.clear(); totalValue = 0; totalMeals = 0; });
                widget.refreshHome();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text("Close"),
            )
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          _buildUnifiedHeader(),
          if (_donationList.isNotEmpty)
            Transform.translate(
              offset: const Offset(0, -20),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))]),
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: "Select Logistics / NGO Partner", border: InputBorder.none, icon: Icon(Icons.local_shipping, color: Color(0xFFD32F2F))),
                  value: _selectedNGO,
                  items: _ngoPartners.map((ngo) => DropdownMenuItem(value: ngo, child: Text(ngo, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
                  onChanged: (val) => setState(() => _selectedNGO = val),
                ),
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFD32F2F)))
                : _donationList.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: _donationList.length,
                        itemBuilder: (context, index) => _buildDonationCard(_donationList[index]),
                      ),
          ),
          if (_donationList.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _processDonation,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text("GENERATE MANIFEST", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2, color: Colors.white)),
                  ),
                ),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildUnifiedHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("TOTAL WRITE-OFF VALUE", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text("\$${totalValue.toStringAsFixed(0)}", style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.2))),
                child: Column(children: [const Icon(Icons.restaurant, color: Colors.white, size: 20), const SizedBox(height: 4), Text("$totalMeals Meals", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))]),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDonationCard(DonationItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        children: [
          Container(width: 56, height: 56, decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(12)), child: Center(child: Text(item.productName[0], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFD32F2F))))),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.productName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)), const SizedBox(height: 6), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(6)), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.access_time_filled, size: 12, color: Colors.deepOrange), const SizedBox(width: 4), Text("Expires in ${item.remainingLife} days", style: const TextStyle(color: Colors.deepOrange, fontSize: 11, fontWeight: FontWeight.bold))]))])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text("${item.currentStock} Units", style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF263238))), const SizedBox(height: 4), Text("Value: \$${(item.markedPrice * item.currentStock).toStringAsFixed(0)}", style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500))]),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.check_circle_outline, size: 80, color: Colors.grey.shade300), const SizedBox(height: 20), Text("No Pending Donations", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade600))]));
  }
}