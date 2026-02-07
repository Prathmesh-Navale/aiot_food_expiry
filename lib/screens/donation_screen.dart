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
  late Future<List<Product>> _productsFuture;
  final int donationThresholdDays = 4;

  @override
  void initState() {
    super.initState();
    _productsFuture = widget.apiService.fetchProducts();
  }

  Future<void> _markAsDonated(String id, String productName) async {
    try {
      await widget.apiService.deleteProduct(id);
      widget.refreshHome();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully donated: $productName.')),
        );
        setState(() {
          _productsFuture = widget.apiService.fetchProducts();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Donation Management')),
      body: FutureBuilder<List<Product>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData) return const Center(child: Text('No Data'));

          final donationCandidates = snapshot.data!
              .where((p) => p.daysToExpiry > 0 && p.daysToExpiry <= donationThresholdDays && p.status != 'Donated')
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Text('Second Alert: Donation Strategy', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.red)),
              const Divider(),
              if (donationCandidates.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No items need donation right now.'))),
              ...donationCandidates.map((product) {
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.warning, color: Colors.red),
                    title: Text(product.productName),
                    subtitle: Text('Expires in ${product.daysToExpiry} days'),
                    trailing: ElevatedButton.icon(
                      icon: const Icon(Icons.thumb_up),
                      label: const Text('Donate'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: product.id == null ? null : () => _markAsDonated(product.id!, product.productName),
                    ),
                  ),
                );
              }).toList(),
            ],
          );
        },
      ),
    );
  }
}