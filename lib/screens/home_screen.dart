import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/product.dart';
import 'inventory_screens.dart'; // Contains Stock, Donation, Discounts

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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late List<Widget> _pages;
  late List<String> _titles;

  @override
  void initState() {
    super.initState();
    _titles = [
      'Dashboard', 'Sales Analytics', 'Stock Entry', 'Discounts', 'Donations'
    ];
    // We pass "widget.apiService" to all pages so they reuse your existing service
    _pages = [
      MainDashboardStub(onNavigate: _navigate),
      SalesDashboardStub(apiService: widget.apiService),
      StockEntryOptionsScreen(apiService: widget.apiService, refreshHome: _refresh, onProductAdded: _refresh),
      AlertsDiscountsScreen(apiService: widget.apiService, refreshHome: _refresh),
      DonationScreen(apiService: widget.apiService, refreshHome: _refresh),
    ];
  }

  void _refresh() => setState(() {});

  void _navigate(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        centerTitle: true,
      ),
      drawer: _buildDrawer(),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.smart_toy, color: Colors.black),
        onPressed: () {
          showModalBottomSheet(
            context: context, 
            backgroundColor: Colors.transparent,
            builder: (_) => ChatbotStub(apiService: widget.apiService)
          );
        },
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF1E1E1E),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).primaryColor.withOpacity(0.1)),
            accountName: Text(widget.storeName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            accountEmail: const Text("AIoT Smart Inventory", style: TextStyle(color: Colors.white70)),
            currentAccountPicture: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.store, size: 30, color: Colors.black)),
          ),
          _drawerItem(Icons.dashboard, 'Dashboard', 0),
          _drawerItem(Icons.ssid_chart, 'Sales Analytics', 1),
          _drawerItem(Icons.add_box, 'Add Stock', 2),
          _drawerItem(Icons.discount, 'Active Discounts', 3),
          _drawerItem(Icons.volunteer_activism, 'Donations', 4),
          const Divider(color: Colors.grey),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () => Navigator.pushReplacementNamed(context, '/login'),
          )
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, int index) {
    final isSelected = _currentIndex == index;
    return ListTile(
      leading: Icon(icon, color: isSelected ? Theme.of(context).primaryColor : Colors.white70),
      title: Text(title, style: TextStyle(color: isSelected ? Theme.of(context).primaryColor : Colors.white)),
      selected: isSelected,
      onTap: () {
        setState(() => _currentIndex = index);
        Navigator.pop(context);
      },
    );
  }
}

// ==========================================
// DASHBOARD & ANALYTICS WIDGETS
// ==========================================

class MainDashboardStub extends StatelessWidget {
  final Function(int) onNavigate;
  const MainDashboardStub({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Store Overview", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _statCard("Total Items", "1,240", Colors.blue)),
              const SizedBox(width: 16),
              Expanded(child: _statCard("At Risk", "12", Colors.red)),
            ],
          ),
          const SizedBox(height: 16),
           Row(
            children: [
              Expanded(child: _statCard("On Sale", "45", Colors.orange)),
              const SizedBox(width: 16),
              Expanded(child: _statCard("Revenue", "\$4.2k", Colors.green)),
            ],
          ),
          const SizedBox(height: 30),
          const Text("Quick Actions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: ElevatedButton(onPressed: () => onNavigate(2), child: const Text("Add Stock"))),
              const SizedBox(width: 10),
              Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.white24), onPressed: () => onNavigate(1), child: const Text("View Sales"))),
            ],
          )
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF252525), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class SalesDashboardStub extends StatelessWidget {
  final ApiService apiService;
  const SalesDashboardStub({super.key, required this.apiService});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 80, color: Colors.grey[800]),
          const SizedBox(height: 16),
          const Text("Sales Visualization Module", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          const Text("(Graph library would connect to apiService.fetchProductSalesDetail here)", style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}

class ChatbotStub extends StatefulWidget {
  final ApiService apiService;
  const ChatbotStub({super.key, required this.apiService});

  @override
  State<ChatbotStub> createState() => _ChatbotStubState();
}

class _ChatbotStubState extends State<ChatbotStub> {
  final TextEditingController _ctrl = TextEditingController();
  String _response = "How can I help you today?";

  void _send() async {
    final query = _ctrl.text;
    _ctrl.clear();
    setState(() => _response = "Thinking...");
    final reply = await widget.apiService.resolveChatQuery(query);
    setState(() => _response = reply);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Container(width: 40, height: 4, color: Colors.grey),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("Foody-AI Assistant", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          Expanded(child: Center(child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(_response, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
          ))),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _ctrl,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: "Ask about stock...",
                filled: true,
                fillColor: Colors.black,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                suffixIcon: IconButton(icon: const Icon(Icons.send, color: Colors.green), onPressed: _send)
              ),
            ),
          )
        ],
      ),
    );
  }
}