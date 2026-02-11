// lib/models/product.dart
import 'dart:math';

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
  final String productSku;
  final int skuEncoded;
  final double avgTemp;
  final int isHoliday;

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
    this.productSku = '',
    this.skuEncoded = 1,
    this.avgTemp = 20.0,
    this.isHoliday = 0,
  });

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
    String? productSku,
    int? skuEncoded,
    double? avgTemp,
    int? isHoliday,
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
      productSku: productSku ?? this.productSku,
      skuEncoded: skuEncoded ?? this.skuEncoded,
      avgTemp: avgTemp ?? this.avgTemp,
      isHoliday: isHoliday ?? this.isHoliday,
    );
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      // Handle various date formats from Python
      String dateStr = json['expiry_date'].toString();
      if (dateStr.length > 10) dateStr = dateStr.substring(0, 10); 
      parsedDate = DateTime.parse(dateStr);
    } catch (_) {
      parsedDate = DateTime.now();
    }

    final idValue = json['_id'];
    final idString = (idValue is Map) ? idValue['\$oid'] as String : idValue as String?;

    T getValue<T>(dynamic val, T defaultValue) {
      if (val is T) return val;
      if (val is num && T == double) return (val as num).toDouble() as T;
      if (val is num && T == int) return (val as num).toInt() as T;
      return defaultValue;
    }

    return Product(
      id: idString,
      // Handle "product_name" OR "Product_Name"
      productName: json['product_name'] ?? json['Product_Name'] ?? 'Unknown',
      
      // ✅ FIXED: Look for 'marked_price' if 'initial_price' is missing
      initialPrice: getValue<double>(json['initial_price'] ?? json['marked_price'], 0.0),
      
      // ✅ FIXED: Look for 'current_stock' if 'quantity' is missing
      quantity: getValue<int>(json['quantity'] ?? json['current_stock'], 0),
      
      expiryDate: parsedDate,
      storageLocation: json['storage_location'] ?? 'Shelf A',
      
      // Handle Discounts
      discountPercentage: getValue<double>(json['discount_percentage'] ?? json['final_discount_pct'], 0.0),
      finalPrice: getValue<double>(json['final_price'] ?? json['final_selling_price'], 0.0),
      
      status: json['status'] ?? json['action_status'] ?? 'For Sale',

      productSku: json['sku'] ?? '',
      skuEncoded: getValue<int>(json['sku_encoded'], 1),
      avgTemp: getValue<double>(json['avg_temp'], 20.0),
      isHoliday: getValue<int>(json['is_holiday'], 0),
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
      'sku': productSku,
      'sku_encoded': skuEncoded,
      'avg_temp': avgTemp,
      'is_holiday': isHoliday,
    };
  }

  int get daysToExpiry => expiryDate.difference(DateTime.now().subtract(const Duration(hours: 24))).inDays;
}