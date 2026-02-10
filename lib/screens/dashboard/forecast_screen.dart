import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ForecastScreen extends StatefulWidget {
  final ApiService apiService;
  const ForecastScreen({super.key, required this.apiService});

  @override
  State<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends State<ForecastScreen> {
  late Future<List<dynamic>> _futureForecast;

  @override
  void initState() {
    super.initState();
    _futureForecast = widget.apiService.getForecast();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _futureForecast,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final item = snapshot.data![index];
            return Card(
              color: Colors.white,
              child: ListTile(
                leading: const Icon(Icons.trending_up, color: Colors.blue),
                title: Text(item['product'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                subtitle: Text("Waste Saved: ${item['waste_saved']}", style: const TextStyle(color: Colors.grey)),
                trailing: Text("${item['recommended_order']} Units", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 16)),
              ),
            );
          },
        );
      },
    );
  }
}