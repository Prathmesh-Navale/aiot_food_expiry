// lib/services/api_service.dart

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

  // ✅ FIXED: Constructor now correctly receives URL from main.dart
  ApiService({required this.baseUrl});

  // --- CORE PRODUCT ENDPOINTS ---

  Future<List<Product>> fetchProducts() async {
    try {
      final response = await client.get(Uri.parse('$baseUrl/api/products'));

      if (response.statusCode == 200) {
        final List<dynamic> productsJson = jsonDecode(response.body);
        return productsJson.map((json) => Product.fromJson(json)).toList();
      } else {
        print('Server Error ${response.statusCode}: ${response.body}');
        return [];
      }
    } catch (e) {
      print('API Error (fetchProducts): $e');
      return [];
    }
  }

  Future<void> addProduct(Product product) async {
    try {
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

  Future<void> deleteProduct(String id) async {
    try {
      final response = await client.delete(Uri.parse('$baseUrl/api/products/$id'));
      if (response.statusCode != 200) {
        throw Exception('Failed to delete product: ${response.body}');
      }
    } catch (e) {
      print('API Error (deleteProduct): $e');
      rethrow;
    }
  }

  // --- DASHBOARD & ANALYTICS ENDPOINTS ---

  Future<Map<String, dynamic>> getSalesStats() async {
    try {
      // ✅ Uses the dynamic baseUrl instead of localhost
      final response = await client.get(Uri.parse('$baseUrl/api/sales-stats'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {};
    } catch (e) {
      print("API Error (getSalesStats): $e");
      return {};
    }
  }

  Future<List<dynamic>> getForecast() async {
    try {
      // ✅ Uses the dynamic baseUrl instead of localhost
      final response = await client.get(Uri.parse('$baseUrl/api/forecast'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print("API Error (getForecast): $e");
      return [];
    }
  }

  Future<List<dynamic>> getDiscountsRaw() async {
    try {
      // ✅ Uses the dynamic baseUrl instead of localhost
      final response = await client.get(Uri.parse('$baseUrl/api/discounts'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print("API Error (getDiscounts): $e");
      return [];
    }
  }

  // --- AI FEATURES ---

  Future<Map<String, double>> calculateDiscount(Product product) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/api/calculate_discount'),
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
        final data = jsonDecode(response.body);
        return {
          'discount_percentage': (data['discount_percentage'] as num?)?.toDouble() ?? 0.0,
          'final_price': (data['final_price'] as num?)?.toDouble() ?? product.initialPrice,
        };
      } else {
        return {
          'discount_percentage': 0.0,
          'final_price': product.initialPrice,
        };
      }
    } catch (e) {
      print('API Error (calculateDiscount): $e');
      return {
        'discount_percentage': 0.0,
        'final_price': product.initialPrice,
      };
    }
  }

  Future<String> getRecipeSuggestion(String productName) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/api/ai_recipe'),
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

  // --- MOCK / LOCAL HELPERS ---

  Future<String> resolveChatQuery(String query) async {
    final lowerQuery = query.toLowerCase();
    if (lowerQuery.contains('total stock')) {
      final products = await fetchProducts();
      final totalQuantity = products.fold(0, (sum, p) => sum + p.quantity);
      return 'Total inventory: **$totalQuantity units**.';
    }
    return "I am Foody-AI. Ask me about stock, sales, or expiry.";
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