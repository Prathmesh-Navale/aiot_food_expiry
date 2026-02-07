// lib/screens/inventory_screens.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/product.dart';

// --- Imports for Navigation ---
import 'barcode_scanner_screen.dart'; 
// Note: We do NOT import donation_screen.dart here because we don't use it inside this file.

// --- UTILITY WIDGETS ---

class OptionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final VoidCallback onPressed;

  const OptionButton({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 450),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 8,
        ),
        child: Row(
          children: [
            Icon(icon, size: 40, color: Colors.black),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                  const SizedBox(height: 4),
                  Text(description, style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.7))),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 20, color: Colors.black),
          ],
        ),
      ),
    );
  }
}

// --- STOCK ENTRY OPTIONS SCREEN ---
class StockEntryOptionsScreen extends StatelessWidget {
  final ApiService apiService;
  final VoidCallback refreshHome;
  final VoidCallback onProductAdded;

  const StockEntryOptionsScreen({super.key, required this.apiService, required this.refreshHome, required this.onProductAdded});

  void _startScan(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BarcodeScannerScreen(
          onScanCompleted: (scannedData) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => InventoryEntryScreen(
                    apiService: apiService,
                    onProductAdded: onProductAdded,
                    initialData: scannedData,
                  )
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stock Entry Options')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Initial Data Capture and Inventory Setup (AIoT)',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 30),
            OptionButton(
              icon: Icons.qr_code_scanner,
              label: 'QR Code/Barcode Scan (IoT)',
              description: 'Instantly integrate stock data via camera scanner.',
              color: Theme.of(context).colorScheme.secondary,
              onPressed: () => _startScan(context),
            ),
            const SizedBox(height: 20),
            OptionButton(
              icon: Icons.edit_note,
              label: 'Manual Data Entry',
              description: 'Manually input all necessary product and expiry details.',
              color: Theme.of(context).colorScheme.primary,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => InventoryEntryScreen(apiService: apiService, onProductAdded: onProductAdded)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// --- MANUAL INVENTORY ENTRY SCREEN ---
class InventoryEntryScreen extends StatefulWidget {
  final ApiService apiService;
  final VoidCallback onProductAdded;
  final Map<String, dynamic>? initialData;

  const InventoryEntryScreen({super.key, required this.apiService, required this.onProductAdded, this.initialData});

  @override
  State<InventoryEntryScreen> createState() => _InventoryEntryScreenState();
}

class _InventoryEntryScreenState extends State<InventoryEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _productNameController;
  late TextEditingController _productSkuController;
  late TextEditingController _initialPriceController;
  late TextEditingController _quantityController;

  DateTime _expiryDate = DateTime.now().add(const Duration(days: 90));
  String _storageLocation = 'Shelf A';
  bool _isLoading = false;

  final List<String> locations = ['Shelf A', 'Fridge B', 'Freezer C', 'Warehouse D'];

  // Simulated AI Inputs
  static const int simulatedSkuEncoded = 201;
  static const double simulatedAvgTemp = 22.0;
  static const int simulatedIsHoliday = 0;

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;
    if (data == null) {
      _productNameController = TextEditingController(text: '');
      _productSkuController = TextEditingController(text: '');
      _initialPriceController = TextEditingController(text: '');
      _quantityController = TextEditingController(text: '1');
      _expiryDate = DateTime.now().add(const Duration(days: 90));
      _storageLocation = 'Shelf A';
    } else {
      _productNameController = TextEditingController(text: data['productName'] ?? '');
      _productSkuController = TextEditingController(text: data['productSku'] ?? '');
      _initialPriceController = TextEditingController(text: data['initialPrice']?.toStringAsFixed(2) ?? '');
      _quantityController = TextEditingController(text: data['quantity']?.toString() ?? '1');
      if (data['storageLocation'] != null) _storageLocation = data['storageLocation'];
      if (data['expiryDays'] != null) {
        _expiryDate = DateTime.now().add(Duration(days: data['expiryDays'] as int));
      }
    }
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _productSkuController.dispose();
    _initialPriceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _productNameController.clear();
    _productSkuController.clear();
    _initialPriceController.clear();
    _quantityController.text = '1';
    setState(() {
      _storageLocation = 'Shelf A';
      _expiryDate = DateTime.now().add(const Duration(days: 90));
      _formKey.currentState?.reset();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _expiryDate) {
      setState(() {
        _expiryDate = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final newProduct = Product(
        productName: _productNameController.text.trim(),
        initialPrice: double.tryParse(_initialPriceController.text) ?? 0.0,
        quantity: int.tryParse(_quantityController.text) ?? 0,
        expiryDate: _expiryDate,
        storageLocation: _storageLocation,
        productSku: _productSkuController.text.trim(),
        skuEncoded: simulatedSkuEncoded,
        avgTemp: simulatedAvgTemp,
        isHoliday: simulatedIsHoliday,
      );

      try {
        await widget.apiService.addProduct(newProduct);
        widget.onProductAdded();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('SUCCESS: Product ${newProduct.productName} stored in database.')),
          );
          _resetForm();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Database Error: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manual Stock Entry')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 10)],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Database Integration: Food Item Details', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.primary)),
                  const Divider(height: 20),
                  TextFormField(
                    controller: _productNameController,
                    decoration: const InputDecoration(labelText: 'Food Item Name', prefixIcon: Icon(Icons.fastfood)),
                    validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _productSkuController,
                    decoration: const InputDecoration(labelText: 'SKU / Barcode', prefixIcon: Icon(Icons.qr_code)),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _initialPriceController,
                    decoration: const InputDecoration(labelText: 'Price', prefixIcon: Icon(Icons.attach_money)),
                    keyboardType: TextInputType.number,
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(labelText: 'Quantity', prefixIcon: Icon(Icons.format_list_numbered)),
                    keyboardType: TextInputType.number,
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Location', prefixIcon: Icon(Icons.location_on)),
                    value: _storageLocation,
                    items: locations.map((loc) => DropdownMenuItem(value: loc, child: Text(loc))).toList(),
                    onChanged: (val) => setState(() => _storageLocation = val!),
                    dropdownColor: Theme.of(context).cardColor,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today),
                    title: Text('Expiry: ${DateFormat('yyyy-MM-dd').format(_expiryDate)}'),
                    trailing: TextButton(
                      onPressed: () => _selectDate(context),
                      child: const Text('Select Date'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton.icon(
                          icon: const Icon(Icons.save),
                          label: const Text('Save Stock'),
                          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                          onPressed: _submitForm,
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- ALERTS & DISCOUNTS SCREEN ---
class AlertsDiscountsScreen extends StatefulWidget {
  final ApiService apiService;
  final VoidCallback refreshHome;

  const AlertsDiscountsScreen({super.key, required this.apiService, required this.refreshHome});

  @override
  State<AlertsDiscountsScreen> createState() => _AlertsDiscountsScreenState();
}

class _AlertsDiscountsScreenState extends State<AlertsDiscountsScreen> {
  late Future<List<Product>> _productsFuture;
  final int firstAlertDays = 10;
  final int secondAlertDays = 4;

  @override
  void initState() {
    super.initState();
    _productsFuture = _fetchProductsAndCheckAlerts();
  }

  Future<List<Product>> _fetchProductsAndCheckAlerts() async {
    List<Product> products = await widget.apiService.fetchProducts();
    List<Product> processedProducts = [];
    for (var product in products) {
      if (product.daysToExpiry > 0 && product.daysToExpiry <= firstAlertDays && product.status == 'For Sale') {
        try {
          final result = await widget.apiService.calculateDiscount(product);
          processedProducts.add(product.copyProductWith(
            discountPercentage: result['discount_percentage'] ?? 0.0,
            finalPrice: result['final_price'] ?? product.initialPrice,
            status: 'Discount Active',
          ));
        } catch (e) {
          processedProducts.add(product);
        }
      } else {
        processedProducts.add(product);
      }
    }
    return processedProducts;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Product>>(
      future: _productsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('No inventory items found.'));

        final alertProducts = snapshot.data!
            .where((p) => p.daysToExpiry > 0 && p.daysToExpiry <= firstAlertDays && p.status != 'Donated')
            .toList();

        return RefreshIndicator(
          onRefresh: () async => setState(() => _productsFuture = _fetchProductsAndCheckAlerts()),
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Text(
                'First Alert: Dynamic Discounting',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
              ),
              const Divider(),
              if (alertProducts.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No alerts currently.'))),
              ...alertProducts.map((product) {
                final isDonationAlert = product.daysToExpiry <= secondAlertDays;
                return DiscountAlertCard(
                  key: ValueKey(product.id),
                  product: product,
                  isDonationAlert: isDonationAlert,
                  apiService: widget.apiService,
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }
}

// Discount Card Widget
class DiscountAlertCard extends StatefulWidget {
  final Product product;
  final bool isDonationAlert;
  final ApiService apiService;

  const DiscountAlertCard({super.key, required this.product, required this.isDonationAlert, required this.apiService});

  @override
  State<DiscountAlertCard> createState() => _DiscountAlertCardState();
}

class _DiscountAlertCardState extends State<DiscountAlertCard> {
  String _recipeSuggestion = 'Fetching AI Recipe...';

  @override
  void initState() {
    super.initState();
    _fetchRecipe();
  }

  Future<void> _fetchRecipe() async {
    try {
      final recipe = await widget.apiService.getRecipeSuggestion(widget.product.productName);
      if(mounted) setState(() => _recipeSuggestion = recipe);
    } catch (_) {
      if(mounted) setState(() => _recipeSuggestion = 'Recipe unavailable');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: widget.isDonationAlert ? Colors.red : Colors.green, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.product.productName, style: Theme.of(context).textTheme.titleLarge),
            Text('${widget.product.daysToExpiry} days left', style: TextStyle(color: widget.isDonationAlert ? Colors.red : Colors.orange)),
            const Divider(),
            Text('Original: \$${widget.product.initialPrice} -> AI Price: \$${widget.product.finalPrice}'),
            const SizedBox(height: 10),
            Text('Recipe Idea: $_recipeSuggestion', style: const TextStyle(fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }
}