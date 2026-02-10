// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:aiot_ui/services/api_service.dart';
import 'package:aiot_ui/screens/inventory_screens.dart'; // Inventory, Alerts
import 'package:aiot_ui/screens/dashboard/main_dashboard_screen.dart'; // Grid
import 'package:aiot_ui/screens/donation_screen.dart'; // Donation
import 'package:flutter/services.dart';

// Import these if you have fixed them, otherwise Stubs below will handle it
// import 'dashboard/sales_screens.dart';
// import 'dashboard/productivity_screen.dart';
// import 'dashboard/forecast_screen.dart';

class HomeScreen extends StatefulWidget {
  final ApiService apiService;
  final String storeName;

  const HomeScreen({super.key, required this.apiService, required this.storeName});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String _currentTitle = 'Home Dashboard';
  bool _isChatOpen = false;

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _initializeScreens();
  }

  void _initializeScreens() {
    final dummyRefresh = () => setState(() {});
    
    _screens = [
      MainDashboardScreen(onNavigate: _onNavigate), // 0
      SalesDashboardStub(apiService: widget.apiService), // 1 - Stub or Real
      StockEntryOptionsScreen(apiService: widget.apiService, refreshHome: dummyRefresh, onProductAdded: dummyRefresh), // 2
      AlertsDiscountsScreen(apiService: widget.apiService, refreshHome: dummyRefresh), // 3
      DonationScreen(apiService: widget.apiService, refreshHome: dummyRefresh), // 4
      ProductivityStub(apiService: widget.apiService), // 5 - Stub or Real
    ];
  }

  void _onNavigate(String route, String title) {
    int index = 0;
    if (route.contains('sale')) index = 1;
    else if (route.contains('stock')) index = 2;
    else if (route.contains('discount') || route.contains('alert')) index = 3;
    else if (route.contains('donation')) index = 4;
    else if (route.contains('productiv')) index = 5;

    setState(() {
      _currentIndex = index;
      _currentTitle = title;
    });
  }

  void _goToDashboard() {
    setState(() {
      _currentIndex = 0;
      _currentTitle = 'Home Dashboard';
    });
  }

  void _toggleChat() => setState(() => _isChatOpen = !_isChatOpen);

  @override
  Widget build(BuildContext context) {
    final bool isDashboard = _currentIndex == 0;
    return Scaffold(
      appBar: AppBar(
        title: Text(isDashboard ? 'Home Dashboard' : _currentTitle),
        backgroundColor: const Color(0xFF1E1E1E),
        leading: isDashboard
            ? IconButton(icon: const Icon(Icons.menu), onPressed: () {})
            : IconButton(icon: const Icon(Icons.arrow_back), onPressed: _goToDashboard),
      ),
      body: Stack(
        children: [
          Positioned.fill(child: Container(color: Colors.white)),
          IndexedStack(index: _currentIndex, children: _screens),
          if (_isChatOpen)
            Positioned(
              right: 16.0,
              bottom: 85.0,
              child: FoodyAIChatbot(apiService: widget.apiService, onClose: _toggleChat),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleChat,
        backgroundColor: _isChatOpen ? Colors.red.shade400 : Theme.of(context).colorScheme.primary,
        child: Icon(_isChatOpen ? Icons.close : Icons.smart_toy, color: Colors.black, size: 30),
      ),
    );
  }
}

// --- STUBS (Placeholders to ensure app runs if files are missing) ---
class SalesDashboardStub extends StatelessWidget {
  final ApiService apiService;
  const SalesDashboardStub({super.key, required this.apiService});
  @override
  Widget build(BuildContext context) => const Center(child: Text("Sales Dashboard (Placeholder)"));
}

class ProductivityStub extends StatelessWidget {
  final ApiService apiService;
  const ProductivityStub({super.key, required this.apiService});
  @override
  Widget build(BuildContext context) => const Center(child: Text("Productivity Screen (Placeholder)"));
}

class FoodyAIChatbot extends StatelessWidget {
  final ApiService apiService;
  final VoidCallback onClose;
  const FoodyAIChatbot({super.key, required this.apiService, required this.onClose});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300, height: 400,
      decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.green)),
      child: Column(children: [AppBar(title: const Text("Foody-AI"), automaticallyImplyLeading: false, backgroundColor: Colors.transparent, actions: [IconButton(icon: const Icon(Icons.close), onPressed: onClose)]), const Expanded(child: Center(child: Text("Ask me about stock...", style: TextStyle(color: Colors.white)))), Padding(padding: const EdgeInsets.all(8.0), child: TextField(decoration: InputDecoration(hintText: "Type a message...", filled: true, fillColor: Colors.black, border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)))))]),
    );
  }
}