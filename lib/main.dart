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