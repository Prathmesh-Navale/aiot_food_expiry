import 'package:flutter/material.dart';
import 'package:aiot_ui/services/api_service.dart';
import 'package:aiot_ui/screens/inventory_screens.dart'; 
import 'package:aiot_ui/screens/dashboard/main_dashboard_screen.dart';
import 'package:aiot_ui/screens/donation_screen.dart'; 
import 'package:aiot_ui/screens/dashboard/productivity_screen.dart';
import 'package:aiot_ui/screens/dashboard/sales_screens.dart';
import 'package:aiot_ui/screens/dashboard/forecast_screen.dart';
import 'package:aiot_ui/screens/discount_screen.dart'; // Added Discount Screen

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
    final dummyRefresh = () => setState(() {});
    
    _screens = [
      MainDashboardScreen(onNavigate: _onNavigate), 
      SalesDashboardScreen(apiService: widget.apiService, onNavigate: _onNavigate), 
      StockEntryOptionsScreen(apiService: widget.apiService, refreshHome: dummyRefresh, onProductAdded: dummyRefresh), 
      AlertsDiscountsScreen(apiService: widget.apiService, refreshHome: dummyRefresh), 
      DonationScreen(apiService: widget.apiService, refreshHome: dummyRefresh), 
      ProductivityManagementScreen(apiService: widget.apiService),
      ForecastScreen(apiService: widget.apiService), // Added Forecast Screen
      const Center(child: Text("Contact Us")),
      const Center(child: Text("Support Desk")),
    ];
  }

  void _onNavigate(String route, String title) {
    int index = 0;
    if (route.contains('sale')) index = 1;
    else if (route.contains('stock')) index = 2;
    else if (route.contains('discount') || route.contains('alert')) index = 3;
    else if (route.contains('donation')) index = 4;
    else if (route.contains('productiv')) index = 5;
    else if (route.contains('forecast')) index = 6;

    setState(() {
      _currentIndex = index;
      _currentTitle = title;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDashboard = _currentIndex == 0;
    return Scaffold(
      appBar: AppBar(
        title: Text(isDashboard ? 'Home Dashboard' : _currentTitle),
        backgroundColor: const Color(0xFF1E1E1E),
        leading: isDashboard
            ? IconButton(icon: const Icon(Icons.menu), onPressed: () {})
            : IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() { _currentIndex = 0; _currentTitle = 'Home Dashboard'; })),
      ),
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: _screens),
          if (_isChatOpen)
            Positioned(
              right: 16.0, bottom: 85.0,
              child: ChatbotStub(onClose: () => setState(() => _isChatOpen = false)),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => _isChatOpen = !_isChatOpen),
        backgroundColor: Colors.greenAccent,
        child: const Icon(Icons.smart_toy, color: Colors.black),
      ),
    );
  }
}

class ChatbotStub extends StatelessWidget {
  final VoidCallback onClose;
  const ChatbotStub({super.key, required this.onClose});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300, height: 400,
      decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.green)),
      child: Column(children: [AppBar(title: const Text("Foody-AI"), automaticallyImplyLeading: false, backgroundColor: Colors.transparent, actions: [IconButton(icon: const Icon(Icons.close), onPressed: onClose)]), const Expanded(child: Center(child: Text("Ask me about stock...", style: TextStyle(color: Colors.white))))]),
    );
  }
}