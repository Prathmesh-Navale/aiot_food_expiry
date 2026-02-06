import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ==========================================
// 1. DATA MODEL (Robust Parsing)
// ==========================================
class DiscountProduct {
  final String productName;
  final int currentStock;
  final double markedPrice;
  final int remainingLife;
  
  // Financial Metrics
  final double revenueAfter;
  final double lossAfter;

  // AI Decision Fields
  final double discountPct;
  final double finalPrice;
  final String actionStatus; // "DONATE", "Critical Clearance", "Flash Sale", etc.
  final int soldAfter;

  DiscountProduct({
    required this.productName,
    required this.currentStock,
    required this.markedPrice,
    required this.remainingLife,
    required this.revenueAfter,
    required this.lossAfter,
    required this.discountPct,
    required this.finalPrice,
    required this.actionStatus,
    required this.soldAfter,
  });

  factory DiscountProduct.fromJson(Map<String, dynamic> json) {
    // ------------------------------------------------------------------
    // GENUINE LOGIC: Handles inconsistent keys from Python (Snake_case vs PascalCase)
    // ------------------------------------------------------------------
    return DiscountProduct(
      productName: json['product_name'] ?? json['Product_Name'] ?? 'Unknown',
      currentStock: json['current_stock'] ?? json['Stock_Quantity'] ?? 0,
      markedPrice: (json['marked_price'] ?? 0).toDouble(),
      remainingLife: (json['remaining_life'] ?? json['Days_Until_Expiry'] ?? 0).toInt(),
      
      // Financials
      revenueAfter: (json['revenue_after'] ?? 0).toDouble(),
      lossAfter: (json['loss_after'] ?? 0).toDouble(),
      
      // The AI Discount %
      discountPct: (json['recommended_discount'] ?? json['Recommended_Discount'] ?? json['final_discount_pct'] ?? 0).toDouble(),
      
      // The Final Price
      finalPrice: (json['final_selling_price'] ?? json['final_price'] ?? 0).toDouble(),
      
      // The Specific Action Strategy
      actionStatus: json['action_status'] ?? json['Action_Status'] ?? 'Keep Price',
      
      soldAfter: (json['sold_after'] ?? 0).toInt(),
    );
  }
}

// ==========================================
// 2. MAIN SCREEN UI
// ==========================================
class DiscountTableScreen extends StatefulWidget {
  const DiscountTableScreen({super.key});

  @override
  State<DiscountTableScreen> createState() => _DiscountTableScreenState();
}

class _DiscountTableScreenState extends State<DiscountTableScreen> {
  // CONFIG: Matches your Flask API
  final String apiUrl = "http://127.0.0.1:5000/api/discounts"; 
  
  late Future<List<DiscountProduct>> _futureProducts;
  
  // Dashboard Totals
  double totalRecoverableRevenue = 0;
  double totalDonationLoss = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _futureProducts = fetchProducts();
    });
  }

  Future<List<DiscountProduct>> fetchProducts() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        List<DiscountProduct> products = body.map((item) => DiscountProduct.fromJson(item)).toList();
        
        // --- GENUINE CALCULATION LOGIC ---
        double tempRev = 0;
        double tempDonate = 0;
        
        for (var p in products) {
          // 1. Sum up Revenue (Money we will actually make)
          tempRev += p.revenueAfter;
          
          // 2. Sum up Donation Value (Cost of goods we are giving away)
          if (p.actionStatus == "DONATE") {
             tempDonate += (p.currentStock * p.markedPrice);
          }
        }

        if (mounted) {
            setState(() {
              totalRecoverableRevenue = tempRev;
              totalDonationLoss = tempDonate;
            });
        }
        return products;
      } else {
        throw Exception('Server Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Connection Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Clean Professional Grey
      appBar: AppBar(
        title: const Text("Profit & Loss Optimization", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF2C3E50), // Corporate Navy
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadData, 
            icon: const Icon(Icons.sync, color: Colors.white),
            tooltip: 'Refresh AI Analysis',
          )
        ],
      ),
      body: Column(
        children: [
          // 1. FINANCIAL SUMMARY
          _buildSummaryHeader(),

          // 2. ACTION LIST
          Expanded(
            child: FutureBuilder<List<DiscountProduct>>(
              future: _futureProducts,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF2C3E50)));
                }
                if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error.toString());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("Inventory is optimized. No actions needed."));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    return _buildGenuineActionCard(snapshot.data![index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF2C3E50),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        children: [
          // Revenue Section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("PROJECTED REVENUE", style: TextStyle(color: Colors.white54, fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(
                  "\$${totalRecoverableRevenue.toStringAsFixed(0)}", 
                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)
                ),
                const Text("from optimization", style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
              ],
            ),
          ),
          Container(height: 50, width: 1, color: Colors.white12),
          const SizedBox(width: 20),
          // Donation Section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text("DONATION WRITE-OFF", style: TextStyle(color: Colors.white54, fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(
                  "\$${totalDonationLoss.toStringAsFixed(0)}", 
                  style: const TextStyle(color: Colors.orangeAccent, fontSize: 28, fontWeight: FontWeight.w800)
                ),
                const Text("tax deductible value", style: TextStyle(color: Colors.orangeAccent, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- GENUINE ACTION CARD LOGIC ---
  Widget _buildGenuineActionCard(DiscountProduct item) {
    // 1. Determine Strategy Colors & Icons based on AI Status
    Color statusColor;
    IconData statusIcon;
    String buttonText;
    String description;
    
    switch (item.actionStatus) {
      case "DONATE":
        statusColor = const Color(0xFFD32F2F); // Red
        statusIcon = Icons.volunteer_activism;
        buttonText = "CONFIRM DONATION";
        description = "Expires soon. Donate to avoid waste.";
        break;
      case "Critical Clearance":
        statusColor = const Color(0xFFE65100); // Deep Orange
        statusIcon = Icons.warning_amber_rounded;
        buttonText = "APPLY 80% CLEARANCE";
        description = "Last chance to sell before expiry.";
        break;
      case "Heavy Discount":
        statusColor = const Color(0xFF7B1FA2); // Purple
        statusIcon = Icons.trending_down;
        buttonText = "APPLY 60% OFF";
        description = "Low turnover. Needs aggressive pricing.";
        break;
      case "Flash Sale":
        statusColor = const Color(0xFF1976D2); // Blue
        statusIcon = Icons.flash_on;
        buttonText = "START FLASH SALE";
        description = "High demand item. Quick sale opportunity.";
        break;
      case "Keep Price":
        statusColor = const Color(0xFF388E3C); // Green
        statusIcon = Icons.check_circle;
        buttonText = "NO ACTION NEEDED";
        description = "Healthy stock levels.";
        break;
      default: // "Bulk Promo", "Stock Clearance"
        statusColor = const Color(0xFF00796B); // Teal
        statusIcon = Icons.local_offer;
        buttonText = "APPLY PROMO";
        description = "Reduce excess inventory.";
    }

    bool isDonate = item.actionStatus == "DONATE";
    bool isKeep = item.actionStatus == "Keep Price";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        children: [
          // 1. STRATEGY HEADER
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.08),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: statusColor.withOpacity(0.1))),
            ),
            child: Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  item.actionStatus.toUpperCase(),
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.8),
                ),
                const Spacer(),
                // Days Left Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: item.remainingLife < 5 ? Colors.red.shade50 : Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: item.remainingLife < 5 ? Colors.red.shade100 : Colors.grey.shade300),
                  ),
                  child: Text(
                    "${item.remainingLife} days left", 
                    style: TextStyle(
                      color: item.remainingLife < 5 ? Colors.red.shade800 : Colors.grey.shade700, 
                      fontSize: 11, 
                      fontWeight: FontWeight.bold
                    )
                  ),
                )
              ],
            ),
          ),

          // 2. PRODUCT & FINANCIALS
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon / Avatar
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(color: const Color(0xFFECEFF1), borderRadius: BorderRadius.circular(10)),
                  child: Center(
                    child: Text(
                      item.productName.isNotEmpty ? item.productName[0] : "?", 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Color(0xFF455A64))
                    )
                  ),
                ),
                const SizedBox(width: 16),
                
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.productName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF263238))),
                      const SizedBox(height: 4),
                      Text(description, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
                      
                      const SizedBox(height: 12),
                      
                      // GENUINE PRICE CALCULATION DISPLAY
                      if (isDonate)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(6)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text("Write-off Value: ", style: TextStyle(color: Colors.red.shade800, fontSize: 12)),
                              Text(
                                "\$${(item.markedPrice * item.currentStock).toStringAsFixed(0)}", 
                                style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold, fontSize: 14)
                              ),
                            ],
                          ),
                        )
                      else if (isKeep)
                        Text(
                          "Current Price: \$${item.markedPrice.toStringAsFixed(2)}", 
                          style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.w600, fontSize: 14)
                        )
                      else
                        Row(
                          children: [
                            Text(
                              "\$${item.markedPrice.toStringAsFixed(2)}", 
                              style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey, fontSize: 13)
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward, size: 14, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              "\$${item.finalPrice.toStringAsFixed(2)}", 
                              style: TextStyle(color: statusColor, fontWeight: FontWeight.w900, fontSize: 18)
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(4)),
                              child: Text("-${item.discountPct.toInt()}%", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            )
                          ],
                        )
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. ACTION BUTTON (Genuine Trigger)
          if (!isKeep)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                   // Genuine Action: Show Confirmation
                   _showConfirmationDialog(context, item, buttonText, statusColor);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: statusColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: Text(buttonText, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ),
            ),
          )
        ],
      ),
    );
  }

  // --- CONFIRMATION DIALOG FOR GENUINE FEEL ---
  void _showConfirmationDialog(BuildContext context, DiscountProduct item, String action, Color color) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(action, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to apply this action to ${item.currentStock} units of ${item.productName}?"),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Successfully applied: $action"),
                  backgroundColor: color,
                )
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: color),
            child: const Text("Confirm"),
          )
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text("Connection Failed", style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text("Ensure backend server is running", style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loadData, 
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2C3E50)),
            child: const Text("Retry Connection")
          )
        ],
      ),
    );
  }
}