// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/api_service.dart';
import 'screens/home_screen.dart';
import 'screens/inventory_screens.dart'; 

// URL for your Render Backend
const String BASE_URL = 'https://aiot-food-expiry.onrender.com';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const AIoTInventoryApp());
}

class AIoTInventoryApp extends StatelessWidget {
  const AIoTInventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService(baseUrl: BASE_URL);

    // Dummy callbacks
    final VoidCallback dummyRefresh = () => print("Refresh");
    final VoidCallback dummyOnProductAdded = () => print("Added");

    return MaterialApp(
      title: 'AIoT Smart Food Management',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00C853),
          brightness: Brightness.dark,
          primary: const Color(0xFF00C853),
          secondary: const Color(0xFF69F0AE),
          surface: const Color(0xFF1E1E1E),
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00C853),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) {
           return HomeScreen(apiService: apiService, storeName: 'My Store');
        },
        '/stock-options': (context) => StockEntryOptionsScreen(apiService: apiService, refreshHome: dummyRefresh, onProductAdded: dummyOnProductAdded),
        '/manual-entry': (context) => InventoryEntryScreen(apiService: apiService, onProductAdded: dummyOnProductAdded),
        '/alerts-discounts': (context) => AlertsDiscountsScreen(apiService: apiService, refreshHome: dummyRefresh),
        '/donation': (context) => DonationScreen(apiService: apiService, refreshHome: dummyRefresh),
        '/productivity': (context) => const PlaceholderScreen(title: 'Productivity'),
        '/profile': (context) => const PlaceholderScreen(title: 'Store Profile'),
        '/contact': (context) => const PlaceholderScreen(title: 'Contact Us'),
        '/support': (context) => const PlaceholderScreen(title: 'Support Desk'),
        '/chatbot': (context) => const PlaceholderScreen(title: 'AI Chatbot'),
      },
    );
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
          child: const Text("LOGIN (Bypass)"),
        ),
      ),
    );
  }
}