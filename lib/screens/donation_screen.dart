// lib/screens/donation_screen.dart

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

        // Rule 1: Expiry <= 4 days
        if (p.daysToExpiry <= 4 && p.status != 'Donated') {
          shouldDonate = true;
        } 
        // Rule 2: High Discount (> 70%) means item is dead stock -> Donate
        else if (p.daysToExpiry <= 30 && p.status != 'Donated') { 
           try {
             final result = await widget.apiService.calculateDiscount(p);
             double discount = result['discount_percentage'] ?? 0.0;
             if (discount > 70.0) {
               shouldDonate = true;
             }
           } catch (e) { /* ignore */ }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
            decoration: const BoxDecoration(color: Color(0xFFD32F2F)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("TOTAL WRITE-OFF VALUE", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                Text("\$${totalValue.toStringAsFixed(0)}", style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _donationList.isEmpty
                    ? const Center(child: Text("No Pending Donations", style: TextStyle(fontSize: 18, color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _donationList.length,
                        itemBuilder: (context, index) {
                          final p = _donationList[index];
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.warning, color: Colors.red, size: 30),
                              title: Text(p.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text("Expires in ${p.daysToExpiry} days"),
                              trailing: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                onPressed: () => _markAsDonated(p.id!),
                                child: const Text("Log Donation", style: TextStyle(color: Colors.white)),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}