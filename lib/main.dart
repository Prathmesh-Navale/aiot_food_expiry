// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/inventory_screens.dart';
import 'screens/donation_screen.dart';
import 'screens/dashboard/productivity_screen.dart';
import 'services/api_service.dart';

// --- CONFIGURATION ---
// CHANGE THIS URL TO CONNECT TO YOUR ATLAS-CONNECTED BACKEND
// For Android Emulator use: 'http://10.0.2.2:5000'
// For Real Device use: 'http://YOUR_PC_IP:5000'
// For Render Deployment: 'https://your-app-name.onrender.com'
const String BASE_URL = 'https://your-app-name.onrender.com'; 
// ---------------------

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
    final VoidCallback dummyRefresh = () {};
    final VoidCallback dummyOnProductAdded = () {};

    return MaterialApp(
      title: 'AIoT Smart Food Management',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00C853), // Green
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
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00C853),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) {
          final settings = ModalRoute.of(context)?.settings;
          String storeName = 'Default Store';
          if (settings?.arguments != null) {
            if (settings!.arguments is Map) {
              final args = settings.arguments as Map<String, dynamic>;
              storeName = args['storeName'] ?? 'Default Store';
            }
          }
          return HomeScreen(apiService: apiService, storeName: storeName);
        },
        '/stock-options': (context) => StockEntryOptionsScreen(apiService: apiService, refreshHome: dummyRefresh, onProductAdded: dummyOnProductAdded),
        '/manual-entry': (context) => InventoryEntryScreen(apiService: apiService, onProductAdded: dummyOnProductAdded),
        '/alerts-discounts': (context) => AlertsDiscountsScreen(apiService: apiService, refreshHome: dummyRefresh),
        '/donation': (context) => DonationScreen(apiService: apiService, refreshHome: dummyRefresh),
        '/productivity': (context) => ProductivityManagementScreen(apiService: apiService),
        '/chatbot': (context) => const PlaceholderScreen(title: 'AI Chatbot Assistant'),
      },
    );
  }
}