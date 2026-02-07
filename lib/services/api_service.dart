import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/product.dart';
import 'dart:math';

// Data model for sales simulation
class SalesDataPoint {
  final DateTime date;
  final int quantity;
  final double revenue;

  SalesDataPoint({required this.date, required this.quantity, required this.revenue});
}

class ApiService {
  final String baseUrl;
  final http.Client client = http.Client();

  // ✅ FIXED: Base URL points to your Render backend
  ApiService({this.baseUrl = "https://aiot-food-expiry.onrender.com"});

  // 1. FETCH PRODUCTS (GET)
  Future<List<Product>> fetchProducts() async {
    try {
      // ✅ FIXED: Added '/api' to match your Python route
      final response = await client.get(Uri.parse('$baseUrl/api/products'));

      if (response.statusCode == 200) {
        final List<dynamic> productsJson = jsonDecode(response.body);
        return productsJson.map((json) => Product.fromJson(json)).toList();
      } else {
        print('Server Error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('API Error (fetchProducts): $e');
      return [];
    }
  }

  // 2. ADD PRODUCT (POST)
  Future<void> addProduct(Product product) async {
    try {
      // ✅ FIXED: Added '/api' to match your Python route
      final response = await client.post(
        Uri.parse('$baseUrl/api/products'),
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

  // 3. DELETE PRODUCT (DELETE)
  // ⚠️ NOTE: Your current Python backend does NOT have a DELETE route.
  // I have simulated a success response so the UI doesn't crash.
  Future<void> deleteProduct(String id) async {
    try {
      // Uncomment this line once you add a DELETE route to Python:
      // final response = await client.delete(Uri.parse('$baseUrl/api/products/$id'));

      print("⚠️ Backend Warning: Delete is not implemented on server yet.");
      await Future.delayed(Duration(milliseconds: 500)); // Fake delay
      
      // We return success silently to keep the UI happy
    } catch (e) {
      print('API Error (deleteProduct): $e');
    }
  }

  // 4. CALCULATE DISCOUNT
  // ⚠️ NOTE: Your Python backend calculates discounts AUTOMATICALLY in 'fetchProducts'.
  // It does not have a separate POST endpoint for single-item calculation.
  Future<Map<String, double>> calculateDiscount(Product product) async {
    // We return 0.0 here because the REAL discount will come 
    // when you refresh the list using fetchProducts().
    return {
      'discount_percentage': 0.0,
      'final_price': product.initialPrice,
    };
  }

  // 5. RECIPE SUGGESTION
  // ⚠️ NOTE: Your Python backend does not have an '/ai_recipe' route yet.
  Future<String> getRecipeSuggestion(String productName) async {
    return "Recipe feature coming soon! (Backend update required)";
  }

  // --- Chatbot & Simulation (Client Side Logic) ---
  
  Future<String> resolveChatQuery(String query) async {
    final lowerQuery = query.toLowerCase();

    if (lowerQuery.contains('total stock') || lowerQuery.contains('total inventory')) {
      final products = await fetchProducts();
      final totalQuantity = products.fold(0, (sum, p) => sum + p.quantity);
      return 'Your current total inventory across all products is **$totalQuantity units**.';
    }

    if (lowerQuery.contains('sales details')) {
      return 'For detailed sales trends, please visit the **Sales Visualization** tab.';
    }

    if (lowerQuery.contains('donation') || lowerQuery.contains('donate')) {
      final products = await fetchProducts();
      final donationCandidates = products.where((p) => p.daysToExpiry <= 4).toList();
      
      if (donationCandidates.isEmpty) {
        return 'Great news! You currently have **no items** requiring immediate donation.';
      } else {
        final totalQty = donationCandidates.fold(0, (sum, p) => sum + p.quantity);
        return 'Alert: You have **$totalQty units** of ${donationCandidates.length} product types expiring soon.';
      }
    }

    if (lowerQuery.contains('products list') || lowerQuery.contains('all items')) {
      return 'To see the full product list, visit the **Discounts & Alerts** screen.';
    }

    return "I am Foody-AI. Try asking: 'How many units need donation?' or 'What is my total stock?'";
  }

  Future<List<SalesDataPoint>> fetchProductSalesDetail(String productName) async {
    await Future.delayed(const Duration(milliseconds: 500)); 

    final today = DateTime.now();
    final random = Random(productName.hashCode);
    final List<SalesDataPoint> data = [];

    for (int i = 29; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final quantity = 10 + random.nextInt(40);
      final revenue = quantity * (10 + random.nextDouble() * 5); 

      data.add(SalesDataPoint(date: date, quantity: quantity, revenue: revenue));
    }

    return data;
  }
}