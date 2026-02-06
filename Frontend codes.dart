//api_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/product.dart'; // UPDATED: Import Product model from its new file

class ApiService {
  final String baseUrl;
  final http.Client client = http.Client();

  ApiService({required this.baseUrl});

  Future<List<Product>> fetchProducts() async {
    try {
      final response = await client.get(Uri.parse('$baseUrl/products'));

      if (response.statusCode == 200) {
        final List<dynamic> productsJson = jsonDecode(response.body);
        return productsJson.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      print('API Error (fetchProducts): $e');
      return [];
    }
  }

  Future<void> addProduct(Product product) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/products'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(product.toJson()),
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to add product: ${response.body}');
      }
    } catch (e) {
      print('API Error (addProduct): $e');
      rethrow;
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      final response = await client.delete(Uri.parse('$baseUrl/products/$id'));

      if (response.statusCode != 200) {
        throw Exception('Failed to delete product: ${response.body}');
      }
    } catch (e) {
      print('API Error (deleteProduct): $e');
      rethrow;
    }
  }

  Future<Map<String, double>> calculateDiscount(Product product) async {
    // API Call to get discount/final price based on AI model
    final response = await client.post(
      Uri.parse('$baseUrl/calculate_discount'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'days_to_expiry': product.daysToExpiry,
        'product_price': product.initialPrice,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'discount_percentage': (data['discount_percentage'] as num?)?.toDouble() ?? 0.0,
        'final_price': (data['final_price'] as num?)?.toDouble() ?? product.initialPrice,
      };
    } else {
      throw Exception('Failed to calculate discount: ${response.body}');
    }
  }

  Future<String> getRecipeSuggestion(String productName) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/ai_recipe'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'product_name': productName}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['recipe'] as String? ?? 'No recipe found.';
      } else {
        return 'Recipe generation failed.';
      }
    } catch (e) {
      print('API Error (getRecipeSuggestion): $e');
      return 'Recipe service unavailable.';
    }
  }
}

//auth_screen.dart
// lib/screens/auth_screen.dart

import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _storeNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  void _submitLogin() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // --- AUTHENTICATION LOGIC (Placeholder) ---
      final storeName = _storeNameController.text.trim().toLowerCase();

      Future.delayed(const Duration(milliseconds: 800), () {
        setState(() {
          _isLoading = false;
        });

        if (storeName == 'store-1') {
          // Navigate to Home upon successful login/validation
          Navigator.pushReplacementNamed(
              context,
              '/home',
              arguments: {'storeName': storeName.toUpperCase()}
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login Failed: Please check the Store Name (must be "store-1").')),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400), // Slightly smaller max width
            padding: const EdgeInsets.all(35.0),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 5)), // Subtle primary glow
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.fastfood, size: 60, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 10),
                  Text(
                    'AIoT Food Expiry System',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 25),

                  // Store Name Input
                  TextFormField(
                    controller: _storeNameController,
                    decoration: InputDecoration(
                      labelText: 'Store Name (e.g., store-1)',
                      prefixIcon: Icon(Icons.store, color: Theme.of(context).colorScheme.primary.withOpacity(0.7)),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Store Name is required';
                      }
                      if (value.toLowerCase() != 'store-1') {
                        return 'Access restricted to Store-1';
                      }
                      return null;
                    },
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 18),

                  // Username Input
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.person, color: Theme.of(context).colorScheme.primary.withOpacity(0.7)),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Username is required' : null,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 18),

                  // Password Input
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock, color: Theme.of(context).colorScheme.primary.withOpacity(0.7)),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Password is required' : null,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 40),

                  // Login Button
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                    onPressed: _submitLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 5, // Added elevation for lift
                      shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1),
                    ),
                    child: const Text('LOG IN'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

//main.dart
// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

// --- Local Imports ---
import 'models/product.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/inventory_screens.dart'; // Imports Alerts/Donation, Placeholder, Entry Forms
import 'services/api_service.dart';

// FIX: Added direct import for the Productivity screen for the MaterialApp routes.
import 'screens/dashboard/productivity_screen.dart';
// ------------------------------------------------------------------------

// --- CONFIGURATION ---
const String BASE_URL = 'http://127.0.0.1:8000';
// ---

// --- MAIN APPLICATION WIDGET ---
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // System UI Override for clean look (removes artifacts but doesn't fix FLAG_SECURE)
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle.light.copyWith(
      systemStatusBarContrastEnforced: false,
    ),
  );

  runApp(const AIoTInventoryApp());
}

class AIoTInventoryApp extends StatelessWidget {
  const AIoTInventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService(baseUrl: BASE_URL);

    // Dummy refresh functions for navigation
    final VoidCallback dummyRefresh = () {};
    final VoidCallback dummyOnProductAdded = () {};

    return MaterialApp(
      title: 'AIoT Smart Food Management',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00C853), // Green
          brightness: Brightness.dark,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        // Pass storeName parameter to Home Screen (Safer argument handling)
        '/home': (context) {
          final settings = ModalRoute.of(context)?.settings;
          final args = settings?.arguments as Map<String, String>?;
          final storeName = args?['storeName'] ?? 'Default Store';
          return HomeScreen(apiService: apiService, storeName: storeName);
        },
        // Routes for individual screens
        '/stock-options': (context) => StockEntryOptionsScreen(apiService: apiService, refreshHome: dummyRefresh, onProductAdded: dummyOnProductAdded),
        '/manual-entry': (context) => InventoryEntryScreen(apiService: apiService, onProductAdded: dummyOnProductAdded),
        '/alerts-discounts': (context) => AlertsDiscountsScreen(apiService: apiService, refreshHome: dummyRefresh),
        '/donation': (context) => DonationScreen(apiService: apiService, refreshHome: dummyRefresh),
        // This line now successfully finds the constructor:
        '/productivity': (context) => ProductivityManagementScreen(apiService: apiService),
        // Placeholder screens
        '/profile': (context) => const PlaceholderScreen(title: 'Store Profile'),
        '/contact': (context) => const PlaceholderScreen(title: 'Contact Us'),
        '/support': (context) => const PlaceholderScreen(title: 'Support Desk'),
        '/chatbot': (context) => const PlaceholderScreen(title: 'AI Chatbot Assistant'),
      },
    );
  }
}

//Androidmanifest.xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application
        android:label="aiot_ui"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:taskAffinity=""
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <!-- Specifies an Android theme to apply to this Activity as soon as
                 the Android process has started. This theme is visible to the user
                 while the Flutter UI initializes. After that, this theme continues
                 to determine the Window background behind the Flutter UI. -->
            <meta-data
              android:name="io.flutter.embedding.android.NormalTheme"
              android:resource="@style/NormalTheme"
              />
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
        <!-- Don't delete the meta-data below.
             This is used by the Flutter tool to generate GeneratedPluginRegistrant.java -->
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
    <!-- Required to query activities that can process text, see:
         https://developer.android.com/training/package-visibility and
         https://developer.android.com/reference/android/content/Intent#ACTION_PROCESS_TEXT.

         In particular, this is used by the Flutter engine in io.flutter.plugin.text.ProcessTextPlugin. -->
    <queries>
        <intent>
            <action android:name="android.intent.action.PROCESS_TEXT"/>
            <data android:mimeType="text/plain"/>
        </intent>
    </queries>
</manifest>

//Mainactivity.kt
package com.example.aiot_ui

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import android.os.Bundle // <-- Required for onCreate
import android.view.WindowManager // <-- Required for FLAG_SECURE
import androidx.annotation.NonNull

class MainActivity: FlutterActivity() {

    // Running this code in onCreate is the earliest and most robust point
    // to manipulate the window flags, overriding persistent secure settings.
    override fun onCreate(savedInstanceState: Bundle?) {
        // Must call super.onCreate first to establish the window context
        super.onCreate(savedInstanceState)

        // =======================================================
        // FINAL FIX: Explicitly clear the FLAG_SECURE flag immediately.
        // This should override ANY plugin or theme setting that enforces
        // the screenshot restriction.
        // =======================================================
        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }

    // Keeping configureFlutterEngine for necessary Flutter setup (like plugins)
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
    }
}

//home_screen.dart
// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:aiot_ui/services/api_service.dart';
import 'package:aiot_ui/screens/inventory_screens.dart'; // Placeholder and general forms
import 'package:aiot_ui/screens/dashboard/main_dashboard_screen.dart'; // Contains MainDashboardScreen
import 'package:aiot_ui/screens/dashboard/productivity_screen.dart'; // Contains ProductivityManagementScreen
import 'package:aiot_ui/screens/dashboard/sales_screens.dart'; // NEW: Sales Dashboard
import 'package:flutter/services.dart';

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
      {'title': 'Sales Visualization', 'route': '/sales-dashboard', 'icon': Icons.ssid_chart, 'index': 1}, // NEW INDEX 1
      {'title': 'Stock Entry', 'route': '/stock-options', 'icon': Icons.scanner_outlined, 'index': 2}, // MOVED TO INDEX 2
      {'title': 'Discounts & Alerts', 'route': '/alerts-discounts', 'icon': Icons.discount, 'index': 3},
      {'title': 'Donation Management', 'route': '/donation', 'icon': Icons.volunteer_activism, 'index': 4},
      {'title': 'Productivity Management', 'route': '/productivity', 'icon': Icons.insights, 'index': 5},
      {'title': 'Store Profile', 'route': '/profile', 'icon': Icons.store, 'index': 6},
      {'title': 'Contact Us', 'route': '/contact', 'icon': Icons.phone, 'index': 7},
      {'title': 'Support Desk', 'route': '/support', 'icon': Icons.support_agent, 'index': 8},
      {'title': 'AI Chatbot Assistant', 'route': '/chatbot', 'icon': Icons.smart_toy, 'index': 9},
    ];

    _screens = [
      MainDashboardScreen(onNavigate: _onNavigate), // 0
      SalesDashboardScreen(apiService: widget.apiService, onNavigate: _onNavigate), // 1 - NEW SALES DASHBOARD
      StockEntryOptionsScreen(apiService: widget.apiService, refreshHome: _forceRefresh, onProductAdded: dummyOnProductAdded), // 2
      AlertsDiscountsScreen(apiService: widget.apiService, refreshHome: _forceRefresh), // 3
      DonationScreen(apiService: widget.apiService, refreshHome: _forceRefresh), // 4
      ProductivityManagementScreen(apiService: widget.apiService), // 5
      const PlaceholderScreen(title: 'Store Profile'), // 6
      const PlaceholderScreen(title: 'Contact Us'), // 7
      const PlaceholderScreen(title: 'Support Desk'), // 8
      const PlaceholderScreen(title: 'AI Chatbot Assistant'), // 9
    ];
  }


  void _onNavigate(String route, String title) {
    if (!_isInitialized) return;

    final index = _menuItems.indexWhere((item) => item['route'] == route);
    if (index != -1) {
      setState(() {
        _currentIndex = index;
        _currentTitle = title;
      });

      if (Scaffold.of(context).hasDrawer && Scaffold.of(context).isDrawerOpen) {
        Navigator.pop(context);
      }
    }
  }

  void _goToDashboard() {
    _onNavigate('/main-dashboard', 'Home Dashboard');
  }

  void _forceRefresh() {
    setState(() {});
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
            child: Opacity(
              opacity: 0.05,
              child: Image.asset(
                'assets/background.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(color: Theme.of(context).scaffoldBackgroundColor),
              ),
            ),
          ),
          _buildScreen(),
        ],
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
          title: Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Theme.of(context).colorScheme.primary : Colors.white)),
          selected: isSelected,
          selectedTileColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
          onTap: () => _onNavigate(route, title),
        ),
      ),
    );
  }
}

//main_dashboard_screen.dart
// lib/screens/dashboard/main_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// --- NEW UNSTOP-INSPIRED DASHBOARD CARD ---

class UnstopInspiredCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const UnstopInspiredCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Card(
        elevation: 10,
        color: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: InkWell(
          onTap: () {
            print('DEBUG: Dashboard Card Tapped: Navigating to $title');
            onTap();
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(icon, size: 30, color: color),
                    const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: color,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- MAIN DASHBOARD SCREEN (Landing Page) ---
class MainDashboardScreen extends StatelessWidget {
  final Function(String, String) onNavigate;

  const MainDashboardScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome, Store-1 Manager',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 32, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: 5),
          const Text(
            'Maximize Shelf Life. Minimize Waste Line.',
            style: TextStyle(color: Colors.grey, fontSize: 18, fontStyle: FontStyle.italic),
          ),
          const Divider(height: 40),

          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 1000 ? 3 : (constraints.maxWidth > 600 ? 2 : 1);
              final cardHeight = crossAxisCount == 1 ? 160.0 : 220.0;

              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: constraints.maxWidth / (crossAxisCount * cardHeight),
                children: [
                  UnstopInspiredCard(
                      title: 'Sales Visualization',
                      subtitle: 'Track revenue, units sold, and top-performing products.',
                      icon: Icons.ssid_chart,
                      color: Colors.blue.shade400,
                      onTap: () => onNavigate('/sales-dashboard', 'Sales Visualization')
                  ),
                  UnstopInspiredCard(
                      title: 'Stock Entry',
                      subtitle: 'Scan, Add, and manage new inventory with automatic data validation.',
                      icon: Icons.scanner_outlined,
                      color: Theme.of(context).colorScheme.primary,
                      onTap: () => onNavigate('/stock-options', 'Stock Entry')
                  ),
                  UnstopInspiredCard(
                      title: 'Discounts & Alerts',
                      subtitle: 'Dynamic pricing suggestions based on AI expiry forecasting.',
                      icon: Icons.discount,
                      color: Colors.orange.shade600,
                      onTap: () => onNavigate('/alerts-discounts', 'Dynamic Discounting & Alerts')
                  ),
                  UnstopInspiredCard(
                      title: 'Donation Management',
                      subtitle: 'Direct items within 4 days of expiry to donation partners.',
                      icon: Icons.volunteer_activism,
                      color: Colors.red.shade400,
                      onTap: () => onNavigate('/donation', 'Donation Management')
                  ),
                  UnstopInspiredCard(
                      title: 'Productivity',
                      subtitle: 'AI sales forecasting, ordering optimization, and waste reports.',
                      icon: Icons.insights,
                      color: Colors.teal,
                      onTap: () => onNavigate('/productivity', 'Productivity Management')
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

//productivity_screen.dart
import 'package:flutter/material.dart';
import 'package:aiot_ui/services/api_service.dart';
import 'package:aiot_ui/models/product.dart';
import 'dart:math' as math;

// Data model for the pie chart
class PieData {
  final String title;
  final double value;
  final Color color;
  PieData({required this.title, required this.value, required this.color});
}

// Widget for Pie Chart Visualization (Simulation)
class SalesPieChart extends StatelessWidget {
  final List<PieData> data;
  final double totalValue;

  const SalesPieChart({required this.data, required this.totalValue, super.key});

  @override
  Widget build(BuildContext context) {
    final nonZeroData = data.where((d) => d.value > 0).toList();
    if (nonZeroData.isEmpty) {
      return const Center(child: Text('No revenue data to display.', style: TextStyle(color: Colors.grey)));
    }

    return Row(
      children: [
        // 1. Pie Chart Area (Takes 50% of the width)
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: CustomPaint(
              size: const Size.square(double.infinity),
              painter: PieChartPainter(nonZeroData, totalValue),
            ),
          ),
        ),

        // 2. Legend (Takes 50% of the width)
        Expanded(
          flex: 5,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: nonZeroData.map((d) => _buildLegendItem(context, d, totalValue)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(BuildContext context, PieData data, double total) {
    final percentage = (data.value / total) * 100;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: data.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${data.title}: ${percentage.toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter to draw the pie chart segments
class PieChartPainter extends CustomPainter {
  final List<PieData> data;
  final double totalValue;

  PieChartPainter(this.data, this.totalValue);

  @override
  void paint(Canvas canvas, Size size) {
    double startAngle = -math.pi / 2; // Start from 12 o'clock

    for (var d in data) {
      final sweepAngle = (d.value / totalValue) * 2 * math.pi;

      final paint = Paint()
        ..color = d.color
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: size.center(Offset.zero), radius: size.width / 2),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      final borderPaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawArc(
        Rect.fromCircle(center: size.center(Offset.zero), radius: size.width / 2),
        startAngle,
        sweepAngle,
        true,
        borderPaint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant PieChartPainter oldDelegate) {
    return oldDelegate.totalValue != totalValue;
  }
}

// Widget for KPI Cards
class ValueCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const ValueCard({required this.title, required this.value, required this.icon, required this.color, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        constraints: const BoxConstraints(minWidth: 140, maxWidth: 300),
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(title, style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// --- PRODUCTIVITY MANAGEMENT SCREEN ---
class ProductivityManagementScreen extends StatelessWidget {
  final ApiService apiService;

  const ProductivityManagementScreen({super.key, required this.apiService});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Product>>(
      future: apiService.fetchProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error loading data: ${snapshot.error}'));
        }

        // --- Data Calculation (Using dummy revenue numbers) ---
        double totalInitialValue = 0.0;
        double discountedValue = 0.0;
        double donatedValue = 0.0;

        for (var p in snapshot.data!) {
          final batchValue = p.initialPrice * p.quantity;

          if (p.status == 'Discount Active') {
            discountedValue += (p.finalPrice * p.quantity);
            totalInitialValue += batchValue;
          } else if (p.daysToExpiry <= 0 || p.status == 'Donated') {
            donatedValue += batchValue;
          } else {
            totalInitialValue += batchValue;
          }
        }

        final fullSalesValue = totalInitialValue * 0.85;
        final totalRevenueTracked = fullSalesValue + discountedValue + donatedValue;

        // --- Pie Chart Data Setup ---
        final pieChartData = [
          PieData(title: 'Full Sales Revenue', value: fullSalesValue, color: Colors.green.shade400),
          PieData(title: 'Discounted Revenue', value: discountedValue, color: Colors.orange.shade400),
          PieData(title: 'Donated/Wasted Value', value: donatedValue, color: Colors.red.shade400),
        ];

        // --- AI Recommendation Logic ---
        String recommendation = 'No major supply chain issues detected. Maintain current ordering levels and monitor seasonal trends.';
        if (donatedValue > totalRevenueTracked * 0.1) {
          recommendation = 'HIGH WASTE ALERT: Inventory loss is significant. Reduce ordering quantity for the top 3 wasted categories (Check Waste Report).';
        } else if (discountedValue > fullSalesValue * 0.3) {
          recommendation = 'DISCOUNT DEPENDENCY: Consider decreasing order quantity by 5% and adjusting initial pricing to test demand elasticity.';
        } else {
          recommendation = 'SUCCESS: Sales and waste metrics are healthy. Maintain current ordering levels.';
        }

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
          children: [
            Text(
              'Predictive Supply Chain & Productivity',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 2.0),
              child: Text(
                'Optimization based on long-term trends and the effectiveness of previous inventory strategies (The Feedback Loop).',
                style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
              ),
            ),
            const Divider(height: 10),

            // --- Sales Visualization / KPI Cards (Kept for Summary) ---
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ValueCard(
                  title: 'Total Revenue',
                  value: '\$${(fullSalesValue + discountedValue).toStringAsFixed(0)}',
                  icon: Icons.attach_money,
                  color: Colors.green.shade400,
                ),
                ValueCard(
                  title: 'Discounted Value',
                  value: '\$${discountedValue.toStringAsFixed(0)}',
                  icon: Icons.local_offer,
                  color: Colors.orange.shade400,
                ),
                ValueCard(
                  title: 'Donated/Wasted Value',
                  value: '\$${donatedValue.toStringAsFixed(0)}',
                  icon: Icons.delete_forever,
                  color: Colors.red.shade400,
                ),
              ],
            ),
            const SizedBox(height: 15),

            // --- Visualization (Pie Chart) ---
            Text('Revenue Distribution Visualization', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 5),
            Container(
              height: 200,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 8)],
              ),
              child: SalesPieChart(data: pieChartData, totalValue: totalRevenueTracked),
            ),
            const SizedBox(height: 15),

            // --- Optimal Ordering Generation (AI Recommendation) ---
            Card(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              elevation: 0,
              margin: const EdgeInsets.only(top: 5),
              child: ListTile(
                leading: Icon(donatedValue > totalRevenueTracked * 0.1 ? Icons.warning : Icons.trending_up,
                    color: donatedValue > totalRevenueTracked * 0.1 ? Colors.red : Theme.of(context).colorScheme.primary,
                    size: 40),
                title: Text('AI RECOMMENDATION', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                subtitle: Text(recommendation, style: const TextStyle(fontStyle: FontStyle.italic)),
              ),
            ),
          ],
        );
      },
    );
  }
}

//inventory_screen.dart
// lib/screens/inventory_screens.dart (Master File)

import 'package:flutter/material.dart';
import 'package:aiot_ui/services/api_service.dart';
import 'package:aiot_ui/models/product.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

// --- Import the refactored screens ---
// NOTE: These are imported here so other screens like HomeScreen can access them 
// via the general 'inventory_screens.dart' import.
import 'dashboard/main_dashboard_screen.dart';
import 'dashboard/productivity_screen.dart';


// --- UTILITY WIDGETS ---

// Placeholder Screen for Extended Menu Items
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction, size: 60, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 20),
            Text(
              'Development In Progress for $title',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            Text(
              'This module will provide specific functions for $title.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

// Reusable button widget for options screen
class OptionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final VoidCallback onPressed;

  const OptionButton({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 450),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 8,
        ),
        child: Row(
          children: [
            Icon(icon, size: 40, color: Colors.black),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                  const SizedBox(height: 4),
                  Text(description, style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.7))),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 20, color: Colors.black),
          ],
        ),
      ),
    );
  }
}

// --- 6. STOCK ENTRY OPTIONS SCREEN (QR/Manual) ---
class StockEntryOptionsScreen extends StatelessWidget {
  final ApiService apiService;
  final VoidCallback refreshHome;
  final VoidCallback onProductAdded;

  const StockEntryOptionsScreen({super.key, required this.apiService, required this.refreshHome, required this.onProductAdded});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stock Entry Options')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Initial Data Capture and Inventory Setup (AIoT)',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 30),

            // QR Code Scan Button (Simulated IoT Layer)
            OptionButton(
              icon: Icons.qr_code_scanner,
              label: 'QR Code/Barcode Scan (IoT)',
              description: 'Instantly integrate stock data via external scanner.',
              color: Theme.of(context).colorScheme.secondary,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Simulating QR/Barcode Scan... Opening manual entry to confirm.')),
                );
                // In a real app, this would pre-fill the form with scanned data
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => InventoryEntryScreen(apiService: apiService, onProductAdded: onProductAdded)),
                );
              },
            ),
            const SizedBox(height: 20),

            // Manual Entry Button
            OptionButton(
              icon: Icons.edit_note,
              label: 'Manual Data Entry',
              description: 'Manually input all necessary product and expiry details.',
              color: Theme.of(context).colorScheme.primary,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => InventoryEntryScreen(apiService: apiService, onProductAdded: onProductAdded)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// --- 7. MANUAL INVENTORY ENTRY SCREEN ---
class InventoryEntryScreen extends StatefulWidget {
  final ApiService apiService;
  final VoidCallback onProductAdded;

  const InventoryEntryScreen({super.key, required this.apiService, required this.onProductAdded});

  @override
  State<InventoryEntryScreen> createState() => _InventoryEntryScreenState();
}

class _InventoryEntryScreenState extends State<InventoryEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  String _productName = '';
  double _initialPrice = 0.0;
  int _quantity = 1;
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 7));
  String _storageLocation = 'Shelf A';
  bool _isLoading = false;

  final List<String> locations = ['Shelf A', 'Fridge B', 'Freezer C', 'Warehouse D'];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _expiryDate) {
      setState(() {
        _expiryDate = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _isLoading = true;
      });

      final newProduct = Product(
        productName: _productName,
        initialPrice: _initialPrice,
        quantity: _quantity,
        expiryDate: _expiryDate,
        storageLocation: _storageLocation,
      );

      try {
        await widget.apiService.addProduct(newProduct);
        widget.onProductAdded(); // Call refresh and navigate to alerts screen
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Product $_productName added successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add product: ${e.toString().split(':')[1].trim()}')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manual Stock Entry')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 10)],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Database Integration: Food Item Details', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.primary)),
                  const Divider(height: 20),

                  // Product Name
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Food Item Name', prefixIcon: Icon(Icons.fastfood)),
                    validator: (value) => value == null || value.isEmpty ? 'Please enter the item name' : null,
                    onSaved: (value) => _productName = value!,
                  ),
                  const SizedBox(height: 16),

                  // Initial Price
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Initial Price (\$) / Unit', prefixIcon: Icon(Icons.attach_money)),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                    validator: (value) {
                      final price = double.tryParse(value ?? '');
                      return price == null || price <= 0 ? 'Enter a valid price' : null;
                    },
                    onSaved: (value) => _initialPrice = double.parse(value!),
                  ),
                  const SizedBox(height: 16),

                  // Quantity
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Quantity (Units)', prefixIcon: Icon(Icons.format_list_numbered)),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      final qty = int.tryParse(value ?? '');
                      return qty == null || qty <= 0 ? 'Enter a valid quantity' : null;
                    },
                    onSaved: (value) => _quantity = int.parse(value!),
                  ),
                  const SizedBox(height: 16),

                  // Storage Location
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Storage Location', prefixIcon: Icon(Icons.location_on)),
                    value: _storageLocation,
                    items: locations.map((String location) {
                      return DropdownMenuItem<String>(
                        value: location,
                        child: Text(location),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _storageLocation = newValue;
                        });
                      }
                    },
                    onSaved: (value) => _storageLocation = value!,
                    dropdownColor: Theme.of(context).cardColor,
                  ),
                  const SizedBox(height: 16),

                  // Expiry Date Picker
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today),
                    title: Text('Expiry Date: ${DateFormat('yyyy-MM-dd').format(_expiryDate)}', style: Theme.of(context).textTheme.bodyMedium),
                    trailing: TextButton(
                      onPressed: () => _selectDate(context),
                      child: Text('Select Date', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Save Stock to Database', style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _submitForm,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- 8. ALERTS & DISCOUNTS SCREEN (First Alert) ---
class AlertsDiscountsScreen extends StatefulWidget {
  final ApiService apiService;
  final VoidCallback refreshHome;

  const AlertsDiscountsScreen({super.key, required this.apiService, required this.refreshHome});

  @override
  State<AlertsDiscountsScreen> createState() => _AlertsDiscountsScreenState();
}

class _AlertsDiscountsScreenState extends State<AlertsDiscountsScreen> {
  late Future<List<Product>> _productsFuture;
  final int firstAlertDays = 10;
  final int secondAlertDays = 4;

  @override
  void initState() {
    super.initState();
    _productsFuture = _fetchProductsAndCheckAlerts();
  }

  Future<List<Product>> _fetchProductsAndCheckAlerts() async {
    List<Product> products = await widget.apiService.fetchProducts();

    List<Product> processedProducts = [];
    for (var product in products) {
      if (product.daysToExpiry > 0 && product.daysToExpiry <= firstAlertDays && product.status == 'For Sale') {
        try {
          final result = await widget.apiService.calculateDiscount(product);
          // FIX: Use the copyProductWith method from the Product model
          processedProducts.add(product.copyProductWith(
            discountPercentage: result['discount_percentage'] ?? 0.0,
            finalPrice: result['final_price'] ?? product.initialPrice,
            status: 'Discount Active',
          ));
        } catch (e) {
          processedProducts.add(product);
          print('Error calculating discount for ${product.productName}: $e');
        }
      } else {
        processedProducts.add(product);
      }
    }
    return processedProducts;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Product>>(
      future: _productsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Connection Error: ${snapshot.error}. Ensure FastAPI is running on ${const String.fromEnvironment('BASE_URL', defaultValue: 'http://127.0.0.1:8000')}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No inventory items found. Add stock via Stock Entry.'));
        }

        final alertProducts = snapshot.data!
            .where((p) => p.daysToExpiry > 0 && p.daysToExpiry <= firstAlertDays && p.status != 'Donated')
            .toList();

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _productsFuture = _fetchProductsAndCheckAlerts();
            });
          },
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Text(
                'First Alert: Dynamic Discounting for Revenue Recovery',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text('Items approaching expiry (10 days or less). AI determines the optimal discount to drive sales.'),
              ),
              const Divider(),
              if (alertProducts.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Text('No items currently triggering the 10-day discount alert.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                  ),
                ),
              ...alertProducts.map((product) {
                final isDonationAlert = product.daysToExpiry <= secondAlertDays;

                return DiscountAlertCard(
                  key: ValueKey(product.id),
                  product: product,
                  isDonationAlert: isDonationAlert,
                  apiService: widget.apiService,
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }
}

// Widget for Dynamic Discounting Display and Recipe
class DiscountAlertCard extends StatefulWidget {
  final Product product;
  final bool isDonationAlert;
  final ApiService apiService;

  const DiscountAlertCard({
    super.key,
    required this.product,
    required this.isDonationAlert,
    required this.apiService,
  });

  @override
  State<DiscountAlertCard> createState() => _DiscountAlertCardState();
}

class _DiscountAlertCardState extends State<DiscountAlertCard> {
  String _recipeSuggestion = 'Fetching AI Recipe...';
  bool _isLoadingRecipe = false;

  @override
  void initState() {
    super.initState();
    _fetchRecipe();
  }

  Future<void> _fetchRecipe() async {
    setState(() {
      _isLoadingRecipe = true;
      _recipeSuggestion = 'Fetching AI Recipe...';
    });
    try {
      final recipe = await widget.apiService.getRecipeSuggestion(widget.product.productName);
      setState(() {
        _recipeSuggestion = recipe;
      });
    } catch (e) {
      setState(() {
        _recipeSuggestion = 'Error fetching recipe: ${e.toString().split(':')[1].trim()}';
      });
    } finally {
      setState(() {
        _isLoadingRecipe = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: widget.isDonationAlert ? Colors.red.shade700 : Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.product.productName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Chip(
                  label: Text(
                    '${widget.product.daysToExpiry} days left',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  backgroundColor: widget.isDonationAlert ? Colors.red : Colors.orange,
                ),
              ],
            ),
            const Divider(height: 10),
            Text('Location: ${widget.product.storageLocation} | Qty: ${widget.product.quantity}'),
            const SizedBox(height: 8),

            // AI Discount and Pricing
            Text('AI Dynamic Pricing', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 10,
              children: [
                Text('Original: \$${widget.product.initialPrice.toStringAsFixed(2)}', style: const TextStyle(decoration: TextDecoration.lineThrough)),
                Text(
                  'AI Price: \$${widget.product.finalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.lightGreen, fontSize: 16),
                ),
                Text('(${widget.product.discountPercentage.toStringAsFixed(0)}% OFF)', style: const TextStyle(color: Colors.red)),
              ],
            ),
            const SizedBox(height: 12),

            // Real-Time Customer Interface simulation
            ExpansionTile(
              title: const Text('Real-Time Customer Interface Preview (LCD/QR)', style: TextStyle(fontWeight: FontWeight.w600)),
              collapsedBackgroundColor: Theme.of(context).cardColor,
              backgroundColor: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LCD Display: ${widget.product.productName} - ${widget.product.discountPercentage.toStringAsFixed(0)}% OFF!',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.secondary),
                      ),
                      const SizedBox(height: 8),
                      // QR Code Recipe Simulation (Encourages immediate purchase)
                      const Text(
                        'QR Code Recipe: "This food is expiring soon—make this recipe for tonight\'s dinner!"',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 4),
                      _isLoadingRecipe
                          ? const LinearProgressIndicator()
                          : Text(
                        _recipeSuggestion,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (widget.isDonationAlert)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Text(
                  'Action Required: Item is within 4 days of expiry and should be moved to the Donation Dashboard.',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red[400]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// --- 9. DONATION SCREEN (Second Alert & Management) ---
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
    // Using DELETE as a proxy for "logging and removing for donation"
    try {
      await widget.apiService.deleteProduct(id);
      widget.refreshHome(); // Refresh the entire home view
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully logged donation and removed: $productName.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to log donation (API Error): ${e.toString().split(':')[1].trim()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Product>>(
      future: _productsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Connection Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) return const Center(child: Text('No Data'));

        final donationCandidates = snapshot.data!
            .where((p) => p.daysToExpiry > 0 && p.daysToExpiry <= donationThresholdDays && p.status != 'Donated')
            .toList();

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _productsFuture = widget.apiService.fetchProducts();
            });
          },
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Text(
                'Second Alert: Donation and Final Sale Strategy',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.red[400]),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text('Items expiring in **4 days or less**. AI suggests a split between final, deep-discount sale and necessary donation.'),
              ),
              const Divider(),

              if (donationCandidates.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 50.0),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.check_circle_outline, size: 80, color: Colors.lightGreen),
                        SizedBox(height: 16),
                        Text('All donation candidates have been cleared or are not yet critical.', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),

              ...donationCandidates.map((product) {
                return DonationCandidateCard(
                  product: product,
                  onDonate: _markAsDonated,
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }
}

// Widget for a single donation item
class DonationCandidateCard extends StatelessWidget {
  final Product product;
  final Function(String, String) onDonate;

  const DonationCandidateCard({required this.product, required this.onDonate, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      color: Theme.of(context).cardColor,
      child: ListTile(
        leading: Icon(Icons.warning, color: Colors.red.shade400, size: 30),
        title: Text('${product.productName} (Qty: ${product.quantity})', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade200)),
        subtitle: Text('Expiring in ${product.daysToExpiry} days | Location: ${product.storageLocation}'),
        trailing: ElevatedButton.icon(
          icon: const Icon(Icons.thumb_up),
          label: const Text('Log Donation'),
          onPressed: product.id == null ? null : () => onDonate(product.id!, product.productName),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.black,
          ),
        ),
      ),
    );
  }
}

//product.dart
import 'dart:math';

// --- CORE DATA MODEL ---
class Product {
  final String? id;
  final String productName;
  final double initialPrice;
  final int quantity;
  final DateTime expiryDate;
  final String storageLocation;
  final double discountPercentage;
  final double finalPrice;
  final String status;

  Product({
    this.id,
    required this.productName,
    required this.initialPrice,
    required this.quantity,
    required this.expiryDate,
    required this.storageLocation,
    this.discountPercentage = 0.0,
    this.finalPrice = 0.0,
    this.status = 'For Sale',
  });

  // Method to create a new Product instance with updated fields
  Product copyProductWith({
    String? id,
    String? productName,
    double? initialPrice,
    int? quantity,
    DateTime? expiryDate,
    String? storageLocation,
    double? discountPercentage,
    double? finalPrice,
    String? status,
  }) {
    return Product(
      id: id ?? this.id,
      productName: productName ?? this.productName,
      initialPrice: initialPrice ?? this.initialPrice,
      quantity: quantity ?? this.quantity,
      expiryDate: expiryDate ?? this.expiryDate,
      storageLocation: storageLocation ?? this.storageLocation,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      finalPrice: finalPrice ?? this.finalPrice,
      status: status ?? this.status,
    );
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      // Safely parse date, handling different date formats
      parsedDate = DateTime.parse(json['expiry_date'].toString().split('T')[0]);
    } catch (_) {
      parsedDate = DateTime.now(); // Fallback date
    }

    final idValue = json['_id'];
    final idString = (idValue is Map) ? idValue['\$oid'] as String : idValue as String?;

    return Product(
      id: idString,
      productName: json['product_name'] ?? 'Unknown',
      initialPrice: (json['initial_price'] as num?)?.toDouble() ?? 0.0,
      quantity: json['quantity'] as int? ?? 0,
      expiryDate: parsedDate,
      storageLocation: json['storage_location'] ?? 'Shelf',
      discountPercentage: (json['discount_percentage'] as num?)?.toDouble() ?? 0.0,
      finalPrice: (json['final_price'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'For Sale',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_name': productName,
      'initial_price': initialPrice,
      'quantity': quantity,
      'expiry_date': expiryDate.toIso8601String().substring(0, 10),
      'storage_location': storageLocation,
      'discount_percentage': discountPercentage,
      'final_price': finalPrice,
      'status': status,
    };
  }

  // Calculates days left until expiration (at least 1 full day remaining)
  int get daysToExpiry => expiryDate.difference(DateTime.now().subtract(const Duration(hours: 24))).inDays;
}

//sales_screen.dart
// lib/screens/dashboard/sales_screens.dart

import 'package:flutter/material.dart';
import 'package:aiot_ui/services/api_service.dart';
import 'package:aiot_ui/models/product.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'dart:ui'; // CRITICAL FIX: Explicitly importing dart:ui for TextDirection

// Data model for the pie chart (Used here because SalesDataPoint depends on it)
class PieData {
  final String title;
  final double value;
  final Color color;
  PieData({required this.title, required this.value, required this.color});
}

// --- SALES MASTER DASHBOARD SCREEN ---

class SalesDashboardScreen extends StatefulWidget {
  final ApiService apiService;
  final Function(String, String) onNavigate;

  const SalesDashboardScreen({super.key, required this.apiService, required this.onNavigate});

  @override
  State<SalesDashboardScreen> createState() => _SalesDashboardScreenState();
}

class _SalesDashboardScreenState extends State<SalesDashboardScreen> {
  late Future<List<Product>> _productsFuture;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _productsFuture = widget.apiService.fetchProducts();
  }

  // Dummy function to determine a product's rank (for display purposes)
  List<Product> _getTopSellers(List<Product> allProducts) {
    allProducts.sort((a, b) => (b.quantity * b.initialPrice).compareTo(a.quantity * a.initialPrice));
    return allProducts.take(6).toList(); // Show top 6
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Product Sales Visualization',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.blue.shade300),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text('Visualize daily sales and revenue for key products over the last month.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
          ),
          const Divider(),

          // --- Search/Slicer Bar (Slightly enhanced UI) ---
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: TextFormField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Product (Slicer)',
                hintText: 'e.g., Apple, Milk, Cheese',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 18),
                  onPressed: () {
                    if (_searchController.text.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductSalesDetailScreen(
                            apiService: widget.apiService,
                            productName: _searchController.text.trim(),
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
              onFieldSubmitted: (value) {
                if (value.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductSalesDetailScreen(
                        apiService: widget.apiService,
                        productName: value,
                      ),
                    ),
                  );
                }
              },
            ),
          ),

          const SizedBox(height: 20),
          Text('Top Selling Products (Click to View Detail)', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),

          // --- Top Sellers Visualization ---
          FutureBuilder<List<Product>>(
            future: _productsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error loading product list: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No products available for sales analysis.'));
              }

              final topSellers = _getTopSellers(snapshot.data!);

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  // Show 3 cards on desktop, 2 on mobile
                  crossAxisCount: MediaQuery.of(context).size.width > 800 ? 3 : 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 3 / 2, // Card width to height ratio
                ),
                itemCount: topSellers.length,
                itemBuilder: (context, index) {
                  final product = topSellers[index];
                  return ProductSummaryCard(
                    product: product,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductSalesDetailScreen(
                            apiService: widget.apiService,
                            productName: product.productName,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

// Summary Card for Top Selling Products
class ProductSummaryCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductSummaryCard({super.key, required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(product.productName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.blue.shade300), overflow: TextOverflow.ellipsis),
              const SizedBox(height: 5),
              Text('Avg. Price: \$${product.initialPrice.toStringAsFixed(2)}', style: Theme.of(context).textTheme.bodySmall),
              Text('In Stock: ${product.quantity}', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}


// --- PRODUCT SALES DETAIL SCREEN (Line Graph Visualization) ---

class ProductSalesDetailScreen extends StatefulWidget {
  final ApiService apiService;
  final String productName;

  const ProductSalesDetailScreen({super.key, required this.apiService, required this.productName});

  @override
  State<ProductSalesDetailScreen> createState() => _ProductSalesDetailScreenState();
}

class _ProductSalesDetailScreenState extends State<ProductSalesDetailScreen> {
  late Future<List<SalesDataPoint>> _salesFuture;

  @override
  void initState() {
    super.initState();
    _salesFuture = widget.apiService.fetchProductSalesDetail(widget.productName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.productName} Sales Analysis')),
      body: FutureBuilder<List<SalesDataPoint>>(
        future: _salesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading sales data: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No sales data available for this product over the last month.'));
          }

          final salesData = snapshot.data!;
          final totalRevenue = salesData.map((d) => d.revenue).reduce((a, b) => a + b);
          final totalQuantity = salesData.map((d) => d.quantity).reduce((a, b) => a + b);
          final days = salesData.length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Sales Summary KPIs ---
                Wrap(
                  spacing: 15,
                  runSpacing: 15,
                  children: [
                    DetailKPI(title: 'Total Revenue (30 Days)', value: '\$${totalRevenue.toStringAsFixed(2)}', color: Colors.green),
                    DetailKPI(title: 'Total Units Sold', value: totalQuantity.toString(), color: Colors.blue),
                    DetailKPI(title: 'Avg. Daily Revenue', value: '\$${(totalRevenue / days).toStringAsFixed(2)}', color: Colors.orange),
                  ],
                ),

                const SizedBox(height: 30),
                Text('Daily Sales Trend (Last 30 Days)', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 10),

                // --- Line Graph Visualization ---
                Container(
                  height: 300,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: LineChartSimulation(salesData: salesData),
                ),

                const SizedBox(height: 30),
                Text('Data Table', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),

                // --- Detailed Data Table ---
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Day')),
                      DataColumn(label: Text('Quantity')),
                      DataColumn(label: Text('Revenue')),
                    ],
                    rows: salesData.map((d) => DataRow(cells: [
                      DataCell(Text(DateFormat('MMM d').format(d.date))),
                      DataCell(Text(d.quantity.toString())),
                      DataCell(Text('\$${d.revenue.toStringAsFixed(2)}')),
                    ])).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Utility widget for detail KPIs
class DetailKPI extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const DetailKPI({super.key, required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

// --- Line Chart Visualization (Simulation) ---
class LineChartSimulation extends StatelessWidget {
  final List<SalesDataPoint> salesData;

  const LineChartSimulation({super.key, required this.salesData});

  @override
  Widget build(BuildContext context) {
    // Determine max values for scaling
    final maxQuantity = salesData.map((d) => d.quantity).reduce(max);
    final maxRevenue = salesData.map((d) => d.revenue).reduce(max);

    // Scale data points for visualization (Normalized to 0-1 range)
    List<Offset> quantityPoints = [];
    List<Offset> revenuePoints = [];

    for (int i = 0; i < salesData.length; i++) {
      final x = i / (salesData.length - 1);

      final quantityNormalized = salesData[i].quantity / maxQuantity;
      quantityPoints.add(Offset(x, 1.0 - quantityNormalized)); // Y-axis inverted for top-down drawing

      final revenueNormalized = salesData[i].revenue / maxRevenue;
      revenuePoints.add(Offset(x, 1.0 - revenueNormalized));
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: CustomPaint(
        painter: LineChartPainter(quantityPoints, revenuePoints),
        child: Container(),
      ),
    );
  }
}

class LineChartPainter extends CustomPainter {
  final List<Offset> quantityPoints;
  final List<Offset> revenuePoints;

  LineChartPainter(this.quantityPoints, this.revenuePoints);

  // Helper to draw a line path
  Path _createLinePath(List<Offset> normalizedPoints, Size size) {
    final path = Path();
    if (normalizedPoints.isEmpty) return path;

    // Convert normalized coordinates (0-1) to screen coordinates
    Offset getScreenCoord(Offset normalized) {
      // Apply a small border padding (10px)
      const padding = 10.0;
      final x = padding + normalized.dx * (size.width - 2 * padding);
      final y = padding + normalized.dy * (size.height - 2 * padding);
      return Offset(x, y);
    }

    path.moveTo(getScreenCoord(normalizedPoints.first).dx, getScreenCoord(normalizedPoints.first).dy);

    for (int i = 1; i < normalizedPoints.length; i++) {
      path.lineTo(getScreenCoord(normalizedPoints[i]).dx, getScreenCoord(normalizedPoints[i]).dy);
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final quantityPaint = Paint()
      ..color = Colors.cyan // Cyan for Quantity
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final revenuePaint = Paint()
      ..color = Colors.lightGreen // Light Green for Revenue
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    // Draw Quantity Line
    canvas.drawPath(_createLinePath(quantityPoints, size), quantityPaint);

    // Draw Revenue Line
    canvas.drawPath(_createLinePath(revenuePoints, size), revenuePaint);

    // Draw Legend
    const styleCyan = TextStyle(color: Colors.cyan, fontSize: 10);
    const styleGreen = TextStyle(color: Colors.lightGreen, fontSize: 10);

    // Units Sold Legend (FIXED)
    final textPainterQuantity = TextPainter(
      text: const TextSpan(text: 'Units Sold (Cyan)', style: styleCyan),
      textDirection: TextDirection.ltr, // CORRECTED
    );
    textPainterQuantity.layout();
    textPainterQuantity.paint(canvas, const Offset(5, 5));

    // Revenue Legend (FIXED)
    final textPainterRevenue = TextPainter(
      text: const TextSpan(text: 'Revenue (Green)', style: styleGreen),
      textDirection: TextDirection.ltr, // CORRECTED
    );
    textPainterRevenue.layout();
    textPainterRevenue.paint(canvas, Offset(5 + textPainterQuantity.width + 15, 5));
  }

  @override
  bool shouldRepaint(covariant LineChartPainter oldDelegate) {
    return oldDelegate.quantityPoints != quantityPoints || oldDelegate.revenuePoints != revenuePoints;
  }
}
