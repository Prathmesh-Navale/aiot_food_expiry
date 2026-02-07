// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../widgets/chatbot_overlay.dart';

// --- CORRECT IMPORTS ---
import 'inventory_screens.dart'; // Contains StockEntry, AlertsDiscounts
import 'donation_screen.dart';   // Contains DonationScreen
import 'dashboard/main_dashboard_screen.dart';
import 'dashboard/sales_screens.dart';
import 'dashboard/forecast_screen.dart';

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
  late List<Map<String, dynamic>> _menuItems;
  late List<Widget> _screens;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _initializeScreens();
      _isInitialized = true;
    }
  }

  void _initializeScreens() {
    final dummyRefresh = () => setState(() {});
    final dummyOnProductAdded = () {
      setState(() {});
      _onNavigate('/alerts-discounts', 'Discounts & Alerts');
    };

    _menuItems = [
      {'title': 'Home Dashboard', 'route': '/main-dashboard', 'icon': Icons.dashboard, 'index': 0},
      {'title': 'Sales Visualization', 'route': '/sales-dashboard', 'icon': Icons.ssid_chart, 'index': 1},
      {'title': 'Stock Entry', 'route': '/stock-options', 'icon': Icons.scanner_outlined, 'index': 2},
      {'title': 'Discounts & Alerts', 'route': '/alerts-discounts', 'icon': Icons.discount, 'index': 3},
      {'title': 'Donation Management', 'route': '/donation', 'icon': Icons.volunteer_activism, 'index': 4},
      {'title': 'Store Profile', 'route': '/profile', 'icon': Icons.store, 'index': 5},
    ];

    _screens = [
      MainDashboardScreen(onNavigate: _onNavigate),
      SalesDashboardScreen(apiService: widget.apiService, onNavigate: _onNavigate),
      StockEntryOptionsScreen(apiService: widget.apiService, refreshHome: dummyRefresh, onProductAdded: dummyOnProductAdded),
      // ✅ FIXED: Using AlertsDiscountsScreen instead of DiscountTableScreen
      AlertsDiscountsScreen(apiService: widget.apiService, refreshHome: dummyRefresh),
      // ✅ FIXED: Using DonationScreen imported from donation_screen.dart
      DonationScreen(apiService: widget.apiService, refreshHome: dummyRefresh),
      const Scaffold(body: Center(child: Text("Store Profile Coming Soon"))),
    ];
  }

  void _onNavigate(String route, String title) {
    int index = 0;
    if (route.contains('sale')) index = 1;
    else if (route.contains('stock')) index = 2;
    else if (route.contains('discount') || route.contains('alert')) index = 3;
    else if (route.contains('donation')) index = 4;
    else if (route.contains('profile')) index = 5;

    setState(() {
      _currentIndex = index;
      _currentTitle = title;
    });
  }

  void _toggleChat() {
    setState(() => _isChatOpen = !_isChatOpen);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    
    return Scaffold(
      appBar: AppBar(title: Text(_currentTitle)),
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: _screens),
          if (_isChatOpen)
            Positioned(
              right: 16, bottom: 80,
              child: FoodyAIChatbot(apiService: widget.apiService, onClose: _toggleChat),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleChat,
        child: Icon(_isChatOpen ? Icons.close : Icons.smart_toy),
      ),
    );
  }
}