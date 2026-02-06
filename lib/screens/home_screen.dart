// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:aiot_ui/services/api_service.dart';

// --- FIXED IMPORT CONFLICT ---
import 'package:aiot_ui/screens/inventory_screens.dart' hide DonationScreen; 
// -----------------------------

import 'package:aiot_ui/screens/dashboard/main_dashboard_screen.dart'; 

// --- ENSURE THIS IMPORT MATCHES YOUR FILE STRUCTURE ---
import 'package:aiot_ui/screens/dashboard/sales_screens.dart'; 
// -----------------------------------------------------

import 'package:flutter/services.dart';
import '../widgets/chatbot_overlay.dart'; 
import '../discount_screen.dart'; 

// New Modules
import 'dashboard/forecast_screen.dart'; 
import 'donation_screen.dart';           

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
  void initState() {
    super.initState();
  }

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
      
      // Index 1: Sales Visualization
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
      // 0. Main Dashboard
      MainDashboardScreen(onNavigate: _onNavigate), 
      
      // 1. Sales Dashboard (Connected)
      SalesDashboardScreen(
        apiService: widget.apiService, 
        onNavigate: _onNavigate
      ), 
      
      // 2. Stock Entry
      StockEntryOptionsScreen(apiService: widget.apiService, refreshHome: _forceRefresh, onProductAdded: dummyOnProductAdded), 
      
      // 3. Discounts
      const DiscountTableScreen(), 
      
      // 4. Donation
      DonationScreen(apiService: widget.apiService, refreshHome: _forceRefresh), 

      // 5. Forecast
      const ForecastScreen(), 
      
      // 6, 7, 8 Placeholders
      const PlaceholderScreen(title: 'Store Profile'), 
      const PlaceholderScreen(title: 'Contact Us'), 
      const PlaceholderScreen(title: 'Support Desk'), 
    ];
  }

  void _onNavigate(String route, String title) {
    String cleanRoute = route.toLowerCase();
    int index = -1;

    // --- SMART ROUTING LOGIC ---
    if (cleanRoute.contains('dashboard') && !cleanRoute.contains('sale') || cleanRoute == '/') {
      index = 0; // Main Dashboard
    }
    // ROUTING FOR SALES SCREEN
    else if (cleanRoute.contains('sale')) {
      index = 1;
    }
    // ---------------------------
    else if (cleanRoute.contains('stock') || cleanRoute.contains('scan')) index = 2;
    else if (cleanRoute.contains('discount') || cleanRoute.contains('alert')) index = 3; 
    else if (cleanRoute.contains('donation')) index = 4;
    else if (cleanRoute.contains('productiv') || cleanRoute.contains('forecast')) index = 5;
    else if (cleanRoute.contains('profile')) index = 6;
    else if (cleanRoute.contains('contact')) index = 7;
    else if (cleanRoute.contains('support')) index = 8;

    if (index != -1) {
      setState(() {
        _currentIndex = index;
        _currentTitle = _menuItems.firstWhere((item) => item['index'] == index)['title'] as String;
      });
      
      if (Scaffold.of(context).hasDrawer && Scaffold.of(context).isDrawerOpen) {
        Navigator.pop(context);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Debug: Could not find page for '$route'"), backgroundColor: Colors.red),
      );
    }
  }

  void _goToDashboard() {
    _onNavigate('/main-dashboard', 'Home Dashboard');
  }

  void _forceRefresh() {
    setState(() {});
  }

  void _toggleChat() {
    setState(() {
      _isChatOpen = !_isChatOpen;
    });
  }

  Widget _buildScreen() {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return IndexedStack(
      index: _currentIndex,
      children: _screens,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDashboard = _currentIndex == 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentTitle),
        backgroundColor: Theme.of(context).cardColor,
        leading: isDashboard
            ? Builder(builder: (context) {
          return IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          );
        })
            : IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goToDashboard,
        ),
      ),
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(color: Colors.white),
          ),
          _buildScreen(),
          if (_isChatOpen)
            Positioned(
              right: 16.0, 
              bottom: 85.0, 
              child: FoodyAIChatbot(
                apiService: widget.apiService,
                onClose: _toggleChat, 
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleChat,
        backgroundColor: _isChatOpen ? Colors.red.shade400 : Theme.of(context).colorScheme.primary,
        elevation: 8,
        shape: const CircleBorder(),
        child: Icon(_isChatOpen ? Icons.close : Icons.smart_toy, color: Colors.black, size: 30),
        tooltip: _isChatOpen ? 'Close Foody-AI' : 'Open Foody-AI Chatbot',
      ),
    );
  }

  Drawer _buildDrawer() {
    if (!_isInitialized) {
      return const Drawer(child: Center(child: Text("Loading...")));
    }
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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text('CORE OPERATIONS', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ..._menuItems.sublist(0, 6).map((item) => _buildDrawerTile(item['icon'] as IconData, item['title'] as String, item['route'] as String)),
            const Divider(color: Colors.grey),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text('ACCOUNT & SUPPORT', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ..._menuItems.sublist(6).map((item) => _buildDrawerTile(item['icon'] as IconData, item['title'] as String, item['route'] as String)),
            const Divider(color: Colors.grey),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerTile(IconData icon, String title, String route) {
    final itemIndex = _menuItems.indexWhere((item) => item['route'] == route);
    final bool isSelected = _currentIndex == itemIndex;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: ListTile(
          hoverColor: Colors.white.withOpacity(0.08),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          leading: Icon(icon, color: isSelected ? Theme.of(context).colorScheme.primary : Colors.white70),
          title: Text(
            title, 
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, 
              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.white
            )
          ),
          selected: isSelected,
          selectedTileColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
          onTap: () {
            Navigator.pop(context);
            _onNavigate(route, title); 
          },
        ),
      ),
    );
  }
}