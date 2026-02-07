// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'inventory_screens.dart'; // Combined import for Stock, Donation, Discounts

// --- MAIN HOME SCREEN ---
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
    final dummyOnProductAdded = () { _forceRefresh(); _onNavigate('/alerts-discounts', 'Discounts & Alerts'); };

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
      // 0. Main Dashboard (Stubbed)
      MainDashboardStub(onNavigate: (i) => setState(() => _currentIndex = i)), 
      
      // 1. Sales Dashboard (Stubbed)
      SalesDashboardStub(apiService: widget.apiService), 
      
      // 2. Stock Entry (From inventory_screens.dart)
      StockEntryOptionsScreen(apiService: widget.apiService, refreshHome: _forceRefresh, onProductAdded: dummyOnProductAdded), 
      
      // 3. Discounts (From inventory_screens.dart)
      AlertsDiscountsScreen(apiService: widget.apiService, refreshHome: _forceRefresh), 
      
      // 4. Donation (From inventory_screens.dart)
      DonationScreen(apiService: widget.apiService, refreshHome: _forceRefresh), 

      // 5. Forecast (Stubbed)
      const PlaceholderScreen(title: 'Productivity & Forecast'), 
      
      // 6, 7, 8 Placeholders
      const PlaceholderScreen(title: 'Store Profile'), 
      const PlaceholderScreen(title: 'Contact Us'), 
      const PlaceholderScreen(title: 'Support Desk'), 
    ];
  }

  void _onNavigate(String route, String title) {
    String cleanRoute = route.toLowerCase();
    int index = -1;
    if (cleanRoute.contains('dashboard') && !cleanRoute.contains('sale') || cleanRoute == '/') index = 0;
    else if (cleanRoute.contains('sale')) index = 1;
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
      if (Scaffold.of(context).hasDrawer && Scaffold.of(context).isDrawerOpen) Navigator.pop(context);
    }
  }

  void _forceRefresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final bool isDashboard = _currentIndex == 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentTitle),
        backgroundColor: Theme.of(context).cardColor,
        leading: isDashboard
            ? Builder(builder: (context) => IconButton(icon: const Icon(Icons.menu), onPressed: () => Scaffold.of(context).openDrawer()))
            : IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => _onNavigate('/main-dashboard', 'Home Dashboard')),
      ),
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: _screens),
          if (_isChatOpen)
            Positioned(
              right: 16.0, bottom: 85.0, 
              child: ChatbotStub(apiService: widget.apiService, onClose: () => setState(() => _isChatOpen = false)),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => _isChatOpen = !_isChatOpen),
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
              leading: Icon(item['icon'] as IconData, color: _currentIndex == item['index'] ? Theme.of(context).colorScheme.primary : Colors.white70),
              title: Text(item['title'] as String, style: TextStyle(color: _currentIndex == item['index'] ? Theme.of(context).colorScheme.primary : Colors.white)),
              selected: _currentIndex == item['index'],
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _currentIndex = item['index'] as int;
                  _currentTitle = item['title'] as String;
                });
              },
            )).toList(),
          ],
        ),
      ),
    );
  }
}

// --- STUBS FOR MISSING WIDGETS ---
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});
  @override
  Widget build(BuildContext context) {
    return Center(child: Text("Coming Soon: $title", style: const TextStyle(fontSize: 18, color: Colors.grey)));
  }
}

class MainDashboardStub extends StatelessWidget {
  final Function(int) onNavigate;
  const MainDashboardStub({super.key, required this.onNavigate});
  @override
  Widget build(BuildContext context) {
    return Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.dashboard, size: 60, color: Colors.blue),
        const SizedBox(height: 20),
        const Text("Main Dashboard", style: TextStyle(fontSize: 20, color: Colors.white)),
        const SizedBox(height: 20),
        ElevatedButton(onPressed: () => onNavigate(2), child: const Text("Go to Stock Entry"))
      ],
    ));
  }
}

class SalesDashboardStub extends StatelessWidget {
  final ApiService apiService;
  const SalesDashboardStub({super.key, required this.apiService});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Sales Charts Go Here"));
  }
}

class ChatbotStub extends StatelessWidget {
  final ApiService apiService;
  final VoidCallback onClose;
  const ChatbotStub({super.key, required this.apiService, required this.onClose});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300, height: 400,
      decoration: BoxDecoration(color: const Color(0xFF2C2C2C), borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black54)]),
      child: Column(
        children: [
          ListTile(title: const Text("Foody-AI", style: TextStyle(color: Colors.white)), trailing: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: onClose)),
          const Expanded(child: Center(child: Text("Ask me about stock...", style: TextStyle(color: Colors.grey)))),
        ],
      ),
    );
  }
}