// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:aiot_ui/services/api_service.dart';
import 'package:aiot_ui/screens/inventory_screens.dart';
import 'package:aiot_ui/screens/dashboard/main_dashboard_screen.dart';
import 'package:aiot_ui/screens/dashboard/sales_screens.dart';
import 'package:flutter/services.dart';
import 'dashboard/forecast_screen.dart';
import 'donation_screen.dart';
import 'dashboard/productivity_screen.dart';

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
      _currentTitle = _menuItems[_currentIndex]['title'] as String;
      _isInitialized = true;
    }
  }

  void _initializeScreens() {
    final dummyOnProductAdded = () {
      _forceRefresh();
      _onNavigate('/alerts-discounts', 'Dynamic Discounting & Alerts');
    };

    _menuItems = [
      {'title': 'Home Dashboard', 'route': '/main-dashboard', 'icon': Icons.dashboard, 'index': 0},
      {'title': 'Sales Visualization', 'route': '/sales-dashboard', 'icon': Icons.ssid_chart, 'index': 1},
      {'title': 'Stock Entry', 'route': '/stock-options', 'icon': Icons.scanner_outlined, 'index': 2},
      {'title': 'Discounts & Alerts', 'route': '/alerts-discounts', 'icon': Icons.discount, 'index': 3},
      {'title': 'Donation Management', 'route': '/donation', 'icon': Icons.volunteer_activism, 'index': 4},
      {'title': 'Productivity Management', 'route': '/productivity', 'icon': Icons.insights, 'index': 5},
      {'title': 'Store Profile', 'route': '/profile', 'icon': Icons.store, 'index': 6},
      {'title': 'Contact Us', 'route': '/contact', 'icon': Icons.phone, 'index': 7},
      {'title': 'Support Desk', 'route': '/support', 'icon': Icons.support_agent, 'index': 8},
    ];

    _screens = [
      MainDashboardScreen(onNavigate: _onNavigate),
      SalesDashboardScreen(apiService: widget.apiService, onNavigate: _onNavigate),
      StockEntryOptionsScreen(apiService: widget.apiService, refreshHome: _forceRefresh, onProductAdded: dummyOnProductAdded),
      AlertsDiscountsScreen(apiService: widget.apiService, refreshHome: _forceRefresh),
      DonationScreen(apiService: widget.apiService, refreshHome: _forceRefresh),
      // ✅ FIXED: Forecast Screen now receives apiService
      ForecastScreen(apiService: widget.apiService),
      const PlaceholderScreen(title: 'Store Profile'),
      const PlaceholderScreen(title: 'Contact Us'),
      const PlaceholderScreen(title: 'Support Desk'),
    ];
  }

  void _onNavigate(String route, String title) {
    int index = 0;
    if (route.contains('sale')) index = 1;
    else if (route.contains('stock')) index = 2;
    else if (route.contains('discount') || route.contains('alert')) index = 3;
    else if (route.contains('donation')) index = 4;
    else if (route.contains('productiv') || route.contains('forecast')) index = 5;
    else if (route.contains('profile')) index = 6;
    else if (route.contains('contact')) index = 7;
    else if (route.contains('support')) index = 8;

    setState(() {
      _currentIndex = index;
      _currentTitle = title;
    });
  }

  void _goToDashboard() => _onNavigate('/main-dashboard', 'Home Dashboard');
  void _forceRefresh() => setState(() {});
  void _toggleChat() => setState(() => _isChatOpen = !_isChatOpen);

  @override
  Widget build(BuildContext context) {
    final bool isDashboard = _currentIndex == 0;
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentTitle),
        backgroundColor: Theme.of(context).cardColor,
        leading: isDashboard
            ? IconButton(icon: const Icon(Icons.menu), onPressed: () => Scaffold.of(context).openDrawer())
            : IconButton(icon: const Icon(Icons.arrow_back), onPressed: _goToDashboard),
      ),
      drawer: _buildDrawer(),
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

  Drawer _buildDrawer() {
    return Drawer(
      child: Container(
        color: Theme.of(context).cardColor,
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.inventory_2, size: 40, color: Colors.white),
                  const SizedBox(height: 8),
                  Text('AIoT Manager', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),
                  Text(widget.storeName, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white70)),
                ],
              ),
            ),
            ..._menuItems.map((item) => ListTile(
              leading: Icon(item['icon'] as IconData, color: Colors.white70),
              title: Text(item['title'] as String, style: const TextStyle(color: Colors.white)),
              onTap: () { Navigator.pop(context); _onNavigate(item['route'] as String, item['title'] as String); },
            )),
          ],
        ),
      ),
    );
  }
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

class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});
  @override
  Widget build(BuildContext context) {
    return Center(child: Text(title));
  }
}