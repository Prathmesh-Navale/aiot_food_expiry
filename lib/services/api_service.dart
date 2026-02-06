//api_service.dart

import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/product.dart';
import 'dart:math';

// Define the data model required for sales simulation
class SalesDataPoint {
  final DateTime date;
  final int quantity;
  final double revenue;

  SalesDataPoint({required this.date, required this.quantity, required this.revenue});
}

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

  // --- UPDATED: sales_last_10d explicitly set to 0.0 ---
  Future<Map<String, double>> calculateDiscount(Product product) async {
    try {
      // Required 7 features for the backend's XGBoost model
      final response = await client.post(
        Uri.parse('$baseUrl/calculate_discount'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sku_encoded': product.skuEncoded,
          'current_stock': product.quantity, // quantity acts as current_stock
          'days_until_expiry': product.daysToExpiry,
          'sales_last_10d': 0.0, // Explicitly set to 0 for new stock entry calculation
          'avg_temp': product.avgTemp, // Backend uses avg_temp_c
          'is_holiday': product.isHoliday,
          'full_retail_price': product.initialPrice,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Handle "donate" action returned by the model
        if (data['action'] == 'donate') {
          throw Exception('AI Recommended Donation: ${data['message']}');
        }

        return {
          'discount_percentage': (data['discount_percentage'] as num?)?.toDouble() ?? 0.0,
          'final_price': (data['final_price'] as num?)?.toDouble() ?? product.initialPrice,
        };
      } else {
        throw Exception('Failed to calculate discount: ${response.body}');
      }
    } catch (e) {
      print('API Error (calculateDiscount): $e');
      rethrow;
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

  // --- Chatbot Query Resolver (Uses existing APIs) ---
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
      final donationCandidates = products.where((p) => p.daysToExpiry <= 4 && p.status != 'Donated').toList();
      if (donationCandidates.isEmpty) {
        return 'Great news! You currently have **no items** requiring immediate donation or disposal (under 4 days to expiry).';
      } else {
        final totalQty = donationCandidates.fold(0, (sum, p) => sum + p.quantity);
        return 'Alert: You have **$totalQty units** of ${donationCandidates.length} product types expiring soon. Please review the **Donation Management** screen.';
      }
    }

    if (lowerQuery.contains('products list') || lowerQuery.contains('all items')) {
      return 'To see the full product list and edit details, please visit the **Discounts & Alerts** screen to view the product table.';
    }

    // Fallback/Generic AI response
    return "I am Foody-AI. I specialize in inventory, sales, and expiry data. Try asking: 'How many units need donation?' or 'Where are my sales details?'";
  }

  Future<List<SalesDataPoint>> fetchProductSalesDetail(String productName) async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay

    final today = DateTime.now();
    final random = Random(productName.hashCode);
    final List<SalesDataPoint> data = [];

    // Simulate 30 days of data
    for (int i = 29; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      // Random quantity based on product name hash for consistent simulation
      final quantity = 10 + random.nextInt(40);
      final revenue = quantity * (10 + random.nextDouble() * 5); // Base price $10-$15

      data.add(SalesDataPoint(date: date, quantity: quantity, revenue: revenue));
    }

    return data;
  }
}