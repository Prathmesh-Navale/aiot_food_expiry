import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/product.dart';
import 'dart:math';

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

  // --- CORE ENDPOINTS ---

  Future<List<Product>> fetchProducts() async {
    try {
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

  // --- AI & DISCOUNT LOGIC ---

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
      }
      return {'discount_percentage': 0.0, 'final_price': product.initialPrice};
    } catch (e) {
      print('API Error (calculateDiscount): $e');
      return {'discount_percentage': 0.0, 'final_price': product.initialPrice};
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
        return jsonDecode(response.body)['recipe'] ?? 'No recipe found.';
      }
      return 'Recipe generation failed.';
    } catch (e) {
      return 'Recipe service unavailable.';
    }
  }

  // --- DASHBOARD DATA FETCHERS (Fixes "localhost" issues) ---

  Future<Map<String, dynamic>> getSalesStats() async {
    try {
      final response = await client.get(Uri.parse('$baseUrl/api/sales-stats'));
      if (response.statusCode == 200) return jsonDecode(response.body);
      return {};
    } catch (e) { return {}; }
  }

  Future<List<dynamic>> getForecast() async {
    try {
      final response = await client.get(Uri.parse('$baseUrl/api/forecast'));
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (e) { return []; }
  }

  Future<List<dynamic>> getDiscountsRaw() async {
    try {
      final response = await client.get(Uri.parse('$baseUrl/api/discounts'));
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (e) { return []; }
  }

  // --- HELPERS ---
  Future<String> resolveChatQuery(String query) async {
    return "I am Foody-AI. Ask me about stock, sales, or expiry.";
  }
}