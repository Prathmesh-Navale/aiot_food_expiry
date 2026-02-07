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

  // --- NEW FIELDS ---
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

  // ✅ ADDED BACK: This method is required by your Inventory Screen
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

  // ✅ FACTORY: Maps Python API keys to Flutter variables
  factory Product.fromJson(Map<String, dynamic> json) {
    T getValue<T>(dynamic val, T defaultValue) {
      if (val == null) return defaultValue;
      if (val is T) return val;
      if (val is num && T == double) return val.toDouble() as T;
      if (val is num && T == int) return val.toInt() as T;
      if (val is String && T == double) return (double.tryParse(val) ?? defaultValue) as T;
      if (val is String && T == int) return (int.tryParse(val) ?? defaultValue) as T;
      return defaultValue;
    }

    // 1. Handle Date Parsing
    DateTime parsedDate;
    if (json['expiry_date'] != null) {
      try {
        parsedDate = DateTime.parse(json['expiry_date'].toString().split('T')[0]);
      } catch (_) {
        parsedDate = DateTime.now().add(const Duration(days: 7));
      }
    } else if (json['remaining_life'] != null) {
      int daysLeft = getValue<int>(json['remaining_life'], 0);
      parsedDate = DateTime.now().add(Duration(days: daysLeft));
    } else {
      parsedDate = DateTime.now().add(const Duration(days: 7));
    }

    // 2. Handle ID
    final idValue = json['_id'];
    String? idString;
    if (idValue is Map && idValue.containsKey('\$oid')) {
      idString = idValue['\$oid'];
    } else if (idValue != null) {
      idString = idValue.toString();
    }

    return Product(
      id: idString,
      productName: json['product_name'] ?? json['name'] ?? 'Unknown Product',
      initialPrice: getValue<double>(json['marked_price'] ?? json['initial_price'], 0.0),
      quantity: getValue<int>(json['current_stock'] ?? json['quantity'], 0),
      expiryDate: parsedDate,
      storageLocation: json['storage_location'] ?? 'Shelf A',
      discountPercentage: getValue<double>(json['final_discount_pct'] ?? json['discount_percentage'], 0.0),
      finalPrice: getValue<double>(json['final_selling_price'] ?? json['final_price'], 0.0),
      status: json['action_status'] ?? json['status'] ?? 'For Sale',
      productSku: json['sku'] ?? '',
      skuEncoded: getValue<int>(json['sku_encoded'], 1),
      avgTemp: getValue<double>(json['avg_temp'], 20.0),
      isHoliday: getValue<int>(json['is_holiday'], 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_name': productName,
      'marked_price': initialPrice,
      'current_stock': quantity,
      'expiry_date': expiryDate.toIso8601String(),
      'storage_location': storageLocation,
      'sku': productSku,
      'action_status': status,
      'discount_percentage': discountPercentage,
    };
  }

  int get daysToExpiry {
    final now = DateTime.now();
    final date = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    final today = DateTime(now.year, now.month, now.day);
    return date.difference(today).inDays;
  }
}