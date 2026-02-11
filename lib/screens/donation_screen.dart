import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

// ==========================================
// 1. ROBUST DATA MODEL
// ==========================================
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
    // Robust parsing handles both Python naming conventions (Snake_case / PascalCase)
    return DonationItem(
      productName: json['product_name'] ?? json['Product_Name'] ?? 'Unknown',
      currentStock: json['current_stock'] ?? json['Stock_Quantity'] ?? 0,
      markedPrice: (json['marked_price'] ?? 0).toDouble(),
      remainingLife: (json['remaining_life'] ?? json['Days_Until_Expiry'] ?? 0).toInt(),
      actionStatus: json['action_status'] ?? json['Action_Status'] ?? 'Keep Price',
    );
  }
}

// ==========================================
// 2. MAIN SCREEN
// ==========================================
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
  // CONFIG: Connects to your Discount API
  final String apiUrl = "http://127.0.0.1:5000/api/discounts";
  
  List<DonationItem> _donationList = [];
  bool _isLoading = true;
  String? _selectedNGO; 
  
  // Metrics
  double totalValue = 0;
  int totalMeals = 0; 

  final List<String> _ngoPartners = [
    "City Food Bank",
    "Homeless Shelter HQ",
    "ZeroWaste Community",
    "Orphanage Trust"
  ];

  @override
  void initState() {
    super.initState();
    _fetchDonations();
  }

  // --- FETCH & FILTER LOGIC ---
  Future<void> _fetchDonations() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        
        // FILTER: Keep ONLY items marked "DONATE"
        List<DonationItem> allItems = body
            .map((item) => DonationItem.fromJson(item))
            .where((item) => item.actionStatus == "DONATE") 
            .toList();

        // CALCULATE IMPACT
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
      } else {
        throw Exception("Server Error");
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint("Error fetching donations: $e");
    }
  }

  // --- SUBMIT LOGIC ---
  void _processDonation() {
    if (_selectedNGO == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select an NGO partner to generate the manifest."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 1. Loading State
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    // 2. Simulate API Call
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context); // Close loader
      
      // 3. Success Receipt
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Column(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 50),
              SizedBox(height: 10),
              Text("Transfer Initiated", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Partner: $_selectedNGO", style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Divider(),
              _buildReceiptRow("Items Donated", "${_donationList.length}"),
              _buildReceiptRow("Total Meals", "$totalMeals"),
              _buildReceiptRow("Tax Write-off", "\$${totalValue.toStringAsFixed(0)}"),
              const Divider(),
              const SizedBox(height: 10),
              const Text("A copy of this manifest has been sent to accounting.", style: TextStyle(fontSize: 11, color: Colors.grey), textAlign: TextAlign.center),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx); 
                setState(() {
                  _donationList.clear(); 
                  totalValue = 0;
                  totalMeals = 0;
                });
                widget.refreshHome(); // Refresh dashboard counts
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text("Close"),
            )
          ],
        ),
      );
    });
  }

  Widget _buildReceiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      // No AppBar - We build a custom unified header
      body: Column(
        children: [
          // 1. UNIFIED HEADER (Replaces AppBar + Info Card)
          _buildUnifiedHeader(),

          // 2. PARTNER SELECTOR (Floating Card style)
          if (_donationList.isNotEmpty)
            Transform.translate(
              offset: const Offset(0, -20), // Pull up slightly to overlap header
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
                ),
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: "Select Logistics / NGO Partner",
                    border: InputBorder.none,
                    icon: Icon(Icons.local_shipping, color: Color(0xFFD32F2F)),
                  ),
                  value: _selectedNGO,
                  items: _ngoPartners.map((ngo) {
                    return DropdownMenuItem(value: ngo, child: Text(ngo, style: const TextStyle(fontWeight: FontWeight.bold)));
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedNGO = val),
                ),
              ),
            ),

          // 3. LIST CONTENT
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFD32F2F)))
                : _donationList.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: _donationList.length,
                        itemBuilder: (context, index) {
                          return _buildDonationCard(_donationList[index]);
                        },
                      ),
          ),

          // 4. BOTTOM ACTION BAR
          if (_donationList.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _processDonation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:  Color.fromARGB(255, 239, 16, 38),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                    ),
                    child: const Text(
                      "GENERATE MANIFEST", 
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2, color: Colors.white)
                    ),
                  ),
                ),
              ),
            )
        ],
      ),
    );
  }

  // --- NEW UNIFIED HEADER WIDGET ---
  Widget _buildUnifiedHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 10), // Top padding handles Status Bar
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color.fromARGB(255, 239, 16, 38), Color.fromARGB(255, 246, 11, 27)], // Professional Deep Red Gradient
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Navigation Row
           
          // Metrics Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("TOTAL WRITE-OFF VALUE", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    "\$${totalValue.toStringAsFixed(0)}",
                    style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              // Meal Counter Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.restaurant, color: Colors.white, size: 20),
                    const SizedBox(height: 4),
                    Text(
                      "$totalMeals Meals", 
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)
                    ),
                  ],
                ),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          // Product Image Placeholder
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE), // Light Red
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                item.productName[0], 
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFD32F2F))
              )
            ),
          ),
          const SizedBox(width: 16),
          
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0), // Light Orange
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time_filled, size: 12, color: Colors.deepOrange),
                      const SizedBox(width: 4),
                      Text("Expires in ${item.remainingLife} days", style: const TextStyle(color: Colors.deepOrange, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Qty & Value
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("${item.currentStock} Units", style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF263238))),
              const SizedBox(height: 4),
              Text(
                "Value: \$${(item.markedPrice * item.currentStock).toStringAsFixed(0)}", 
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500)
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          Text("No Pending Donations", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
          const SizedBox(height: 10),
          Text("Inventory levels are currently optimized.", style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}