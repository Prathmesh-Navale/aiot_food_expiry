import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DiscountTableScreen extends StatefulWidget {
  final ApiService apiService;
  const DiscountTableScreen({super.key, required this.apiService});

  @override
  State<DiscountTableScreen> createState() => _DiscountTableScreenState();
}

class _DiscountTableScreenState extends State<DiscountTableScreen> {
  late Future<List<dynamic>> _futureDiscounts;

  @override
  void initState() {
    super.initState();
    _futureDiscounts = widget.apiService.getDiscountsRaw();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _futureDiscounts,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final item = snapshot.data![index];
            return Card(
              color: const Color(0xFF1E1E1E),
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(item['product_name'] ?? 'Unknown', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text("Action: ${item['action_status']}", style: TextStyle(color: Colors.grey[400])),
                trailing: Text("-${(item['recommended_discount'] ?? 0)}%", style: const TextStyle(color: Colors.orange, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            );
          },
        );
      },
    );
  }
}