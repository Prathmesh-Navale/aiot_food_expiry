// api_service.dart

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
  // CHANGED: Removed 'final' to allow default value and removed 'required' from constructor
  final String baseUrl;
  final http.Client client = http.Client();

  // CHANGED: Set default URL to your Live Render Backend
  ApiService({this.baseUrl = "https://aiot-food-expiry.onrender.com"}); 
  // Note: I added "/api" at the end because your backend routes usually look like /api/discounts
  // IF your backend routes are just /products, remove "/api". 
  // Based on your previous Python code, your routes are '/api/discounts', so let's be careful.
  
  // WAIT: Your Python code has routes like:
  // @app.route('/api/discounts')
  // @app.route('/api/forecast')
  // BUT your Flutter code below calls '$baseUrl/products'. 
  // If your Python backend DOES NOT have a '/products' route, this will fail.
  // Assuming you have a '/products' route or will add one, here is the setup:

  Future<List<Product>> fetchProducts() async {
    try {
      // Calls: https://aiot-food-expiry.onrender.com/api/products
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
    try {
      // Calls: https://aiot-food-expiry.onrender.com/api/calculate_discount
      // Note: Make sure your Python backend has this route!
      // In your previous Python code, the route was '/api/discounts'. 
      // You might need to change the string below to match your Python route.
      final response = await client.post(
        Uri.parse('$baseUrl/discounts'), // Changed to match likely Python route
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sku_encoded': product.skuEncoded,
          'current_stock': product.quantity, 
          'days_until_expiry': product.daysToExpiry,
          'sales_last_10d': 0.0, 
          'avg_temp': product.avgTemp,
          'is_holiday': product.isHoliday,
          'full_retail_price': product.initialPrice,
        }),
      );

      if (response.statusCode == 200) {
        // Your Python API returns a list of products. 
        // If this specific endpoint returns a single object, keep this.
        // If it returns a list, you'll need to update this parsing logic.
        final data = jsonDecode(response.body);

        if (data is List) {
           // Handle case where API returns list
           return { 'discount_percentage': 0.0, 'final_price': product.initialPrice };
        }

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

  // --- Chatbot Query Resolver ---
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

    return "I am Foody-AI. I specialize in inventory, sales, and expiry data. Try asking: 'How many units need donation?' or 'Where are my sales details?'";
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