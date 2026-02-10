import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

// ==========================================
// 1. DATA MODEL
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

class _DonationScreenState extends State<DonationScreen> with SingleTickerProviderStateMixin {
  // Use the apiService method instead of hardcoded URL if available, 
  // otherwise fallback to the service's base URL logic.
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

  Future<void> _fetchDonations() async {
    setState(() => _isLoading = true);
    try {
      // Use the raw discount fetcher from API service to reuse logic
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

  void _removeItem(int index) {
    setState(() {
      final item = _donationList[index];
      totalValue -= (item.currentStock * item.markedPrice);
      totalMeals -= item.currentStock;
      _donationList.removeAt(index);
    });
  }

  void _processDonation() {
    if (_selectedNGO == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Select a partner to proceed."),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade800,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    // Show Loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context); // Close loader
      
      // Show Success Receipt
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Container(
          padding: const EdgeInsets.all(30),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF00C853), size: 60),
              const SizedBox(height: 15),
              const Text("Manifest Generated", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 10),
              Text("Your donation to $_selectedNGO has been logged and sent to accounting.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx); 
                    setState(() {
                      _donationList.clear(); 
                      totalValue = 0;
                      totalMeals = 0;
                    });
                    widget.refreshHome();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C853),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("DONE", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              )
            ],
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Stack(
        children: [
          Column(
            children: [
              // 1. UNIQUE CURVED HEADER
              _buildAnimatedHeader(),

              // 2. NGO SELECTOR
              if (_donationList.isNotEmpty)
                Transform.translate(
                  offset: const Offset(0, -25),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.red.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8))
                      ],
                    ),
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: "Select NGO / Partner",
                        labelStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                        icon: Icon(Icons.handshake, color: Color(0xFFD32F2F)),
                      ),
                      value: _selectedNGO,
                      items: _ngoPartners.map((ngo) {
                        return DropdownMenuItem(value: ngo, child: Text(ngo, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)));
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
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100), // Bottom padding for floating bar
                            itemCount: _donationList.length,
                            itemBuilder: (context, index) {
                              return _buildDismissibleItem(index);
                            },
                          ),
              ),
            ],
          ),

          // 4. FLOATING ACTION BAR
          if (_donationList.isNotEmpty)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: _buildFloatingActionBar(),
            )
        ],
      ),
    );
  }

  Widget _buildAnimatedHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 50),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFB71C1C), Color(0xFFE53935)],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                        child: const Icon(Icons.volunteer_activism, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Text("IMPACT DASHBOARD", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Animated Counter
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: totalValue),
                    duration: const Duration(seconds: 2),
                    curve: Curves.easeOutExpo,
                    builder: (context, value, child) {
                      return Text(
                        "\$${value.toStringAsFixed(0)}",
                        style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w900, height: 1.0),
                      );
                    },
                  ),
                  const Text("Tax Deductible Value", style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
              
              // Meals Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.restaurant_menu, color: Colors.white, size: 22),
                    const SizedBox(height: 4),
                    TweenAnimationBuilder<int>(
                      tween: IntTween(begin: 0, end: totalMeals),
                      duration: const Duration(seconds: 2),
                      builder: (context, val, child) => Text("$val", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    const Text("Meals", style: TextStyle(color: Colors.white70, fontSize: 10)),
                  ],
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDismissibleItem(int index) {
    final item = _donationList[index];
    return Dismissible(
      key: Key(item.productName + index.toString()),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) => _removeItem(index),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.delete, color: Colors.red.shade800),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Text(item.productName[0], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFD32F2F)))),
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.productName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.timer, size: 12, color: Colors.orange[800]),
                      const SizedBox(width: 4),
                      Text("Expires in ${item.remainingLife} days", style: TextStyle(color: Colors.orange[800], fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
            // Values
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("${item.currentStock} Units", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                Text("\$${(item.markedPrice * item.currentStock).toStringAsFixed(0)}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionBar() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF263238), // Dark contrast
        borderRadius: BorderRadius.circular(35),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("${_donationList.length} Items Selected", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const Text("Ready for transfer", style: TextStyle(color: Colors.white54, fontSize: 11)),
            ],
          ),
          ElevatedButton(
            onPressed: _processDonation,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF263238),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text("GENERATE", style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 20)]),
            child: const Icon(Icons.check, size: 50, color: Colors.green),
          ),
          const SizedBox(height: 24),
          const Text("Zero Waste Achieved!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 8),
          const Text("No items require donation at this moment.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}