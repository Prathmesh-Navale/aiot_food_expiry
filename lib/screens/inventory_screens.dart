import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/product.dart';
import 'barcode_scanner_screen.dart'; // Ensure this file exists

// --- UTILITY WIDGETS ---
class OptionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final VoidCallback onPressed;

  const OptionButton({required this.icon, required this.label, required this.description, required this.color, required this.onPressed, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 450),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color, foregroundColor: Colors.black,
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

// --- STOCK ENTRY OPTIONS ---
class StockEntryOptionsScreen extends StatelessWidget {
  final ApiService apiService;
  final VoidCallback refreshHome;
  final VoidCallback onProductAdded;

  const StockEntryOptionsScreen({super.key, required this.apiService, required this.refreshHome, required this.onProductAdded});

  void _startScan(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(
        builder: (context) => BarcodeScannerScreen(
          onScanCompleted: (scannedData) {
            Navigator.push(context, MaterialPageRoute(
                  builder: (context) => InventoryEntryScreen(apiService: apiService, onProductAdded: onProductAdded, initialData: scannedData)
              ));
          },
        ),
      ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stock Entry Options')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(padding: const EdgeInsets.all(16.0), child: Text('Initial Data Capture and Inventory Setup (AIoT)', style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center)),
            const SizedBox(height: 30),
            OptionButton(icon: Icons.qr_code_scanner, label: 'QR Code/Barcode Scan (IoT)', description: 'Instantly integrate stock data via camera scanner.', color: Theme.of(context).colorScheme.secondary, onPressed: () => _startScan(context)),
            const SizedBox(height: 20),
            OptionButton(icon: Icons.edit_note, label: 'Manual Data Entry', description: 'Manually input all necessary product and expiry details.', color: Theme.of(context).colorScheme.primary, onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => InventoryEntryScreen(apiService: apiService, onProductAdded: onProductAdded)))),
          ],
        ),
      ),
    );
  }
}

// --- MANUAL INVENTORY ENTRY ---
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

  @override
  void initState() {
    super.initState();
    final data = widget.initialData ?? {};
    _productNameController = TextEditingController(text: data['productName'] ?? '');
    _productSkuController = TextEditingController(text: data['productSku'] ?? '');
    _initialPriceController = TextEditingController(text: data['initialPrice']?.toString() ?? '');
    _quantityController = TextEditingController(text: data['quantity']?.toString() ?? '1');
    if (data['expiryDays'] != null) {
      _expiryDate = DateTime.now().add(Duration(days: data['expiryDays'] as int));
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
        skuEncoded: 201, avgTemp: 22.0, isHoliday: 0,
      );

      try {
        await widget.apiService.addProduct(newProduct);
        widget.onProductAdded();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('SUCCESS: Product ${newProduct.productName} stored in database.')));
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
            decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16)),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Database Integration', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 20),
                  TextFormField(controller: _productNameController, decoration: const InputDecoration(labelText: 'Food Item Name', prefixIcon: Icon(Icons.fastfood))),
                  const SizedBox(height: 16),
                  TextFormField(controller: _initialPriceController, decoration: const InputDecoration(labelText: 'Price', prefixIcon: Icon(Icons.attach_money)), keyboardType: TextInputType.number),
                  const SizedBox(height: 16),
                  TextFormField(controller: _quantityController, decoration: const InputDecoration(labelText: 'Quantity', prefixIcon: Icon(Icons.numbers)), keyboardType: TextInputType.number),
                  const SizedBox(height: 16),
                  DropdownButtonFormField(
                    value: _storageLocation,
                    items: locations.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                    onChanged: (v) => setState(() => _storageLocation = v.toString()),
                    decoration: const InputDecoration(labelText: 'Location'),
                  ),
                  const SizedBox(height: 20),
                  _isLoading ? const CircularProgressIndicator() : ElevatedButton(onPressed: _submitForm, child: const Text('SAVE TO DATABASE')),
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

  @override
  void initState() {
    super.initState();
    _productsFuture = _fetchProductsAndCheckAlerts();
  }

  Future<List<Product>> _fetchProductsAndCheckAlerts() async {
    List<Product> products = await widget.apiService.fetchProducts();
    List<Product> processedProducts = [];
    
    for (var product in products) {
      if (product.daysToExpiry > 0 && product.daysToExpiry <= 30 && product.status != 'Donated') {
        try {
          final result = await widget.apiService.calculateDiscount(product);
          double discount = result['discount_percentage'] ?? 0.0;
          
          // ✅ LOGIC FIX: If discount > 70%, it goes to Donation, NOT Discount list.
          if (discount > 70.0) {
             continue; // Skip adding to this screen
          }

          processedProducts.add(product.copyProductWith(
            discountPercentage: discount,
            finalPrice: result['final_price'] ?? product.initialPrice,
            status: 'Discount Active',
          ));
        } catch (e) {
          processedProducts.add(product);
        }
      } 
    }
    return processedProducts;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Product>>(
      future: _productsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final alertProducts = snapshot.data ?? [];

        return RefreshIndicator(
          onRefresh: () async { setState(() { _productsFuture = _fetchProductsAndCheckAlerts(); }); },
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Text('Profit & Loss Optimization', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
              const Divider(),
              if (alertProducts.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(40.0), child: Text('No discount alerts found.', style: TextStyle(color: Colors.grey)))),
              ...alertProducts.map((product) {
                return DiscountAlertCard(product: product, apiService: widget.apiService);
              }).toList(),
            ],
          ),
        );
      },
    );
  }
}

class DiscountAlertCard extends StatefulWidget {
  final Product product;
  final ApiService apiService;
  const DiscountAlertCard({super.key, required this.product, required this.apiService});

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
    } catch (e) { if(mounted) setState(() => _recipeSuggestion = 'Error fetching recipe'); }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(widget.product.productName, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))),
                Chip(label: Text('${widget.product.daysToExpiry} days left', style: const TextStyle(color: Colors.black)), backgroundColor: Colors.orange),
              ],
            ),
            const SizedBox(height: 8),
            Text('AI Price: \$${widget.product.finalPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.lightGreen, fontSize: 16)),
            Text('(${widget.product.discountPercentage.toStringAsFixed(0)}% OFF)', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ExpansionTile(
              title: const Text('Real-Time Interface Preview', style: TextStyle(fontWeight: FontWeight.w600)),
              children: [Padding(padding: const EdgeInsets.all(8.0), child: Text(_recipeSuggestion, style: Theme.of(context).textTheme.bodyMedium))],
            ),
          ],
        ),
      ),
    );
  }
}